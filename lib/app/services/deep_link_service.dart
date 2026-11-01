// Liens de partage : https://grandpublic.bj/m/{type}/{id} et grandpublic://{type}/{id}
// Un lien partagé par une chaîne (réseaux sociaux, WhatsApp…) ouvre directement SA chaîne dans l'app.
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class DeepLinkService {
  DeepLinkService._();
  static final _links = AppLinks();
  static StreamSubscription<Uri>? _sub;
  static String? _pending; // lien reçu avant que l'utilisateur soit connecté / l'accueil prêt

  static Future<void> init() async {
    try {
      final first = await _links.getInitialLink();
      if (first != null) _pending = _route(first);
      _sub ??= _links.uriLinkStream.listen((u) {
        final r = _route(u);
        if (r != null) {
          _pending = r;
          consumePending();
        }
      });
    } catch (e) {
      debugPrint('DeepLinkService.init: $e');
    }
  }

  /// Convertit un lien en route interne (null = lien non géré).
  static String? _route(Uri u) {
    final seg = <String>[
      if (u.scheme != 'http' && u.scheme != 'https' && u.host.isNotEmpty) u.host, // grandpublic://channel/5
      ...u.pathSegments.where((s) => s.isNotEmpty),
    ];
    if (seg.isNotEmpty && seg.first == 'm') seg.removeAt(0); // https://…/m/channel/5
    if (seg.length < 2) return null;
    final type = seg[0], id = seg[1];
    switch (type) {
      case 'channel':
        return '/channel/$id';
      case 'media':
        return '/videos?id=$id';
      default:
        return null;
    }
  }

  /// Navigue vers le lien en attente (à appeler quand l'utilisateur est connecté et l'accueil prêt).
  static void consumePending() {
    final r = _pending;
    if (r == null || GetStorage().read('token') == null) return;
    _pending = null;
    Future.delayed(const Duration(milliseconds: 400), () => Get.toNamed(r));
  }
}
