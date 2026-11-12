import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Position de l'utilisateur pour le Club : permissions (Android + iOS), position courante,
/// distance et estimations de trajet.
class ClubLocationService {
  ClubLocationService._();

  /// Demande la permission « pendant l'utilisation ». Retourne true si accordée.
  static Future<bool> ensureForeground() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  /// Demande « Toujours » (nécessaire aux alertes de proximité quand l'app est fermée).
  static Future<bool> ensureAlways() async {
    if (!await ensureForeground()) return false;
    var s = await Permission.locationAlways.status;
    if (!s.isGranted) s = await Permission.locationAlways.request();
    return s.isGranted;
  }

  static Future<bool> hasAlways() async => (await Permission.locationAlways.status).isGranted;

  static Future<bool> isPermanentlyDenied() async =>
      (await Geolocator.checkPermission()) == LocationPermission.deniedForever;

  static Future<void> openSettings() => openAppSettings();

  static Future<Position?> current() async {
    try {
      if (!await ensureForeground()) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)),
      );
    } catch (e) {
      debugPrint('ClubLocationService.current: $e');
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// Distance en mètres (haversine).
  static double distanceM(double la1, double lo1, double la2, double lo2) {
    const r = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final a = math.pow(math.sin(rad(la2 - la1) / 2), 2) +
        math.cos(rad(la1)) * math.cos(rad(la2)) * math.pow(math.sin(rad(lo2 - lo1) / 2), 2);
    return r * 2 * math.asin(math.min(1, math.sqrt(a.toDouble())));
  }

  static String formatDistance(double meters) =>
      meters < 1000 ? '${meters.round()} m' : '${(meters / 1000).toStringAsFixed(meters < 10000 ? 1 : 0)} km';

  /// Estimation à vol d'oiseau ×1.3 : marche 5 km/h, moto/voiture ~25 km/h en ville.
  static String formatDuration(int seconds) {
    final m = (seconds / 60).round();
    if (m < 1) return '< 1 min';
    if (m < 60) return '$m min';
    return '${m ~/ 60} h ${(m % 60).toString().padLeft(2, '0')}';
  }

  static int estimateSeconds(double meters, {bool walking = false}) =>
      (meters * 1.3 / ((walking ? 5.0 : 25.0) * 1000 / 3600)).round();
}
