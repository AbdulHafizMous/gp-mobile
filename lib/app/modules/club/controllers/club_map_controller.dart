import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart' show Color, debugPrint, EdgeInsets;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/promotion.dart';
import 'package:grand_public_v2/app/modules/club/views/club_marker_factory.dart';
import 'package:grand_public_v2/app/services/club_location_service.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

class ClubRoute {
  final List<LatLng> points;
  final int distanceM;
  final int durationS;
  final bool approximate;
  const ClubRoute({required this.points, required this.distanceM, required this.durationS, required this.approximate});
}

/// Carte du Club : position de l'utilisateur, partenaires dans le rayon (max 50 km), sélection,
/// itinéraire. Les marqueurs sont dessinés (voir [ClubMarkerFactory]).
class ClubMapController extends GetxController {
  static const radiusOptions = <double>[1, 5, 10, 25, 50];

  final userPos = Rxn<LatLng>();
  final partners = <PartnerFiche>[].obs;
  final radiusKm = 10.0.obs;
  final loading = false.obs;
  final permissionDenied = false.obs;
  final offersMode = false.obs;
  final selected = Rxn<PartnerFiche>();
  final route = Rxn<ClubRoute>();
  final routeMode = 'driving'.obs;
  final routeLoading = false.obs;
  final markers = <Marker>{}.obs;
  final polylines = <Polyline>{}.obs;

  GoogleMapController? map;

  // ── Carte : réglages dans constants/index.dart (MAP_PROVIDER, MAP_DEFAULT_*) ──
  // Le fond par défaut vient TOUJOURS de MAP_PROVIDER : un ancien choix mémorisé (Google sans clé = carte blanche)
  // ne peut plus bloquer l'affichage. Le bouton « calques » bascule seulement pour la session en cours.
  final useOsm = (MAP_PROVIDER != 'google').obs;

  // Style de carte choisi (mémorisé). Défaut : MapTiler si une clé est configurée, sinon le style standard gratuit.
  static const _styleKey = 'club_map_style_v1';
  final mapStyle = _initialStyle().obs;
  static String _initialStyle() {
    String? saved;
    try {
      saved = GetStorage().read<String>(_styleKey);
    } catch (_) {}
    final ok = MAP_STYLES.any((m) => m['id'] == saved && (m['needsKey'] != true || MAPTILER_KEY.isNotEmpty));
    if (ok) return saved!;
    return MAPTILER_KEY.isNotEmpty ? 'mt_streets' : MAP_DEFAULT_STYLE;
  }

  void setMapStyle(String id) {
    mapStyle.value = id;
    useOsm.value = true;
    try {
      GetStorage().write(_styleKey, id);
    } catch (_) {}
  }

  /// Centre par défaut (Cotonou) quand la position de l'utilisateur est indisponible.
  static const defaultCenter = LatLng(MAP_DEFAULT_LAT, MAP_DEFAULT_LNG);
  LatLng get center => userPos.value ?? defaultCenter;
  final fm.MapController osm = fm.MapController();
  bool osmReady = false;

  void setUseOsm(bool v) {
    useOsm.value = v;
    map = null;
    osmReady = false;
  }

  /// Google n'a pas fini de s'initialiser (clé absente / services indisponibles) → bascule sur OSM.
  void googleFailed() {
    if (!useOsm.value) setUseOsm(true);
  }
  StreamSubscription<Position>? _sub;

  /// Partenaires affichés (en mode « Offres » : uniquement ceux qui ont des offres actives).
  List<PartnerFiche> get visible =>
      partners.where((p) => p.offers.isNotEmpty).toList(); // un partenaire sans offre active n'est pas affiché

  Future<void> start() async {
    loading.value = true;
    final p = await ClubLocationService.current();
    if (p == null) {
      // Pas de position : on affiche quand même la carte et les partenaires autour de Cotonou.
      permissionDenied.value = true;
      await refreshNearby();
      return;
    }
    permissionDenied.value = false;
    userPos.value = LatLng(p.latitude, p.longitude);
    await refreshNearby();
    _sub?.cancel();
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 8),
    ).listen((pos) {
      userPos.value = LatLng(pos.latitude, pos.longitude);
      _rebuildMarkers();
    }, onError: (_) {});
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }

  Future<void> refreshNearby() async {
    final u = center;
    loading.value = true;
    try {
      final r = await RequestService().get('/partners/nearby', queryParameters: {'lat': u.latitude, 'lng': u.longitude, 'radius_km': permissionDenied.value ? 50 : radiusKm.value});
      if (r.statusCode == 200) {
        partners.assignAll((r.data['data']['partners'] as List)
            .map((e) => PartnerFiche.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((p) => p.hasPosition));
      }
    } catch (e) {
      debugPrint('ClubMap refreshNearby: $e');
    } finally {
      loading.value = false;
    }
    if (selected.value != null && !partners.any((p) => p.id == selected.value!.id)) selected.value = null;
    await _rebuildMarkers();
    fitAll();
  }

  Future<void> setRadius(double km) async {
    radiusKm.value = km;
    clearRoute();
    await refreshNearby();
  }

  void toggleOffersMode(bool v) {
    offersMode.value = v;
    _rebuildMarkers();
  }

  Future<void> _rebuildMarkers() async {
    final me = await ClubMarkerFactory.me();
    final set = <Marker>{};
    final u = userPos.value;
    if (u != null) {
      set.add(Marker(markerId: const MarkerId('me'), position: u, icon: me, anchor: const Offset(0.5, 0.5), zIndexInt: 10, consumeTapEvents: true));
    }
    for (final p in visible) {
      final sel = selected.value?.id == p.id;
      set.add(Marker(
        markerId: MarkerId('p${p.id}'),
        position: LatLng(p.latitude!, p.longitude!),
        icon: await ClubMarkerFactory.partner(p, selected: sel),
        anchor: const Offset(0.5, 1.0),
        zIndexInt: sel ? 5 : 1,
        onTap: () => select(p),
      ));
    }
    final r = route.value;
    if (r != null && selected.value != null) {
      set.add(Marker(markerId: const MarkerId('dest'), position: LatLng(selected.value!.latitude!, selected.value!.longitude!), icon: await ClubMarkerFactory.flag(), anchor: const Offset(0.2, 1.0), zIndexInt: 6));
    }
    markers.assignAll(set);
  }

  void select(PartnerFiche? p, {bool animate = true}) {
    selected.value = p;
    if (route.value != null && p != null) clearRoute(rebuild: false);
    _rebuildMarkers();
    if (p != null && animate && p.hasPosition) {
      map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(p.latitude!, p.longitude!), 16.2));
      if (useOsm.value && osmReady) osm.move(ll.LatLng(p.latitude!, p.longitude!), 16.2);
    }
  }

  double? distanceTo(PartnerFiche p) {
    final u = userPos.value;
    if (u == null || !p.hasPosition) return p.distanceKm == null ? null : p.distanceKm! * 1000;
    return ClubLocationService.distanceM(u.latitude, u.longitude, p.latitude!, p.longitude!);
  }

  void recenter() {
    final u = userPos.value;
    if (u == null) return;
    map?.animateCamera(CameraUpdate.newLatLngZoom(u, 15.5));
    if (useOsm.value && osmReady) osm.move(ll.LatLng(u.latitude, u.longitude), 15.5);
  }

  void fitAll() {
    final u = center;
    if (map == null && !(useOsm.value && osmReady)) return;
    final pts = <LatLng>[if (userPos.value != null) u, ...visible.map((p) => LatLng(p.latitude!, p.longitude!))];
    if (pts.isEmpty) {
      map?.animateCamera(CameraUpdate.newLatLngZoom(u, 12.5));
      if (useOsm.value && osmReady) osm.move(ll.LatLng(u.latitude, u.longitude), 12.5);
      return;
    }
    if (pts.length == 1) {
      map?.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 14));
      if (useOsm.value && osmReady) osm.move(ll.LatLng(pts.first.latitude, pts.first.longitude), 14);
      return;
    }
    double minLa = pts.first.latitude, maxLa = minLa, minLo = pts.first.longitude, maxLo = minLo;
    for (final p in pts) {
      if (p.latitude < minLa) minLa = p.latitude;
      if (p.latitude > maxLa) maxLa = p.latitude;
      if (p.longitude < minLo) minLo = p.longitude;
      if (p.longitude > maxLo) maxLo = p.longitude;
    }
    if (useOsm.value && osmReady) {
      if ((maxLa - minLa).abs() < 1e-5 && (maxLo - minLo).abs() < 1e-5) {
        osm.move(ll.LatLng(minLa, minLo), 14);
      } else {
        try {
          osm.fitCamera(fm.CameraFit.bounds(bounds: fm.LatLngBounds(ll.LatLng(minLa, minLo), ll.LatLng(maxLa, maxLo)), padding: const EdgeInsets.all(48), maxZoom: 16));
        } catch (_) {
          osm.move(ll.LatLng(minLa, minLo), 13);
        }
      }
      return;
    }
    map?.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(minLa, minLo), northeast: LatLng(maxLa, maxLo)), 80));
  }

  // ── Itinéraire ──────────────────────────────────────────────────────────
  Future<void> startRoute(PartnerFiche p, {String? mode}) async {
    final u = userPos.value;
    if (u == null || !p.hasPosition) return;
    if (mode != null) routeMode.value = mode;
    selected.value = p;
    routeLoading.value = true;
    try {
      final r = await RequestService().get('/partners/route', queryParameters: {
        'from_lat': u.latitude,
        'from_lng': u.longitude,
        'to_lat': p.latitude,
        'to_lng': p.longitude,
        'mode': routeMode.value,
      });
      if (r.statusCode == 200) {
        final d = r.data['data'];
        route.value = ClubRoute(
          points: (d['points'] as List).map((e) => LatLng((e[0] as num).toDouble(), (e[1] as num).toDouble())).toList(),
          distanceM: (d['distance_m'] as num).toInt(),
          durationS: (d['duration_s'] as num).toInt(),
          approximate: d['approximate'] == true,
        );
      }
    } catch (e) {
      final m = ClubLocationService.distanceM(u.latitude, u.longitude, p.latitude!, p.longitude!);
      route.value = ClubRoute(
        points: [u, LatLng(p.latitude!, p.longitude!)],
        distanceM: (m * 1.3).round(),
        durationS: ClubLocationService.estimateSeconds(m, walking: routeMode.value == 'walking'),
        approximate: true,
      );
    } finally {
      routeLoading.value = false;
    }
    final r = route.value;
    if (r == null) return;
    polylines.assignAll({
      Polyline(polylineId: const PolylineId('route_casing'), points: r.points, color: const Color(0xFF1A1A1A), width: 10, zIndex: 1, jointType: JointType.round, startCap: Cap.roundCap, endCap: Cap.roundCap),
      Polyline(polylineId: const PolylineId('route'), points: r.points, color: const Color(0xFFFFC600), width: 6, zIndex: 2, jointType: JointType.round, startCap: Cap.roundCap, endCap: Cap.roundCap, patterns: r.approximate ? [PatternItem.dash(18), PatternItem.gap(10)] : const []),
    });
    await _rebuildMarkers();
    _fitRoute(r);
  }

  void _fitRoute(ClubRoute r) {
    if ((map == null && !(useOsm.value && osmReady)) || r.points.length < 2) return;
    double minLa = r.points.first.latitude, maxLa = minLa, minLo = r.points.first.longitude, maxLo = minLo;
    for (final p in r.points) {
      if (p.latitude < minLa) minLa = p.latitude;
      if (p.latitude > maxLa) maxLa = p.latitude;
      if (p.longitude < minLo) minLo = p.longitude;
      if (p.longitude > maxLo) maxLo = p.longitude;
    }
    if (useOsm.value && osmReady) {
      osm.fitCamera(fm.CameraFit.bounds(bounds: fm.LatLngBounds(ll.LatLng(minLa, minLo), ll.LatLng(maxLa, maxLo)), padding: const EdgeInsets.all(48), maxZoom: 17));
      return;
    }
    map?.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(minLa, minLo), northeast: LatLng(maxLa, maxLo)), 90));
  }

  void clearRoute({bool rebuild = true}) {
    route.value = null;
    polylines.clear();
    if (rebuild) _rebuildMarkers();
  }
}