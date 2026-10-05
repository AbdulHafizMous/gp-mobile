import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/audience_fields.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import '../controllers/complete_profile_controller.dart';

/// Écran BLOQUANT : impossible d'aller plus loin tant que date de naissance,
/// genre et profession ne sont pas renseignés (pas de bouton retour).
class CompleteProfileView extends GetView<CompleteProfileController> {
  const CompleteProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.badge_outlined, size: 56, color: GPTheme.primaryColor),
                      const SizedBox(height: 14),
                      const Text('Complétez votre profil',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text('Ces informations sont obligatoires pour continuer.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
                      const SizedBox(height: 26),
                      AudienceFields(state: controller.audience),
                      const SizedBox(height: 26),
                      Obx(() => SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: controller.isLoading.value ? null : controller.submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GPTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: controller.isLoading.value
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Continuer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
