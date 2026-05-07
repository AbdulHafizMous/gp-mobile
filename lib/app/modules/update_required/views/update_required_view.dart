import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';


class UpdateRequiredView extends StatelessWidget {
  const UpdateRequiredView({super.key});

  Future<void> _openStore() async {
    final String url = Platform.isIOS ? kAppStoreUrl : kPlayStoreUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GPTheme.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Logo ────────────────────────────────────────────────
              Image.asset(
                LOGO_PIXEL,
                height: 130,
                width: 130,
                cacheHeight: 130,
                cacheWidth: 130,
              ),
              const SizedBox(height: 40),

              // ── Icône update ─────────────────────────────────────────
              // Container(
              //   width: 80,
              //   height: 80,
              //   decoration: BoxDecoration(
              //     color: Colors.white.withValues(alpha: 0.12),
              //     shape: BoxShape.circle,
              //     border: Border.all(
              //       color: Colors.white.withValues(alpha: 0.25),
              //     ),
              //   ),
              //   child: const Icon(
              //     Icons.system_update_rounded,
              //     color: Colors.white,
              //     size: 40,
              //   ),
              // ),
              // const SizedBox(height: 28),

              // ── Titre ────────────────────────────────────────────────
              const Text(
                'Mise à jour disponible !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 14),

              // ── Description ──────────────────────────────────────────
              const Text(
                'Une nouvelle version de l\'application est disponible. '
                'Veuillez mettre à jour pour profiter des dernières '
                'améliorations et corrections.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),

              // ── Bouton store ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: GPTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(
                    Platform.isIOS
                        ? Icons.apple_rounded
                        : Icons.shop_rounded,
                    size: 22,
                  ),
                  label: Text(
                    Platform.isIOS
                        ? 'Mettre à jour sur l\'App Store'
                        : 'Mettre à jour sur le Play Store',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Bouton continuer (optionnel) ─────────────────────────
              TextButton(
                onPressed: () => Get.offAllNamed('/onboarding'),
                child: const Text(
                  'Continuer sans mettre à jour',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}