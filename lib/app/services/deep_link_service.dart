// Liens de partage : https://grandpublic.bj/m/{type}/{id} et grandpublic://{type}/{id}
// Un lien partagé par une chaîne (réseaux sociaux, WhatsApp…) ouvre directement SA chaîne dans l'app.
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:grand_public_v2/app/utils/app_link_router.dart';
// import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class DeepLinkService {
  DeepLinkService._();
  static final _links = AppLinks();
  static StreamSubscription<Uri>? _sub;
  static Uri? _pending; // lien reçu avant que l'utilisateur soit connecté / l'accueil prêt

  static Future<void> init() async {
    try {
      final first = await _links.getInitialLink();
      if (first != null) _pending = _accept(first);
      await _checkDeferred();
      _sub ??= _links.uriLinkStream.listen((u) {
        final r = _accept(u);
        if (r != null) {
          _pending = r;
          consumePending();
        }
      });
    } catch (e) {
      debugPrint('DeepLinkService.init: $e');
    }
  }

  /// Un lien est géré s'il a un type + un id (ou une salle Youwiiin).
  static Uri? _accept(Uri u) {
    final n = <String>[
      if (u.scheme != 'http' && u.scheme != 'https' && u.host.isNotEmpty) u.host,
      ...u.pathSegments.where((s) => s.isNotEmpty),
    ];
    if (n.isNotEmpty && n.first == 'm') n.removeAt(0);
    return n.length >= 2 ? u : null;
  }

  /// Navigue vers le lien en attente (à appeler quand l'utilisateur est connecté et l'accueil prêt).
  static void consumePending() {
    final r = _pending;
    if (r == null || GetStorage().read('token') == null) return;
    _pending = null;
    Future.delayed(const Duration(milliseconds: 400), () => AppLinkRouter.routeFromUri(r));
  }

  /// Lien différé : si l'app vient d'être installée depuis un partage, la page web a copié
  /// `https://grandpublic.bj/m/...` dans le presse-papiers → on l'ouvre au premier lancement.
  static Future<void> _checkDeferred() async {
    try {
      final box = GetStorage();
      if (box.read('deferred_link_checked') == true) return;
      await box.write('deferred_link_checked', true);
      final clip = (await Clipboard.getData('text/plain'))?.text?.trim();
      if (clip == null || !clip.startsWith('https://grandpublic.bj/m/')) return;
      final u = Uri.tryParse(clip);
      if (u != null && _accept(u) != null) {
        _pending ??= u;
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    } catch (_) {}
  }
}
