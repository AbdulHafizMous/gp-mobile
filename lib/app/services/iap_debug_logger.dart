// lib/app/services/iap_debug_logger.dart
//
// Petit logger en mémoire pour diagnostiquer RevenueCat/StoreKit sans accès
// à la console Xcode (utile quand on développe sur Windows sans Mac).
// Tout ce qui est loggé ici est visible dans IapDiagnosticsView, à l'écran,
// copiable en un tap.

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/constants/index.dart';

class IapDebugLogger {
  IapDebugLogger._();

  static final RxList<String> logs = <String>[].obs;

  static void log(String message) {
    // Coupe-circuit global : voir `isDebuggingIap` dans constants/index.dart.
    if (!isDebuggingIap) return;
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    String three(int n) => n.toString().padLeft(3, '0');
    final time =
        '${two(now.hour)}:${two(now.minute)}:${two(now.second)}.${three(now.millisecond)}';
    final line = '[$time] $message';
    debugPrint('IAP_DEBUG $line');
    logs.add(line);
    // Garde les 300 dernières lignes pour ne pas grossir indéfiniment
    if (logs.length > 300) logs.removeAt(0);
  }

  static void clear() => logs.clear();

  static String get allAsText => logs.join('\n');
}
