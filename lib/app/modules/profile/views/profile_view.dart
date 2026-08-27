// lib/app/modules/profile/views/profile_view.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/interest_item.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/subscription.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';
import 'package:grand_public_v2/app/modules/pages/favorites_page.dart';
import 'package:grand_public_v2/app/modules/profile/controllers/profile_controller.dart';
import 'package:grand_public_v2/app/modules/social_premium/controllers/social_premium_controller.dart';
import 'package:grand_public_v2/app/utils/section_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE VIEW — StatefulWidget pour gérer le back interceptor
// ─────────────────────────────────────────────────────────────────────────────
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileController _ctrl;
  static const _route = '/profile';

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ProfileController>();
    _ctrl.loadAvatars();

    // Enregistre l'intercepteur de retour :
    // - Si on est sur une sous-page → revient au main profil (retourne true)
    // - Si on est déjà sur le main → laisse HomeController dépiler (retourne false)
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().registerBackInterceptor(_route, _handleBack);
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().unregisterBackInterceptor(_route);
    }
    super.dispose();
  }

  bool _handleBack() {
    if (_ctrl.subPage.value != ProfileSubPage.main) {
      _ctrl.goBack();
      return true; // géré ici
    }
    return false; // laisser HomeController dépiler
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(_ctrl.subPage.value),
            child: _buildSubPage(_ctrl.subPage.value, context),
          ),
        ),
      ),
    );
  }

  Widget _buildSubPage(ProfileSubPage page, BuildContext context) {
    switch (page) {
      case ProfileSubPage.editInfo:
        return const _EditInfoPage();
      case ProfileSubPage.changePassword:
        return const _ChangePasswordPage();
      case ProfileSubPage.avatarPicker:
        return const _AvatarPickerPage();
      case ProfileSubPage.interests:
        return const _InterestsPage();
      case ProfileSubPage.manageSubscriptions:
        return const _ManageSubscriptionsPage();
      case ProfileSubPage.favorites:
        return const FavoritesPage();
      case ProfileSubPage.main:
        return const _MainProfilePage();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  // Color get primaryText =>
  //     Theme.of(this).textTheme.bodyLarge?.color ??
  //     (isDark ? Colors.white : Colors.black);
  Color get subtleText => Theme.of(this).hintColor;
  Color get dividerColor => Theme.of(this).dividerColor;
  Color get cardColor => Theme.of(this).cardColor;

  BoxDecoration get cardDecoration => BoxDecoration(
    color: isDark ? const Color(0xFF1A1A1A) : cardColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: isDark ? Colors.white12 : Colors.transparent,
      width: 2,
    ),
    boxShadow: isDark
        ? null
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileSubBar extends StatelessWidget {
  final String title;
  final VoidCallback onCancel;
  final VoidCallback? onSave;
  final bool isSaving;

  const _ProfileSubBar({
    required this.title,
    required this.onCancel,
    this.onSave,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onCancel,
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: SectionHelper.color,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onSave != null)
                GestureDetector(
                  onTap: isSaving ? null : onSave,
                  child: isSaving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SectionHelper.color,
                          ),
                        )
                      : Text(
                          'Enregistrer',
                          style: TextStyle(
                            color: SectionHelper.color,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                )
              else
                const SizedBox(width: 80),
            ],
          ),
        ),
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  color: SectionHelper.color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }
}

class _GpField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String? hint;
  final bool readOnly;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final Widget? prefixIcon;

  const _GpField({
    required this.label,
    required this.ctrl,
    this.hint,
    this.readOnly = false,
    this.obscure = false,
    this.onToggleObscure,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: readOnly ? context.subtleText : SectionHelper.color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          readOnly: readOnly,
          validator: readOnly ? null : validator,
          keyboardType: keyboardType,
          maxLines: obscure ? 1 : maxLines,
          maxLength: maxLength,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: readOnly ? context.subtleText : SectionHelper.color,
          ),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: readOnly
                ? (isDark ? Colors.grey.shade800 : Colors.grey.shade100)
                : (isDark ? Colors.grey.shade800 : Colors.white),
            counterStyle: TextStyle(color: context.subtleText, fontSize: 11),
            prefixIcon: prefixIcon,
            suffixIcon: readOnly
                ? Icon(Icons.lock_outline, size: 16, color: context.subtleText)
                : onToggleObscure != null
                ? IconButton(
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: SectionHelper.color,
                      size: 20,
                    ),
                  )
                : maxLines == 1
                ? Icon(
                    Icons.edit_outlined,
                    color: SectionHelper.color,
                    size: 18,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: readOnly ? Colors.grey.shade400 : SectionHelper.color,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: SectionHelper.color),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: SectionHelper.color, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _GpDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<Map<String, String>> options;
  final ValueChanged<String?> onChanged;

  const _GpDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: SectionHelper.color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
          style: TextStyle(
            color: SectionHelper.color,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.grey.shade800 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: SectionHelper.color, width: 1.5),
            ),
          ),
          items: options
              .map(
                (o) => DropdownMenuItem(
                  value: o['value'],
                  child: Text(o['label']!),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  final String avatarUrl;
  final String pickedPath;
  final double radius;

  const _AvatarWidget({
    required this.avatarUrl,
    required this.pickedPath,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    if (pickedPath.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(pickedPath)),
        backgroundColor: Colors.grey.shade200,
      );
    }
    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: Colors.grey.shade200,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      // backgroundImage: const AssetImage('assets/images/profile.png'),
      child: Icon(
        Icons.person_outline_rounded,
        size: radius,
        color: Colors.grey.shade400,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: context.subtleText, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: SectionHelper.color,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: SectionHelper.color,
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 56, color: context.dividerColor);
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. MAIN PROFILE PAGE
// ─────────────────────────────────────────────────────────────────────────────
class _MainProfilePage extends GetView<ProfileController> {
  const _MainProfilePage();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: SectionHelper.color),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Text(
              'MON COMPTE',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: SectionHelper.color,
              ),
            ),
            const SizedBox(height: 20),

            // Profile card
            Container(
              decoration: context.cardDecoration,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              controller.goTo(ProfileSubPage.avatarPicker),
                          child: Stack(
                            children: [
                              _AvatarWidget(
                                avatarUrl: controller.displayAvatar.replaceAll(
                                  "localhost",
                                  API_IP,
                                ),
                                pickedPath: controller.pickedAvatarPath.value,
                                radius: 30,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.displayName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: SectionHelper.color,
                                ),
                              ),
                              Text(
                                activeUser.value.description?.isNotEmpty == true
                                    ? activeUser.value.description!
                                    : 'Ajouter une description',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: context.subtleText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 24, color: context.dividerColor),
                  _ActionTile(
                    title: 'Avatar',
                    icon: Icons.emoji_emotions_outlined,
                    onTap: () => controller.goTo(ProfileSubPage.avatarPicker),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Actions card
            Container(
              decoration: context.cardDecoration,
              child: Column(
                children: [
                  _ActionTile(
                    title: 'Modifier mon compte',
                    icon: Icons.person_outline_rounded,
                    onTap: () => controller.goTo(ProfileSubPage.editInfo),
                  ),
                  const _TileDivider(),
                  _ActionTile(
                    title: "Centres d'intérêt",
                    icon: Icons.favorite_border_rounded,
                    onTap: () {
                      controller.loadInterests();
                      controller.goTo(ProfileSubPage.interests);
                    },
                  ),
                  const _TileDivider(),
                  _ActionTile(
                    title: 'Mes abonnements',
                    icon: Icons.subscriptions_outlined,
                    onTap: () =>
                        controller.goTo(ProfileSubPage.manageSubscriptions),
                  ),
                  const _TileDivider(),
                  _ActionTile(
                    title: 'Mes favoris',
                    icon: Icons.bookmark_border_rounded,
                    onTap: () => controller.goTo(ProfileSubPage.favorites),
                  ),
                  const _TileDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.dark_mode_outlined,
                          color: context.subtleText,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Mode sombre',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: SectionHelper.color,
                            ),
                          ),
                        ),
                        Obx(
                          () => Switch(
                            value: controller.isDark.value,
                            onChanged: (_) => controller.toggleTheme(),
                            activeThumbColor: SectionHelper.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Paramètres',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: SectionHelper.color,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: context.cardDecoration,
              child: _ActionTile(
                title: 'Mot de passe',
                icon: Icons.lock_outline_rounded,
                onTap: () => controller.goTo(ProfileSubPage.changePassword),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: controller.logout,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: SectionHelper.color),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Se déconnecter',
                  style: TextStyle(
                    color: SectionHelper.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Suppression de compte (Guideline 5.1.1(v) Apple) ─────────
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => OutlinedButton(
                  onPressed: controller.isDeletingAccount.value
                      ? null
                      : () => _confirmDeleteAccount(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: SectionHelper.color),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isDeletingAccount.value
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SectionHelper.color,
                          ),
                        )
                      : Text(
                          'Supprimer mon compte',
                          style: TextStyle(
                            color: SectionHelper.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      );
    });
  }

  // ── Dialogue de confirmation de suppression de compte ────────────────────
  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer mon compte ?'),
        content: const Text(
          'Cette action est définitive et irréversible. Toutes vos données '
          '(profil, messages, abonnements, favoris…) seront supprimées.\n\n'
          'Voulez-vous vraiment continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.deleteAccount();
            },
            child: Text(
              'Supprimer définitivement',
              style: TextStyle(
                color: SectionHelper.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. EDIT INFO PAGE
// ─────────────────────────────────────────────────────────────────────────────
class _EditInfoPage extends GetView<ProfileController> {
  const _EditInfoPage();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
        child: Form(
          key: controller.formKeyEdit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileSubBar(
                title: 'ÉDITEZ VOTRE COMPTE',
                onCancel: controller.goBack,
                onSave: controller.updateProfile,
                isSaving: controller.isSaving.value,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _AvatarWidget(
                          avatarUrl: controller.displayAvatar.replaceAll(
                            "localhost",
                            API_IP,
                          ),
                          pickedPath: controller.pickedAvatarPath.value,
                          radius: 38,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              onPressed: controller.pickAvatarFromGallery,
                              style: ElevatedButton.styleFrom(
                                side: BorderSide(color: Colors.white),
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Modifier',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () =>
                                  controller.goTo(ProfileSubPage.avatarPicker),
                              child: Text(
                                'choisissez votre avatar...',
                                style: TextStyle(
                                  color: SectionHelper.color,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _GpField(
                      label: 'Nom & Prénom',
                      ctrl: controller.nameController,
                      hint: 'Votre nom complet',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                    _GpField(
                      label: 'Nom d\'utilisateur',
                      ctrl: controller.usernameController,
                      hint: '@monpseudo',
                    ),
                    const SizedBox(height: 16),
                    _GpField(
                      label: 'Email (non modifiable)',
                      ctrl: controller.emailController,
                      readOnly: true,
                      hint: 'votre@email.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _GpField(
                      label: 'Téléphone (non modifiable)',
                      ctrl: controller.phoneController,
                      readOnly: true,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1920),
                          lastDate: DateTime.now(),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: SectionHelper.color,
                                onPrimary: Colors.white,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          controller.birthdayController.text =
                              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        }
                      },
                      child: AbsorbPointer(
                        child: _GpField(
                          label: 'Date de naissance',
                          ctrl: controller.birthdayController,
                          hint: 'AAAA-MM-JJ',
                          prefixIcon: Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: SectionHelper.color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Managed By Dating, can cause confusion if we allow editing here
                    Obx(
                      () => _GpDropdown(
                        label: 'Genre',
                        value: controller.selectedGender.value,
                        options: ProfileController.genderOptions.cast(),
                        onChanged: (v) => controller.selectedGender.value = v,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Obx(() => _GpDropdown(
                    //       label: 'Je recherche',
                    //       value: controller.selectedLookingFor.value,
                    //       options:
                    //           ProfileController.lookingForOptions.cast(),
                    //       onChanged: (v) =>
                    //           controller.selectedLookingFor.value = v,
                    //     )),
                    // const SizedBox(height: 16),
                    _GpField(
                      label: 'Ville / Quartier',
                      ctrl: controller.cityController,
                      hint: 'Ex: Cotonou, Haie Vive',
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: SectionHelper.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _GpField(
                      label: 'Description',
                      ctrl: controller.descController,
                      hint: 'Parlez de vous...',
                      maxLines: 4,
                      maxLength: 150,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. CHANGE PASSWORD PAGE
// ─────────────────────────────────────────────────────────────────────────────
class _ChangePasswordPage extends GetView<ProfileController> {
  const _ChangePasswordPage();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
        child: Form(
          key: controller.formKeyPassword,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileSubBar(
                title: 'MOT DE PASSE',
                onCancel: controller.goBack,
                onSave: controller.changePassword,
                isSaving: controller.isSaving.value,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Column(
                  children: [
                    _GpField(
                      label: 'Mot de passe actuel',
                      ctrl: controller.oldPasswordController,
                      obscure: controller.isOldObscure.value,
                      onToggleObscure: () => controller.isOldObscure.value =
                          !controller.isOldObscure.value,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 20),
                    _GpField(
                      label: 'Nouveau mot de passe',
                      ctrl: controller.newPasswordController,
                      obscure: controller.isNewObscure.value,
                      onToggleObscure: () => controller.isNewObscure.value =
                          !controller.isNewObscure.value,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Champ requis';
                        if (v.length < 8) return 'Minimum 8 caractères';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _GpField(
                      label: 'Confirmer',
                      ctrl: controller.confirmPasswordController,
                      obscure: controller.isConfirmObscure.value,
                      onToggleObscure: () => controller.isConfirmObscure.value =
                          !controller.isConfirmObscure.value,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Champ requis';
                        if (v != controller.newPasswordController.text)
                          return 'Les mots de passe ne correspondent pas';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. AVATAR PICKER PAGE
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarPickerPage extends GetView<ProfileController> {
  const _AvatarPickerPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileSubBar(title: 'CHOISIR UN AVATAR', onCancel: controller.goBack),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: OutlinedButton.icon(
            onPressed: controller.pickAvatarFromGallery,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: SectionHelper.color),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: Icon(
              Icons.photo_library_outlined,
              color: SectionHelper.color,
            ),
            label: Text(
              'Choisir depuis la galerie',
              style: TextStyle(
                color: SectionHelper.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            'ou sélectionnez un avatar',
            style: TextStyle(color: context.subtleText, fontSize: 13),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: controller.avatars.length,
            itemBuilder: (_, i) {
              final isSelected =
                  controller.selectedAvatarIndex.value ==
                  controller.avatars[i].id;
              final isSavingThis = controller.isSaving.value;
              return GestureDetector(
                onTap: isSavingThis
                    ? null
                    : () =>
                          controller.selectPresetAvatar(controller.avatars[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? SectionHelper.color
                          : Colors.grey.shade300,
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: SectionHelper.color.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipOval(
                    child: isSavingThis
                        ? Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: SectionHelper.color,
                              ),
                            ),
                          )
                        : Image.network(
                            controller.avatars[i].url.replaceAll(
                              "localhost",
                              API_IP,
                            ),
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, p) {
                              if (p == null) return child;
                              return Container(
                                color: Colors.grey.shade100,
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: SectionHelper.color,
                                      value: p.expectedTotalBytes != null
                                          ? p.cumulativeBytesLoaded /
                                                p.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.person,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. INTERESTS PAGE
// ─────────────────────────────────────────────────────────────────────────────
class _InterestsPage extends GetView<ProfileController> {
  const _InterestsPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileSubBar(
          title: "CENTRES D'INTÉRÊT",
          onCancel: controller.goBack,
          onSave: controller.saveInterests,
          isSaving: controller.isSaving.value,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Sélectionnez ce que vous aimez',
            style: TextStyle(color: context.subtleText, fontSize: 14),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isInterestsLoading.value) {
              return Center(
                child: CircularProgressIndicator(color: SectionHelper.color),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 15,
                children: controller.interests.map((interest) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InterestItem(
                        title: interest.name,
                        isSelected: interest.isSelected,
                        onTap: () => controller.toggleInterest(interest),
                        fromProfile: true,
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. MES ABONNEMENTS PAGE
// ─────────────────────────────────────────────────────────────────────────────
class _ManageSubscriptionsPage extends StatefulWidget {
  const _ManageSubscriptionsPage();

  @override
  State<_ManageSubscriptionsPage> createState() =>
      _ManageSubscriptionsPageState();
}

class _ManageSubscriptionsPageState extends State<_ManageSubscriptionsPage> {
  final _premCtrl = Get.put(SocialPremiumController());

  @override
  void initState() {
    super.initState();
    _premCtrl.fetchMySubscriptions();
  }

  int _totalDays(List<ActiveSubscription> h) => h.fold(0, (s, e) {
    final d = (e.cancelledAt ?? e.endsAt).difference(e.startsAt).inDays;
    return s + (d > 0 ? d : 0);
  });

  String _mostUsedPlan(List<ActiveSubscription> h) {
    if (h.isEmpty) return '—';
    final freq = <String, int>{};
    for (final s in h) {
      final n = s.plan?.name ?? 'Inconnu';
      freq[n] = (freq[n] ?? 0) + 1;
    }
    return freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  int _cancelledCount(List<ActiveSubscription> h) =>
      h.where((s) => s.cancelledAt != null).length;

  double _totalSpent(List<ActiveSubscription> h) =>
      h.fold(0.0, (s, e) => s + (e.plan?.price ?? 0));

  double _avgDuration(List<ActiveSubscription> h) =>
      h.isEmpty ? 0 : _totalDays(h) / h.length;

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();
    return Column(
      children: [
        _ProfileSubBar(title: 'MES ABONNEMENTS', onCancel: profileCtrl.goBack),
        Expanded(
          child: Obx(() {
            if (_premCtrl.isLoadingHistory.value) {
              return Center(
                child: CircularProgressIndicator(color: SectionHelper.color),
              );
            }
            final history = _premCtrl.subscriptionHistory;
            if (history.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.subscriptions_outlined,
                      size: 56,
                      color: context.subtleText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun abonnement trouvé',
                      style: TextStyle(
                        color: context.subtleText,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => profileCtrl.goTo(ProfileSubPage.main),
                      child: Text(
                        'Voir les plans disponibles',
                        style: TextStyle(
                          color: SectionHelper.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    final sub = activeUser.value.activeSubscription;
                    if (sub == null || !sub.isValid) {
                      return _NoActiveSubBanner(context: context);
                    }
                    return _ActiveSubCard(subscription: sub, context: context);
                  }),
                  const SizedBox(height: 20),
                  _SectionLabel(label: 'Statistiques', context: context),
                  const SizedBox(height: 10),
                  _buildStatsGrid(context, history),
                  const SizedBox(height: 24),
                  _SectionLabel(
                    label: 'Historique (${history.length})',
                    context: context,
                  ),
                  const SizedBox(height: 10),
                  ...history.asMap().entries.map(
                    (e) => _SubscriptionHistoryTile(
                      subscription: e.value,
                      isFirst: e.key == 0,
                      isLast: e.key == history.length - 1,
                      context: context,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    List<ActiveSubscription> history,
  ) {
    final stats = [
      _StatItem(
        icon: Icons.calendar_today_rounded,
        label: 'Total jours',
        value: '${_totalDays(history)} j',
        color: SectionHelper.color,
      ),
      _StatItem(
        icon: Icons.star_rounded,
        label: 'Plan favori',
        value: _mostUsedPlan(history),
        color: Colors.amber.shade600,
      ),
      _StatItem(
        icon: Icons.cancel_outlined,
        label: 'Annulés',
        value: '${_cancelledCount(history)}',
        color: Colors.red.shade400,
      ),
      _StatItem(
        icon: Icons.payments_outlined,
        label: 'Total dépensé',
        value: '${_totalSpent(history).toStringAsFixed(0)} XOF',
        color: Colors.green.shade600,
      ),
      _StatItem(
        icon: Icons.timelapse_rounded,
        label: 'Durée moy.',
        value: '${_avgDuration(history).toStringAsFixed(0)} j',
        color: Colors.blue.shade400,
      ),
      _StatItem(
        icon: Icons.repeat_rounded,
        label: 'Renouvellements',
        value: '${history.length}',
        color: Colors.purple.shade400,
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.4,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _StatCard(stat: stats[i], context: context),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS ABONNEMENTS
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final BuildContext context;
  const _SectionLabel({required this.label, required this.context});
  @override
  Widget build(BuildContext ctx) => Text(
    label,
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: SectionHelper.color,
      letterSpacing: 0.4,
    ),
  );
}

class _ActiveSubCard extends StatelessWidget {
  final ActiveSubscription subscription;
  final BuildContext context;
  const _ActiveSubCard({required this.subscription, required this.context});
  @override
  Widget build(BuildContext ctx) {
    final daysLeft = subscription.endsAt.difference(DateTime.now()).inDays;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [SectionHelper.color, SectionHelper.color.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: SectionHelper.color.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'ABONNEMENT ACTIF',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subscription.plan?.name ?? 'Premium',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${subscription.plan?.price.toStringAsFixed(0) ?? '—'} XOF',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: Colors.white70,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Expire le ${subscription.formattedExpiry}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _SubscriptionProgressBar(subscription: subscription),
          const SizedBox(height: 4),
          Text(
            '$daysLeft jour${daysLeft > 1 ? 's' : ''} restant${daysLeft > 1 ? 's' : ''}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionProgressBar extends StatelessWidget {
  final ActiveSubscription subscription;
  const _SubscriptionProgressBar({required this.subscription});
  @override
  Widget build(BuildContext context) {
    final total = subscription.endsAt.difference(subscription.startsAt).inDays;
    final elapsed = DateTime.now().difference(subscription.startsAt).inDays;
    final progress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.white.withOpacity(0.25),
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        minHeight: 5,
      ),
    );
  }
}

class _NoActiveSubBanner extends StatelessWidget {
  final BuildContext context;
  const _NoActiveSubBanner({required this.context});
  @override
  Widget build(BuildContext ctx) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: context.subtleText, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aucun abonnement actif en ce moment.',
              style: TextStyle(color: context.subtleText, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionHistoryTile extends StatelessWidget {
  final ActiveSubscription subscription;
  final bool isFirst;
  final bool isLast;
  final BuildContext context;
  const _SubscriptionHistoryTile({
    required this.subscription,
    required this.isFirst,
    required this.isLast,
    required this.context,
  });

  String _fd(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  bool get _isCancelled => subscription.cancelledAt != null;
  bool get _isActive => subscription.isActive && subscription.isValid;
  Color _sc() {
    if (_isActive) return Colors.green.shade600;
    if (_isCancelled) return Colors.orange.shade700;
    return Colors.grey.shade500;
  }

  String _sl() {
    if (_isActive) return 'Actif';
    if (_isCancelled) return 'Annulé';
    return 'Expiré';
  }

  IconData _si() {
    if (_isActive) return Icons.check_circle_rounded;
    if (_isCancelled) return Icons.cancel_rounded;
    return Icons.history_rounded;
  }

  @override
  Widget build(BuildContext ctx) {
    final isDark = context.isDark;
    final dd = (subscription.cancelledAt ?? subscription.endsAt)
        .difference(subscription.startsAt)
        .inDays;
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isActive
              ? SectionHelper.color.withOpacity(isDark ? 0.6 : 0.25)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
          width: _isActive ? 1.5 : 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _sc().withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_si(), color: _sc(), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subscription.plan?.name ?? 'Plan inconnu',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: SectionHelper.color,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _sc().withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _sl(),
                        style: TextStyle(
                          color: _sc(),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${subscription.plan?.price.toStringAsFixed(0) ?? '—'} XOF',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: SectionHelper.color,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 13,
                      color: context.subtleText,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _fd(subscription.startsAt),
                      style: TextStyle(color: context.subtleText, fontSize: 12),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: context.subtleText,
                      ),
                    ),
                    Icon(
                      _isCancelled
                          ? Icons.cancel_outlined
                          : Icons.stop_circle_outlined,
                      size: 13,
                      color: _isCancelled
                          ? Colors.orange.shade700
                          : context.subtleText,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _fd(subscription.cancelledAt ?? subscription.endsAt),
                      style: TextStyle(
                        color: _isCancelled
                            ? Colors.orange.shade700
                            : context.subtleText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.timelapse_rounded,
                      size: 12,
                      color: context.subtleText,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$dd jour${dd > 1 ? 's' : ''}',
                      style: TextStyle(color: context.subtleText, fontSize: 11),
                    ),
                    if (subscription.paymentRef.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.receipt_outlined,
                        size: 12,
                        color: context.subtleText,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          subscription.paymentRef,
                          style: TextStyle(
                            color: context.subtleText,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (_isCancelled) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 12,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Annulé le ${_fd(subscription.cancelledAt!)}',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem stat;
  final BuildContext context;
  const _StatCard({required this.stat, required this.context});
  @override
  Widget build(BuildContext ctx) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? stat.color.withOpacity(0.08)
            : stat.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stat.color.withOpacity(isDark ? 0.35 : 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(stat.icon, color: stat.color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: SectionHelper.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  stat.label,
                  style: TextStyle(fontSize: 10, color: context.subtleText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
