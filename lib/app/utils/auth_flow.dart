// lib/app/utils/auth_flow.dart
//
// Point unique de sortie du parcours d'authentification (inscription, OTP,
// connexion sociale). L'ancien écran « Inscription réussie » (sucess_page) et
// l'écran bloquant de profil sont supprimés du parcours : on hydrate
// l'utilisateur tout de suite (nom + e-mail visibles immédiatement) puis on
// entre directement dans l'app. Le profil incomplet est ensuite géré par la
// bannière / le bottom sheet « Compléter mon profil ».

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/models/user.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';
import 'package:grand_public_v2/app/services/brand_takeover_service.dart';
import 'package:grand_public_v2/app/services/crush_quota_service.dart';

class AuthFlow {
  AuthFlow._();

  /// Hydrate [activeUser] depuis un JSON utilisateur (réponse login /
  /// register / social) et mémorise nom + e-mail pour un affichage immédiat.
  static void hydrate(dynamic userJson) {
    if (userJson is! Map) return;
    final map = Map<String, dynamic>.from(userJson);
    if (map['id'] == null) return;
    try {
      activeUser.value = User.fromJson(map);
    } catch (_) {}
    final s = GetStorage();
    final name = map['name']?.toString();
    final email = map['email']?.toString();
    if (name != null && name.isNotEmpty) s.write('username', name);
    if (email != null && email.isNotEmpty) s.write('email', email);
  }

  /// Entre dans l'app (jamais d'écran intermédiaire).
  static Future<void> finish([dynamic userJson]) async {
    hydrate(userJson);
    GetStorage().write('isLogged', true);
    // Services initialisés avant la connexion : on les rafraîchit.
    try {
      if (Get.isRegistered<BrandTakeoverService>()) BrandTakeoverService.to.refresh();
      if (Get.isRegistered<CrushQuotaService>()) CrushQuotaService.to.refreshQuota();
    } catch (_) {}
    final route = await AppModeService.resolvePostAuthRoute();
    Get.offAllNamed(route);
  }
}
