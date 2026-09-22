// lib/app/services/brand_takeover_service.dart
//
// Récupère (et met en cache) la config de "prise de contrôle de marque"
// (FullAppAd) éventuellement active côté backend (GET /ads/takeover), et
// l'expose de façon réactive pour que tout composant de l'app puisse
// s'y adapter sans effort : AppBarWi (logo + couleur d'AppBar), le fond
// d'écran global (voir main.dart), et potentiellement d'autres composants
// à l'avenir.
//
// Volontairement peu invasif : si aucun takeover n'est actif, `current`
// reste `null` et RIEN ne change visuellement (comportement actuel intact).

import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/brand_takeover_model.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

class BrandTakeoverService extends GetxService {
  static BrandTakeoverService get to => Get.find();

  final Rxn<BrandTakeover> current = Rxn<BrandTakeover>();

  bool get isActive => current.value != null;

  Future<BrandTakeoverService> init() async {
    // Premier fetch au démarrage, silencieux en cas d'échec (pas bloquant :
    // l'app doit toujours fonctionner sans pub/branding).
    await refresh();
    return this;
  }

  Future<void> refresh() async {
    try {
      final res = await RequestService().get('/ads/takeover');
      final data = res.data?['data'];
      current.value = data != null ? BrandTakeover.fromJson(data) : null;
    } catch (_) {
      // On ne casse jamais l'app pour une histoire de pub.
    }
  }
}
