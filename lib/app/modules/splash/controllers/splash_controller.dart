import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/models/user.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/main_page/controllers/main_page_controller.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

class SplashController extends GetxController {
  final count = 200.obs;
  late final MainPageController controller;

  @override
  Future<void> onReady() async {
    super.onReady();

    // ── 1. Vérifie la version avant tout ──────────────────────────────────
    final needsUpdate = await _checkVersion();
    if (needsUpdate) {
      Get.offAllNamed('/update-required');
      return;
    }

    // ── 2. Vérifie l'authentification ─────────────────────────────────────
    final isLogged = GetStorage().read('isLogged');
    final token = GetStorage().read('token');

    debugPrint('Token: $token ---- Logged: $isLogged');

    if (isLogged == true && token != null) {
      controller = Get.put(MainPageController());
      final User user = await controller.getUser();
      debugPrint('User + $user ---- Splash User: ${user.toString()}');
      if (user.id == 0) {
        Get.offAllNamed('/onboarding');
      } else {
        Get.offAllNamed('/main-page');
      }
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        Get.offAllNamed('/onboarding');
      });
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VÉRIFICATION DE VERSION
  // Retourne true si une mise à jour est requise
  // ══════════════════════════════════════════════════════════════════════════
  Future<bool> _checkVersion() async {
    try {
      // ── Mock ───────────────────────────────────────────────────────────
      if (!useMock) {
        await Future.delayed(const Duration(milliseconds: 500));
        // 🔧 Change '1.0.0' par une version différente pour tester l'écran update
        const String mockBackendVersion = '1.0.0';
        debugPrint(
          'Version check (mock): local=$kAppVersion backend=$mockBackendVersion',
        );
        return _isUpdateRequired(kAppVersion, mockBackendVersion);
      }

      // ── Réel ───────────────────────────────────────────────────────────
      final response = await RequestService().get('/version');
      debugPrint('Version check [${response.statusCode}]: ${response.data}');

      if (response.statusCode == 200) {
        // Backend retourne { version: "1.2.0" } ou { data: { version: "1.2.0" } }
        final data = response.data;
        String? backendVersion;

        if (data is Map) {
          backendVersion = (data['version'] ?? data['data']?['version'])
              ?.toString();
        }

        if (backendVersion == null) {
          debugPrint('Version backend introuvable — skip update check');
          return false;
        }

        debugPrint('Version check: local=$kAppVersion backend=$backendVersion');
        return _isUpdateRequired(kAppVersion, backendVersion);
      }

      return false;
    } on DioException catch (e) {
      // En cas d'erreur réseau → on laisse passer, pas bloquant
      debugPrint('Version check Dio error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Version check error: $e');
      return false;
    }
  }

  // Compare deux versions semver "X.Y.Z"
  // Retourne true si backendVersion > localVersion
  bool _isUpdateRequired(String local, String backend) {
    try {
      final localParts = local.split('.').map(int.parse).toList();
      final backendParts = backend.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final l = i < localParts.length ? localParts[i] : 0;
        final b = i < backendParts.length ? backendParts[i] : 0;
        if (b > l) return true;
        if (b < l) return false;
      }
      return false; // versions identiques
    } catch (e) {
      debugPrint('Version parse error: $e');
      return false;
    }
  }

  void increment() => count.value++;
}
