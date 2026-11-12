import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/club/controllers/club_map_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:latlong2/latlong.dart' as ll;

/// Carte de secours OpenStreetMap (aucune clé API) : mêmes données que la carte Google, mais
/// avec le dessin Grandpublic — fond doux CARTO (clair/sombre), pins or avec logo partenaire,
/// point rouge pulsé pour « moi », tracé d'itinéraire jaune cerné de noir.
class ClubOsmMap extends StatelessWidget {
  final ClubMapController c;
  final bool dark;
  const ClubOsmMap({super.key, required this.c, required this.dark});

  static ll.LatLng _p(double la, double lo) => ll.LatLng(la, lo);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final me = c.userPos.value;
      final sel = c.selected.value;
      final route = c.route.value;
      final list = c.visible; // lu ici pour réagir aux changements
      final radius = c.radiusKm.value;
      final center = me != null ? _p(me.latitude, me.longitude) : _p(6.3703, 2.3912);

      final tile = TileLayer(
        urlTemplate: dark
            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
            : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
        subdomains: const ['a', 'b', 'c', 'd'],
        userAgentPackageName: 'bj.grandpublic.app',
        retinaMode: RetinaMode.isHighDensity(context),
        maxNativeZoom: 19,
      );

      return FlutterMap(
        mapController: c.osm,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13.5,
          minZoom: 3,
          maxZoom: 19,
          onTap: (_, __) => c.select(null),
          onMapReady: () {
            c.osmReady = true;
            c.fitAll();
          },
        ),
        children: [
          // Teinte chaude en thème clair, pour rester dans l'univers Grandpublic.
          dark
              ? tile
              : ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    1.02, 0.02, 0, 0, 4,
                    0.01, 1.0, 0, 0, 2,
                    0, 0.02, 0.92, 0, -6,
                    0, 0, 0, 1, 0,
                  ]),
                  child: tile,
                ),
          if (me != null)
            CircleLayer(circles: [
              CircleMarker(
                point: _p(me.latitude, me.longitude),
                radius: radius * 1000,
                useRadiusInMeter: true,
                color: GPTheme.clubColor.withValues(alpha: 0.07),
                borderColor: GPTheme.clubColor.withValues(alpha: 0.7),
                borderStrokeWidth: 2,
              ),
            ]),
          if (route != null && route.points.length > 1) ...[
            PolylineLayer(polylines: [
              Polyline(points: route.points.map((e) => _p(e.latitude, e.longitude)).toList(), color: const Color(0xFF1A1A1A), strokeWidth: 10, strokeCap: StrokeCap.round, strokeJoin: StrokeJoin.round),
            ]),
            PolylineLayer(polylines: [
              Polyline(
                points: route.points.map((e) => _p(e.latitude, e.longitude)).toList(),
                color: const Color(0xFFFFC600),
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
                pattern: route.approximate ? StrokePattern.dashed(segments: const [14, 9]) : const StrokePattern.solid(),
              ),
            ]),
          ],
          MarkerLayer(markers: [
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
          ]),
          RichAttributionWidget(
            alignment: AttributionAlignment.bottomLeft,
            popupInitialDisplayDuration: const Duration(seconds: 3),
            attributions: [
              TextSourceAttribution('© OpenStreetMap contributors'),
              TextSourceAttribution('© CARTO'),
            ],
          ),
        ],
      );
    });
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
