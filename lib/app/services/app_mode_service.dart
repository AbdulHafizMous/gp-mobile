// lib/app/services/app_mode_service.dart
//
// Centralise tout ce qui concerne le choix "Grand Public" vs "Blow Music".
// Tant que `isBlowMusicActivated` (constants/index.dart) est à false, ce
// service se comporte toujours comme s'il n'y avait que Grand Public :
// aucun changement visible pour les utilisateurs actuels.

import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/constants/index.dart';

enum AppMode { grandPublic, blowMusic }

class AppModeService {
  AppModeService._();

  static const _grandPublicValue = 'grandpublic';
  static const _blowMusicValue = 'blowmusic';

  /// Mode courant. Si Blow Music est désactivé globalement, on force
  /// toujours Grand Public quel que soit ce qui a été stocké précédemment.
  static AppMode get current {
    if (!isBlowMusicActivated) return AppMode.grandPublic;
    final raw = GetStorage().read<String>(kAppModeStorageKey);
    return raw == _blowMusicValue ? AppMode.blowMusic : AppMode.grandPublic;
  }

  static bool get isBlowMusic => current == AppMode.blowMusic;

  static Future<void> setMode(AppMode mode) async {
    await GetStorage().write(
      kAppModeStorageKey,
      mode == AppMode.blowMusic ? _blowMusicValue : _grandPublicValue,
    );
  }

  /// Route du "shell" principal correspondant au mode courant, utilisée
  /// après le splash / après connexion pour savoir où renvoyer l'utilisateur.
  static String get homeRoute =>
      isBlowMusic ? '/blowmusic/home' : '/home';
}
