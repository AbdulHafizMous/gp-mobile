import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/models/promotion.dart';
import 'package:grand_public_v2/app/services/club_location_service.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/services/notification_service.dart';

/// Alertes de proximité du Club : quand l'utilisateur passe à moins de [radiusM] mètres (50 par défaut,
/// réglable) d'un partenaire qui a des offres actives, une notification locale est envoyée — même
/// application en arrière-plan (service de localisation Android au premier plan / iOS background location).
class ClubProximityService {
  ClubProximityService._();

  static const _kEnabled = 'club_alerts_enabled';
  static const _kRadius = 'club_alert_radius_m';
  static const _kNotified = 'club_alerts_notified';
  static const defaultRadiusM = 50;
  static const minRadiusM = 20;
  static const maxRadiusM = 500;
  static const cooldown = Duration(hours: 6);

  static StreamSubscription<Position>? _sub;
  static List<PartnerFiche> _partners = [];
  static Position? _fetchedAt;
  static DateTime? _fetchedTime;

  static bool get enabled => GetStorage().read<bool>(_kEnabled) ?? false;
  static int get radiusM => GetStorage().read<int>(_kRadius) ?? defaultRadiusM;

  static Future<void> setRadius(int m) async {
    await GetStorage().write(_kRadius, m.clamp(minRadiusM, maxRadiusM));
  }

  /// Active/désactive les alertes. Active = demande les permissions (toujours) puis démarre.
  /// Retourne false si les permissions sont refusées.
  static Future<bool> setEnabled(bool on) async {
    if (!on) {
      await GetStorage().write(_kEnabled, false);
      await stop();
      return true;
    }
    final ok = await ClubLocationService.ensureAlways();
    // Sans « Toujours », les alertes marchent tout de même app ouverte / récente.
    final fg = ok || await ClubLocationService.ensureForeground();
    if (!fg) return false;
    await GetStorage().write(_kEnabled, true);
    await start();
    return ok;
  }

  /// À appeler au démarrage (utilisateur connecté).
  static Future<void> init() async {
    if (enabled && GetStorage().read('token') != null) await start();
  }

  static Future<void> start() async {
    if (_sub != null) return;
    if (!await ClubLocationService.ensureForeground()) return;
    final LocationSettings settings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Grandpublic Club',
          notificationText: 'Alertes offres à proximité activées',
          notificationChannelName: 'Alertes de proximité',
          enableWakeLock: false,
          setOngoing: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.otherNavigation,
        distanceFilter: 15,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: false,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      settings = const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15);
    }
    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      _onPosition,
      onError: (e) => debugPrint('ClubProximity stream: $e'),
    );
  }

  static Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  static Future<void> _refreshPartners(Position p) async {
    final moved = _fetchedAt == null
        ? double.infinity
        : ClubLocationService.distanceM(_fetchedAt!.latitude, _fetchedAt!.longitude, p.latitude, p.longitude);
    final stale = _fetchedTime == null || DateTime.now().difference(_fetchedTime!) > const Duration(minutes: 30);
    if (!stale && moved < 5000) return;
    try {
      final r = await RequestService().get('/partners/nearby', queryParameters: {'lat': p.latitude, 'lng': p.longitude, 'radius_km': 50});
      if (r.statusCode == 200) {
        _partners = ((r.data['data']['partners']) as List)
            .map((e) => PartnerFiche.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((x) => x.hasPosition && x.offers.isNotEmpty)
            .toList();
        _fetchedAt = p;
        _fetchedTime = DateTime.now();
      }
    } catch (e) {
      debugPrint('ClubProximity fetch: $e');
    }
  }

  static Future<void> _onPosition(Position p) async {
    if (GetStorage().read('token') == null) return;
    await _refreshPartners(p);
    if (_partners.isEmpty) return;
    final box = GetStorage();
    final notified = Map<String, dynamic>.from(box.read(_kNotified) ?? {});
    final now = DateTime.now().millisecondsSinceEpoch;
    var changed = false;
    for (final pa in _partners) {
      final d = ClubLocationService.distanceM(p.latitude, p.longitude, pa.latitude!, pa.longitude!);
      if (d > radiusM) continue;
      final last = (notified['${pa.id}'] as int?) ?? 0;
      if (now - last < cooldown.inMilliseconds) continue;
      notified['${pa.id}'] = now;
      changed = true;
      final n = pa.offers.length;
      await NotificationService.showLocalNotification(
        id: 7000 + pa.id,
        title: '🎁 ${pa.companyName} est tout près !',
        body: n == 1 ? pa.offers.first.title : '${pa.offers.first.title} · +${n - 1} autre${n > 2 ? 's' : ''} offre${n > 2 ? 's' : ''}',
        route: jsonEncode({'type': 'partner', 'partner_id': pa.id}),
      );
    }
    if (changed) await box.write(_kNotified, notified);
  }
}
