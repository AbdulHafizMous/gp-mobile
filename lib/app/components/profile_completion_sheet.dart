// Bottom sheet en stepper pour compléter le profil : ne propose QUE les
// étapes correspondant aux champs manquants (téléphone, identité,
// profession, centres d'intérêt). Chaque étape est enregistrée dès qu'elle
// est validée ; « Plus tard » ferme sans rien bloquer.
import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_pickers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/app_field.dart';
import 'package:grand_public_v2/app/components/audience_fields.dart';
import 'package:grand_public_v2/app/components/country_picker.dart';
import 'package:grand_public_v2/app/components/interest_item.dart';
import 'package:grand_public_v2/app/data/models/profile_interest.dart';
import 'package:grand_public_v2/app/data/models/user.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

enum _Step { phone, identity, work, interests }

class ProfileCompletionSheet extends StatefulWidget {
  const ProfileCompletionSheet({super.key});

  @override
  State<ProfileCompletionSheet> createState() => _ProfileCompletionSheetState();
}

class _ProfileCompletionSheetState extends State<ProfileCompletionSheet> {
  final _audience = AudienceFormState();
  final _phone = TextEditingController();
  final _country = ValueNotifier<Country>(CountryPickerUtils.getCountryByIsoCode('BJ'));
  final _identityKey = GlobalKey<FormState>();
  final _workKey = GlobalKey<FormState>();
  final _phoneKey = GlobalKey<FormState>();

  late final List<_Step> _steps;
  int _index = 0;
  bool _saving = false;

  final _interests = <ProfileInterest>[];
  bool _interestsLoading = false;

  @override
  void initState() {
    super.initState();
    final u = activeUser.value;
    _audience.prefill(b: u.birthday, g: u.gender, p: u.profession);
    final m = u.profileMissingFields;
    _steps = [
      if (m.contains('phone')) _Step.phone,
      if (m.contains('birthday') || m.contains('gender')) _Step.identity,
      if (m.contains('profession')) _Step.work,
      if (m.contains('interests')) _Step.interests,
    ];
    if (_steps.contains(_Step.interests)) _loadInterests();
  }

  @override
  void dispose() {
    _audience.dispose();
    _phone.dispose();
    _country.dispose();
    super.dispose();
  }

  String _label(_Step s) => switch (s) {
        _Step.phone => 'Téléphone',
        _Step.identity => 'Identité',
        _Step.work => 'Profession',
        _Step.interests => 'Intérêts',
      };

  Future<void> _loadInterests() async {
    setState(() => _interestsLoading = true);
    try {
      final r = await RequestService().get('/interest-centers');
      final list = r.data['data']['interest_centers'] as List<dynamic>;
      _interests
        ..clear()
        ..addAll(list.map((e) => ProfileInterest(id: e['id'], name: e['name'].toString())));
    } catch (_) {
      // Silencieux : l'étape affichera « aucun centre d'intérêt ».
    } finally {
      if (mounted) setState(() => _interestsLoading = false);
    }
  }

  /// Enregistre l'étape courante puis avance (ou ferme à la fin).
  Future<void> _next() async {
    final step = _steps[_index];
    if (_saving) return;

    Map<String, dynamic>? payload;
    switch (step) {
      case _Step.phone:
        if (!(_phoneKey.currentState?.validate() ?? false)) return;
        final raw = _phone.text.replaceAll(' ', '').trim();
        payload = {'phone': '+${_country.value.phoneCode}$raw', 'country_code': _country.value.isoCode};
      case _Step.identity:
        if (!(_identityKey.currentState?.validate() ?? false)) return;
        payload = {'birthday': _audience.birthday.text, 'gender': _audience.gender.value};
      case _Step.work:
        if (!(_workKey.currentState?.validate() ?? false)) return;
        payload = {'profession': _audience.profession.text.trim()};
      case _Step.interests:
        final ids = _interests.where((e) => e.isSelected).map((e) => e.id).toList();
        if (ids.isEmpty) {
          ToastHelper.showToast("Choisissez au moins un centre d'intérêt",
              backgroundColor: Colors.orange, textColor: Colors.white);
          return;
        }
        setState(() => _saving = true);
        try {
          await RequestService().post('/interest-centers', data: {'interest_center_ids': ids});
          _markDone('interests');
        } on DioException catch (e) {
          _fail(e);
          return;
        }
        _advance();
        return;
    }

    setState(() => _saving = true);
    try {
      final res = await RequestService().post('/users/complete-profile', data: payload);
      final user = res.data?['data']?['user'];
      if (user is Map<String, dynamic>) {
        activeUser.value = User.fromJson(user);
      }
    } on DioException catch (e) {
      _fail(e);
      return;
    }
    _advance();
  }

  void _markDone(String field) {
    final u = activeUser.value;
    activeUser.value = u.copyWith(
      profileMissingFields: u.profileMissingFields.where((f) => f != field).toList(),
    );
  }

  void _fail(DioException e) {
    final errs = e.response?.data is Map ? e.response?.data['errors'] : null;
    final first = errs is Map && errs.isNotEmpty ? (errs.values.first as List).first.toString() : null;
    ToastHelper.showToast(first ?? "Impossible d'enregistrer. Réessayez.",
        backgroundColor: Colors.red, textColor: Colors.white);
    if (mounted) setState(() => _saving = false);
  }

  void _advance() {
    if (!mounted) return;
    if (_index >= _steps.length - 1) {
      Navigator.of(context).pop();
      ToastHelper.showToast('Profil complété, merci ! 🎉',
          backgroundColor: Colors.green, textColor: Colors.white);
      return;
    }
    setState(() {
      _index++;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final muted = isDark ? Colors.white60 : Colors.black54;
    if (_steps.isEmpty) return const SizedBox.shrink();
    final step = _steps[_index];
    final last = _index == _steps.length - 1;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: AppFieldStyle.theme.copyWith(
            errorStyle: const TextStyle(color: AppFieldStyle.error, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(color: muted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Complétez votre profil',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Quelques infos pour des contenus et offres adaptés à vous.',
                  textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 13)),
              const SizedBox(height: 18),
              if (_steps.length > 1)
                AppStepper(
                  labels: _steps.map(_label).toList(),
                  current: _index,
                  color: GPTheme.primaryColor,
                  onColor: Colors.white,
                ),
              if (_steps.length > 1) const SizedBox(height: 18),
              _body(step),
              const SizedBox(height: 22),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GPTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(last ? 'Terminer' : 'Suivant', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: Text('Plus tard', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(_Step step) {
    switch (step) {
      case _Step.phone:
        return Form(
          key: _phoneKey,
          child: ValueListenableBuilder<Country>(
            valueListenable: _country,
            builder: (_, country, __) => AppField(
              controller: _phone,
              hint: 'Numéro de téléphone',
              keyboardType: TextInputType.phone,
              prefix: CountryPickerWidget(selectedCountry: country, onChanged: (c) => _country.value = c),
              formatters: [FilteringTextInputFormatter.digitsOnly, SimplePhoneFormatter()],
              validator: (v) => (v == null || v.length < 6) ? 'Numéro invalide' : null,
            ),
          ),
        );
      case _Step.identity:
        return Form(
          key: _identityKey,
          child: AudienceFields(state: _audience, showWork: false, onPrimary: false),
        );
      case _Step.work:
        return Form(
          key: _workKey,
          child: AudienceFields(state: _audience, showIdentity: false, onPrimary: false),
        );
      case _Step.interests:
        if (_interestsLoading) {
          return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final i in _interests)
              InterestItem(
                title: i.name,
                isSelected: i.isSelected,
                fromProfile: true,
                onTap: () => setState(() => i.isSelected = !i.isSelected),
              ),
          ],
        );
    }
  }
}
