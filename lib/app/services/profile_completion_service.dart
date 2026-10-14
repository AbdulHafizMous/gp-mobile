// lib/app/services/profile_completion_service.dart
//
// Complétion PROGRESSIVE du profil (remplace l'ancien écran bloquant) :
//  - une bannière discrète reste affichée partout tant que le profil est
//    incomplet (Grandpublic, Blowmusic, Youwiiin, Chaînes…) ;
//  - à chaque entrée dans un module, un bottom sheet en stepper propose de
//    renseigner uniquement ce qui manque (téléphone, naissance/genre,
//    profession, centres d'intérêt).
// Rien n'est bloquant : « Plus tard » ferme le sheet.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/profile_completion_sheet.dart';
import 'package:grand_public_v2/app/globals/index.dart';

class ProfileCompletionService extends GetxService {
  static ProfileCompletionService get to => Get.find();

  /// Modules pour lesquels le sheet a déjà été proposé pendant CETTE visite.
  final Set<String> _promptedThisVisit = {};
  bool _sheetOpen = false;

  bool get needsCompletion => activeUser.value.needsProfileCompletion;

  /// À appeler à l'entrée d'un module (une fois par visite du module).
  void promptIfNeeded(String module) {
    if (!needsCompletion || _sheetOpen) return;
    if (_promptedThisVisit.contains(module)) return;
    _promptedThisVisit.add(module);
    // Laisse le module s'afficher avant d'ouvrir le sheet.
    Future.delayed(const Duration(milliseconds: 700), openSheet);
  }

  /// Quand l'utilisateur quitte les modules (écran de choix), la prochaine
  /// entrée dans un module re-proposera le sheet.
  void resetVisit() => _promptedThisVisit.clear();

  Future<void> openSheet() async {
    if (!needsCompletion || _sheetOpen) return;
    final ctx = Get.context;
    if (ctx == null) return;
    _sheetOpen = true;
    try {
      await showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ProfileCompletionSheet(),
      );
    } finally {
      _sheetOpen = false;
    }
  }
}
