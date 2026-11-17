import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/modules/club/controllers/club_map_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:latlong2/latlong.dart' as ll;

/// Carte de secours OpenStreetMap (aucune clé API) : mêmes données que la carte Google, mais
/// avec le dessin Grandpublic — fond doux CARTO (clair/sombre), pins or avec logo partenaire,
/// point rouge pulsé pour « moi », tracé d'itinéraire jaune cerné de noir.
class ClubOsmMap extends StatefulWidget {
  final ClubMapController c;
  final bool dark;
  const ClubOsmMap({super.key, required this.c, required this.dark});

  @override
  State<ClubOsmMap> createState() => _ClubOsmMapState();
}

class _ClubOsmMapState extends State<ClubOsmMap> {
  static ll.LatLng _p(double la, double lo) => ll.LatLng(la, lo);

  ClubMapController get c => widget.c;

  // IMPORTANT : le fournisseur de tuiles et la couche de tuiles sont créés UNE SEULE FOIS.
  // Les recréer à chaque rebuild (position, filtres...) annule les téléchargements en cours : la carte reste blanche.
  late final NetworkTileProvider _provider = NetworkTileProvider();
  bool _loggedError = false;

  /// Clé MapTiler (gratuite) renseignée dans constants/index.dart => MapTiler ; sinon OpenStreetMap (aucune clé).
  static String _url(bool dark) {
    if (MAPTILER_KEY.isNotEmpty) {
      return 'https://api.maptiler.com/maps/${dark ? 'streets-v2-dark' : 'streets-v2'}/256/{z}/{x}/{y}.png?key=$MAPTILER_KEY';
    }
    return dark ? MAP_DARK_TILE_URL : MAP_OSM_TILE_URL;
  }

  TileLayer _tileLayer(bool dark) => TileLayer(
        key: ValueKey('tiles_$dark'),
        urlTemplate: _url(dark),
        fallbackUrl: dark ? MAP_OSM_TILE_URL : MAP_OSM_FALLBACK_TILE_URL,
        userAgentPackageName: MAP_USER_AGENT,
        tileProvider: _provider,
        maxNativeZoom: 19,
        errorTileCallback: (tile, error, stack) {
          if (_loggedError) return;
          _loggedError = true;
          debugPrint('[ClubMap] tuile non chargée: $error');
        },
      );

  late TileLayer _tiles = _tileLayer(widget.dark);

  @override
  void didUpdateWidget(covariant ClubOsmMap old) {
    super.didUpdateWidget(old);
    if (old.dark != widget.dark) _tiles = _tileLayer(widget.dark);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = c.userPos.value;
    final center = start != null ? _p(start.latitude, start.longitude) : _p(MAP_DEFAULT_LAT, MAP_DEFAULT_LNG);

    return FlutterMap(
      mapController: c.osm,
      options: MapOptions(
        initialCenter: center,
        initialZoom: MAP_DEFAULT_ZOOM,
        minZoom: 3,
        maxZoom: 19,
        backgroundColor: widget.dark ? const Color(0xFF1B1B1B) : const Color(0xFFEDE8DD),
        onTap: (_, __) => c.select(null),
        onMapReady: () {
          c.osmReady = true;
          c.fitAll();
        },
      ),
      children: [
        _tiles,
        // Couches dynamiques : chacune réagit seule, sans toucher à la couche de tuiles.
        Obx(() {
          final me = c.userPos.value;
          if (me == null) return const SizedBox.shrink();
          return CircleLayer(circles: [
            CircleMarker(
              point: _p(me.latitude, me.longitude),
              radius: c.radiusKm.value * 1000,
              useRadiusInMeter: true,
              color: GPTheme.clubColor.withValues(alpha: 0.07),
              borderColor: GPTheme.clubColor.withValues(alpha: 0.7),
              borderStrokeWidth: 2,
            ),
          ]);
        }),
        Obx(() {
          final route = c.route.value;
          if (route == null || route.points.length < 2) return const SizedBox.shrink();
          final pts = route.points.map((e) => _p(e.latitude, e.longitude)).toList();
          return PolylineLayer(polylines: [
            Polyline(points: pts, color: const Color(0xFF1A1A1A), strokeWidth: 10, strokeCap: StrokeCap.round, strokeJoin: StrokeJoin.round),
            Polyline(
              points: pts,
              color: const Color(0xFFFFC600),
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
              pattern: route.approximate ? StrokePattern.dashed(segments: const [14, 9]) : const StrokePattern.solid(),
            ),
          ]);
        }),
        Obx(() {
          final me = c.userPos.value;
          final sel = c.selected.value;
          final list = c.visible;
          return MarkerLayer(markers: [
            for (final p in list)
              if (p.hasPosition)
                Marker(
                  point: _p(p.latitude!, p.longitude!),
                  width: 56,
                  height: 72,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(onTap: () => c.select(p), child: _Pin(logo: p.logoUrl, offers: p.offers.length, selected: sel?.id == p.id)),
                ),
            if (me != null) Marker(point: _p(me.latitude, me.longitude), width: 44, height: 44, child: const _MeDot()),
          ]);
        }),
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          popupInitialDisplayDuration: const Duration(seconds: 3),
          attributions: [
            TextSourceAttribution('© OpenStreetMap contributors'),
            TextSourceAttribution('© CARTO / MapTiler'),
          ],
        ),
      ],
    );
  }
}

class _Pin extends StatelessWidget {
  final String? logo;
  final int offers;
  final bool selected;
  const _Pin({this.logo, required this.offers, required this.selected});

  @override
  Widget build(BuildContext context) {
    final s = selected ? 1.18 : 1.0;
    return AnimatedScale(
      scale: s,
      duration: const Duration(milliseconds: 180),
      alignment: Alignment.bottomCenter,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
        Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: GPTheme.clubColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: ClipOval(
              child: logo != null && logo!.isNotEmpty
                  ? Image.network(logo!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: Colors.black, size: 24))
                  : const Icon(Icons.storefront_rounded, color: Colors.black, size: 24),
            ),
          ),
          CustomPaint(size: const Size(14, 10), painter: _Tail()),
        ]),
        if (offers > 0)
          Positioned(
            right: 0,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 1.5)),
              child: Text('$offers', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ),
      ]),
    );
  }
}

class _Tail extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = GPTheme.clubColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MeDot extends StatefulWidget {
  const _MeDot();

  @override
  State<_MeDot> createState() => _MeDotState();
}

class _MeDotState extends State<_MeDot> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Stack(alignment: Alignment.center, children: [
        Container(
          width: 16 + 28 * _a.value,
          height: 16 + 28 * _a.value,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFE53935).withValues(alpha: .3 * (1 - _a.value))),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: const Color(0xFFE53935), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)]),
        ),
      ]),
    );
  }
}
