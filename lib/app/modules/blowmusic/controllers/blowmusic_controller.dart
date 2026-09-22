// lib/app/modules/blowmusic/controllers/blowmusic_controller.dart
//
// Base minimale de la coquille Blow Music : même projet/architecture que
// Grand Public (même auth, même API, même GetStorage), mais ses propres
// onglets/menus. Les sections sont volontairement de simples emplacements
// ("Bientôt disponible") à ce stade — à connecter aux vrais écrans musique
// (lecteur, bibliothèque, découverte...) lors du lot de fonctionnalités
// dédié.

import 'package:get/get.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';

class BlowMusicTab {
  final String label;
  final String icon; // nom d'icône logique, à mapper côté vue
  const BlowMusicTab(this.label, this.icon);
}

const List<BlowMusicTab> kBlowMusicTabs = [
  BlowMusicTab('Accueil', 'home'),
  BlowMusicTab('Découvrir', 'explore'),
  BlowMusicTab('Ma musique', 'library'),
  BlowMusicTab('Profil', 'profile'),
];

class BlowMusicController extends GetxController {
  final currentTab = 0.obs;

  void changeTab(int index) => currentTab.value = index;

  /// Permet de revenir au choix Grand Public / Blow Music (ex: bouton
  /// "changer d'application" dans le profil Blow Music).
  Future<void> switchToGrandPublic() async {
    await AppModeService.setMode(AppMode.grandPublic);
    Get.offAllNamed('/home');
  }
}
