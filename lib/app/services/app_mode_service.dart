// lib/app/services/app_mode_service.dart
//
// Centralise le choix "Grandpublic" / "Blowmusic" / "Youwiiin". Tant que
// isBlowMusicActivated ET isYouwiiinActivated sont à false, ce service se
// comporte comme s'il n'y avait que Grandpublic : rien ne change pour les
// utilisateurs actuels.

import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/models/user.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/constants/index.dart';

enum AppMode { grandPublic, blowMusic, youwiiin }

class AppModeService {
  AppModeService._();

  static const _values = {
    AppMode.grandPublic: 'grandpublic',
    AppMode.blowMusic: 'blowmusic',
    AppMode.youwiiin: 'youwiiin',
  };

  /// Un choix de module est-il nécessaire (plus d'un module actif) ?
  static bool get hasMultipleModules =>
      isBlowMusicActivated || isYouwiiinActivated;

  /// Ancienne valeur persistée (module renommé GameZ → Youwiiin).
  static const _legacyYouwiiin = 'gamez';

  /// Migre la valeur persistée « gamez » vers « youwiiin » (une seule fois,
  /// à la première lecture). Tolère un stockage indisponible.
  static String? _readRaw() {
    final storage = GetStorage();
    final raw = storage.read<String>(kAppModeStorageKey);
    if (raw == _legacyYouwiiin) {
      try {
        storage.write(kAppModeStorageKey, _values[AppMode.youwiiin]);
      } catch (_) {}
      return _values[AppMode.youwiiin];
    }
    return raw;
  }

  static AppMode get current {
    final raw = _readRaw();
    if (raw == _values[AppMode.blowMusic] && isBlowMusicActivated)
      return AppMode.blowMusic;
    if (raw == _values[AppMode.youwiiin] && isYouwiiinActivated) return AppMode.youwiiin;
    return AppMode.grandPublic;
  }

  static bool get isBlowMusic => current == AppMode.blowMusic;
  static bool get isYouwiiin => current == AppMode.youwiiin;

  /// L'utilisateur a-t-il déjà choisi un module au moins une fois ?
  static bool get hasChosenMode => _readRaw() != null;

  static Future<void> setMode(AppMode mode) async {
    await GetStorage().write(kAppModeStorageKey, _values[mode]);
  }

  /// Route du "shell" principal du module courant.
  static String get homeRoute {
    switch (current) {
      case AppMode.blowMusic:
        return '/blowmusic/home';
      case AppMode.youwiiin:
        return '/youwiiin/home';
      case AppMode.grandPublic:
        return '/home';
    }
  }

  /// Où renvoyer l'utilisateur juste après connexion (login/register) ET à
  /// chaque ouverture de l'app si déjà connecté : le choix de destination
  /// doit être reproposé À CHAQUE FOIS quand plus d'un module est actif —
  /// ce n'est PAS un choix figé une fois pour toutes. Reste directement sur
  /// Grandpublic si un seul module est actif (comportement actuel conservé).
  ///
  /// Profil d'audience incomplet (naissance / genre / profession) → écran
  /// bloquant /complete-profile AVANT toute destination (il renvoie ensuite
  /// ici une fois complété).
  static String get postAuthRoute {
    final u = activeUser.value;
    if (u.id != 0 && u.needsAudienceProfile) return '/complete-profile';
    return hasMultipleModules ? '/module-choice' : homeRoute;
  }

  /// Variante asynchrone : recharge l'utilisateur (/auth/me) pour connaître
  /// l'état réel du profil, puis renvoie la bonne route. À utiliser juste
  /// après une connexion / à l'ouverture de l'app (activeUser pas encore chargé).
  static Future<String> resolvePostAuthRoute() async {
    try {
      final res = await RequestService().get('/auth/me');
      final data = res.data?['data']?['user'];
      if (data is Map<String, dynamic>) activeUser.value = User.fromJson(data);
    } catch (_) {}
    return postAuthRoute;
  }
}
