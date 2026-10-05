// lib/app/components/audience_fields.dart
//
// Champs OBLIGATOIRES de profil d'audience : date de naissance, genre,
// profession (liste déroulante chargée depuis le backend). Utilisés à
// l'inscription (étape 2) ET sur l'écran bloquant « Compléter mon profil ».
// Le design des champs vient exclusivement de app_field.dart.

import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/components/app_field.dart';
import 'package:grand_public_v2/app/services/profession_service.dart';

class AudienceFormState {
  final birthday = TextEditingController(); // yyyy-MM-dd
  final profession = TextEditingController(); // nom exact d'une profession du backend
  final gender = ValueNotifier<String?>(null);

  bool get isValid =>
      birthday.text.isNotEmpty &&
      gender.value != null &&
      profession.text.trim().isNotEmpty;

  /// Validations par groupe (utilisées par les steppers).
  bool get isIdentityValid => birthday.text.isNotEmpty && gender.value != null;
  bool get isWorkValid => profession.text.trim().isNotEmpty;

  Map<String, dynamic> toPayload() => {
        'birthday': birthday.text,
        'gender': gender.value,
        'profession': profession.text.trim(),
      };

  void prefill({String? b, String? g, String? p}) {
    if (b != null && b.length >= 10) birthday.text = b.substring(0, 10);
    if (g != null && ['male', 'female', 'other'].contains(g)) gender.value = g;
    if (p != null) profession.text = p;
  }

  void dispose() {
    birthday.dispose();
    profession.dispose();
    gender.dispose();
  }
}

class AudienceFields extends StatefulWidget {
  final AudienceFormState state;
  final bool showIdentity; // date de naissance + genre
  final bool showWork; // profession
  final bool onPrimary; // fond coloré (inscription) : couleur d'erreur adaptée
  const AudienceFields({
    super.key,
    required this.state,
    this.showIdentity = true,
    this.showWork = true,
    this.onPrimary = true,
  });

  @override
  State<AudienceFields> createState() => _AudienceFieldsState();
}

class _AudienceFieldsState extends State<AudienceFields> {
  static const _genders = [
    ('male', 'Homme', Icons.male_rounded),
    ('female', 'Femme', Icons.female_rounded),
    ('other', 'Autre', Icons.transgender_rounded),
  ];

  List<String> _professions = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.showWork) _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() => _loading = true);
    try {
      final l = await ProfessionService.load(force: force);
      if (mounted) {
        setState(() {
          _professions = l;
          // Ancienne valeur libre absente de la liste : on la redemande.
          if (widget.state.profession.text.isNotEmpty && !l.contains(widget.state.profession.text)) {
            widget.state.profession.clear();
          }
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger les professions. Touchez le champ pour réessayer.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showIdentity) ...[
          AppDateField(
            controller: s.birthday,
            hint: 'Date de naissance *',
            lastDate: DateTime(DateTime.now().year - 13, DateTime.now().month, DateTime.now().day),
            validator: (v) => (v == null || v.isEmpty) ? 'Date de naissance obligatoire' : null,
          ),
          const SizedBox(height: 16),
          FormField<String>(
            validator: (_) => s.gender.value == null ? 'Genre obligatoire' : null,
            builder: (field) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<String?>(
                  valueListenable: s.gender,
                  builder: (_, g, __) => Row(
                    children: [
                      for (final o in _genders) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              s.gender.value = o.$1;
                              field.didChange(o.$1);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: g == o.$1 ? AppFieldStyle.focus : AppFieldStyle.fill,
                                borderRadius: BorderRadius.circular(AppFieldStyle.radius),
                                border: Border.all(color: g == o.$1 ? AppFieldStyle.focus : AppFieldStyle.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(o.$3, size: 18, color: g == o.$1 ? Colors.white : AppFieldStyle.icon),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(o.$2,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: g == o.$1 ? Colors.white : AppFieldStyle.text,
                                        )),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (o.$1 != 'other') const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 6),
                    child: Text(field.errorText!,
                        style: TextStyle(color: widget.onPrimary ? AppFieldStyle.errorOnPrimary : AppFieldStyle.error, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          if (widget.showWork) const SizedBox(height: 16),
        ],
        if (widget.showWork)
          AppDropdown<String>(
            value: s.profession.text.isEmpty ? null : s.profession.text,
            items: _professions,
            labelOf: (e) => e,
            hint: 'Profession *',
            icon: Icons.work_outline_rounded,
            loading: _loading,
            onRetry: () => _load(force: true),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Profession obligatoire' : null,
            onChanged: (v) => setState(() => s.profession.text = v),
          ),
      ],
    );
  }
}
