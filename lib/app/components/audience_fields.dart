// lib/app/components/audience_fields.dart
//
// Champs OBLIGATOIRES de profil d'audience : date de naissance, genre,
// profession. Utilisés à l'inscription ET sur l'écran bloquant
// « Compléter mon profil » (comptes existants / sociaux).

import 'package:flutter/material.dart';

class AudienceFormState {
  final birthday = TextEditingController(); // yyyy-MM-dd
  final profession = TextEditingController();
  final gender = ValueNotifier<String?>(null);

  bool get isValid =>
      birthday.text.isNotEmpty &&
      gender.value != null &&
      profession.text.trim().isNotEmpty;

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

class AudienceFields extends StatelessWidget {
  final AudienceFormState state;
  final bool dark;
  const AudienceFields({super.key, required this.state, this.dark = false});

  static const _genders = [
    ('male', 'Homme', Icons.male_rounded),
    ('female', 'Femme', Icons.female_rounded),
    ('other', 'Autre', Icons.transgender_rounded),
  ];

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
      );

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(state.birthday.text) ?? DateTime(now.year - 25, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: 'Date de naissance',
    );
    if (picked != null) state.birthday.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final txt = dark ? Colors.black : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: state.birthday,
          readOnly: true,
          style: TextStyle(color: txt),
          onTap: () async {
            await _pickDate(context);
            (context as Element).markNeedsBuild();
          },
          validator: (v) => (v == null || v.isEmpty) ? 'Date de naissance obligatoire' : null,
          decoration: _dec('Date de naissance *', Icons.cake_outlined),
        ),
        const SizedBox(height: 16),
        FormField<String>(
          validator: (_) => state.gender.value == null ? 'Genre obligatoire' : null,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<String?>(
                valueListenable: state.gender,
                builder: (_, g, __) => Row(
                  children: [
                    for (final o in _genders) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            state.gender.value = o.$1;
                            field.didChange(o.$1);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: g == o.$1 ? Theme.of(context).primaryColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: g == o.$1 ? Theme.of(context).primaryColor : Colors.grey.shade400,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(o.$3, size: 18, color: g == o.$1 ? Colors.white : Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(o.$2,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: g == o.$1 ? Colors.white : Colors.grey.shade700,
                                    )),
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
                  child: Text(field.errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: state.profession,
          style: TextStyle(color: txt),
          textCapitalization: TextCapitalization.sentences,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Profession obligatoire' : null,
          decoration: _dec('Profession *', Icons.work_outline_rounded),
        ),
      ],
    );
  }
}
