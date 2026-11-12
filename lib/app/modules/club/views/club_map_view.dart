import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:grand_public_v2/app/data/models/promotion.dart';
import 'package:grand_public_v2/app/modules/club/controllers/club_map_controller.dart';
import 'package:grand_public_v2/app/modules/club/views/club_map_style.dart';
import 'package:grand_public_v2/app/modules/club/views/club_osm_map.dart';
import 'package:grand_public_v2/app/modules/club/views/partner_detail_view.dart';
import 'package:grand_public_v2/app/services/club_location_service.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/share_helper.dart';
import 'package:url_launcher/url_launcher.dart';

extension _Tx on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? const Color(0xFF14141A) : Colors.white;
  Color get primary => Theme.of(this).textTheme.bodyLarge!.color!;
  Color get subtle => Theme.of(this).hintColor;
}

/// Carte du Club : partenaires et offres autour de moi (rayon max 50 km), marqueurs Grandpublic,
/// ma position, distance, itinéraire.
class ClubMapView extends StatefulWidget {
  const ClubMapView({super.key});

  @override
  State<ClubMapView> createState() => _ClubMapViewState();
}

class _ClubMapViewState extends State<ClubMapView> {
  late final ClubMapController c = Get.isRegistered<ClubMapController>() ? Get.find<ClubMapController>() : Get.put(ClubMapController());
  final PageController _pager = PageController(viewportFraction: 0.88);

  Timer? _googleWatchdog;

  @override
  void initState() {
    super.initState();
    c.start();
    // Si Google Maps ne s'initialise pas (clé API absente, services indisponibles) : bascule auto sur OpenStreetMap.
    if (!c.useOsm.value) {
      _googleWatchdog = Timer(const Duration(seconds: 6), () {
        if (mounted && c.map == null) c.googleFailed();
      });
    }
  }

  @override
  void dispose() {
    _googleWatchdog?.cancel();
    c.stop();
    c.map = null;
    _pager.dispose();
    super.dispose();
  }

  void _openSheet(PartnerFiche p) {
    c.select(p);
    Get.bottomSheet(_PartnerSheet(p: p, c: c), isScrollControlled: true, backgroundColor: Colors.transparent);
  }

  @override
  Widget build(BuildContext context) {
    final start = c.userPos.value ?? const LatLng(6.3703, 2.3912); // Cotonou par défaut
    return Stack(children: [
      Positioned.fill(
        child: Obx(
          () => c.useOsm.value
              ? ClubOsmMap(c: c, dark: context.isDark)
              : GoogleMap(
            initialCameraPosition: CameraPosition(target: start, zoom: 13.5),
            style: context.isDark ? kClubMapStyleDark : kClubMapStyleLight,
            markers: c.markers.toSet(),
            polylines: c.polylines.toSet(),
            circles: {
              if (c.userPos.value != null)
                Circle(
                  circleId: const CircleId('radius'),
                  center: c.userPos.value!,
                  radius: c.radiusKm.value * 1000,
                  strokeColor: GPTheme.clubColor.withValues(alpha: 0.7),
                  strokeWidth: 2,
                  fillColor: GPTheme.clubColor.withValues(alpha: 0.07),
                ),
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            rotateGesturesEnabled: true,
            padding: const EdgeInsets.only(top: 110, bottom: 210),
            onMapCreated: (m) {
              c.map = m;
              if (c.userPos.value != null) c.fitAll();
            },
            onTap: (_) => c.select(null),
          ),
        ),
      ),

      // ── Bandeau haut : rayon + mode ────────────────────────────────────
      Positioned(
        top: 8,
        left: 0,
        right: 0,
        child: Column(children: [
          SizedBox(
            height: 38,
            child: Obx(
              () => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _Pill(
                    icon: Icons.local_offer_rounded,
                    label: c.offersMode.value ? 'Offres' : 'Partenaires',
                    active: true,
                    onTap: () => c.toggleOffersMode(!c.offersMode.value),
                  ),
                  const SizedBox(width: 8),
                  for (final r in ClubMapController.radiusOptions) ...[
                    _Pill(label: r < 1 ? '${(r * 1000).round()} m' : '${r.round()} km', active: c.radiusKm.value == r, onTap: () => c.setRadius(r)),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
        ]),
      ),

      // ── Boutons latéraux ───────────────────────────────────────────────
      Positioned(
        right: 12,
        top: 58,
        child: Column(children: [
          Obx(() => _RoundBtn(icon: c.useOsm.value ? Icons.map_rounded : Icons.layers_rounded, onTap: () => c.setUseOsm(!c.useOsm.value))),
          const SizedBox(height: 8),
          _RoundBtn(icon: Icons.my_location_rounded, onTap: c.recenter),
          const SizedBox(height: 8),
          _RoundBtn(icon: Icons.zoom_out_map_rounded, onTap: c.fitAll),
        ]),
      ),

      // ── Chargement ─────────────────────────────────────────────────────
      Obx(() => c.loading.value
          ? Positioned(
              top: 52,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: context.bg, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: GPTheme.clubColor)),
                    const SizedBox(width: 8),
                    Text('Recherche autour de toi…', style: TextStyle(color: context.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            )
          : const SizedBox.shrink()),

      // ── Permission refusée ─────────────────────────────────────────────
      Obx(() => c.permissionDenied.value
          ? Positioned.fill(
              child: Container(
                color: context.bg.withValues(alpha: 0.94),
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.location_off_rounded, size: 56, color: GPTheme.clubColor),
                  const SizedBox(height: 14),
                  Text('Active ta position', style: TextStyle(color: context.primary, fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 6),
                  Text('Pour voir les partenaires et offres autour de toi, autorise l\'accès à ta position.', textAlign: TextAlign.center, style: TextStyle(color: context.subtle)),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: GPTheme.clubColor, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
                    onPressed: () async {
                      if (await ClubLocationService.isPermanentlyDenied()) {
                        await ClubLocationService.openSettings();
                      } else {
                        c.start();
                      }
                    },
                    icon: const Icon(Icons.my_location_rounded),
                    label: const Text('Autoriser', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ]),
              ),
            )
          : const SizedBox.shrink()),

      // ── Bas : itinéraire OU carrousel ──────────────────────────────────
      Positioned(
        left: 0,
        right: 0,
        bottom: 84,
        child: Obx(() {
          if (c.route.value != null || c.routeLoading.value) return _RouteBar(c: c);
          final list = c.visible;
          if (list.isEmpty) {
            return c.loading.value || c.permissionDenied.value
                ? const SizedBox.shrink()
                : Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: context.bg, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
                      child: Text(
                        c.offersMode.value ? 'Aucune offre dans ce rayon. Élargis la recherche.' : 'Aucun partenaire dans ce rayon. Élargis la recherche.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.subtle, fontSize: 13),
                      ),
                    ),
                  );
          }
          // Quand un marqueur est tapé, le carrousel saute sur la bonne carte.
          final sel = c.selected.value;
          if (sel != null) {
            final i = list.indexWhere((p) => p.id == sel.id);
            if (i >= 0 && _pager.hasClients && (_pager.page?.round() ?? 0) != i) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_pager.hasClients) _pager.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              });
            }
          }
          return SizedBox(
            height: 142,
            child: PageView.builder(
              controller: _pager,
              itemCount: list.length,
              onPageChanged: (i) => c.select(list[i]),
              itemBuilder: (_, i) => _PartnerCard(p: list[i], c: c, onTap: () => _openSheet(list[i])),
            ),
          );
        }),
      ),
    ]);
  }
}

class _Pill extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Pill({this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? GPTheme.clubColor : context.bg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 15, color: Colors.black), const SizedBox(width: 6)],
            Text(label, style: TextStyle(color: active ? Colors.black : context.primary, fontWeight: FontWeight.w800, fontSize: 12.5)),
          ]),
        ),
      );
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: context.bg,
        elevation: 4,
        shape: const CircleBorder(),
        child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Padding(padding: const EdgeInsets.all(11), child: Icon(icon, size: 20, color: context.primary))),
      );
}

class _PartnerCard extends StatelessWidget {
  final PartnerFiche p;
  final ClubMapController c;
  final VoidCallback onTap;
  const _PartnerCard({required this.p, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = c.distanceTo(p);
    final offer = p.offers.isNotEmpty ? p.offers.first : null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GPTheme.clubColor.withValues(alpha: 0.6), width: 1.4),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Row(children: [
          _Logo(url: p.logoUrl, size: 62),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(p.companyName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.primary, fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.near_me_rounded, size: 13, color: GPTheme.primaryColor),
                const SizedBox(width: 4),
                Text(d == null ? '—' : ClubLocationService.formatDistance(d), style: TextStyle(color: GPTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 12)),
                if (d != null) ...[
                  Text('  ·  ', style: TextStyle(color: context.subtle)),
                  Icon(Icons.directions_walk_rounded, size: 13, color: context.subtle),
                  Text(' ${ClubLocationService.formatDuration(ClubLocationService.estimateSeconds(d, walking: true))}', style: TextStyle(color: context.subtle, fontSize: 12)),
                ],
              ]),
              const SizedBox(height: 5),
              if (offer != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: GPTheme.clubColor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🎁 ', style: TextStyle(fontSize: 12)),
                    Flexible(child: Text(offer.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.primary, fontSize: 12, fontWeight: FontWeight.w700))),
                  ]),
                )
              else
                Text(p.address ?? 'Partenaire Grandpublic', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.subtle, fontSize: 12)),
            ]),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => c.startRoute(p),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: GPTheme.primaryColor, shape: BoxShape.circle),
              child: const Icon(Icons.directions_rounded, color: Colors.white, size: 22),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String? url;
  final double size;
  const _Logo({this.url, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: GPTheme.clubColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(size * 0.3),
          border: Border.all(color: Colors.black87, width: 1.6),
        ),
        child: (url != null && url!.isNotEmpty)
            ? Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: Colors.black87))
            : const Icon(Icons.storefront_rounded, color: Colors.black87),
      );
}

class _RouteBar extends StatelessWidget {
  final ClubMapController c;
  const _RouteBar({required this.c});

  @override
  Widget build(BuildContext context) => Obx(() => _body(context));

  Widget _body(BuildContext context) {
    final p = c.selected.value;
    final r = c.route.value;
    final mode = c.routeMode.value;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.bg, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 14, offset: Offset(0, 4))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: Text(p?.companyName ?? 'Itinéraire', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.primary, fontWeight: FontWeight.w900, fontSize: 15))),
          IconButton(visualDensity: VisualDensity.compact, icon: Icon(Icons.close_rounded, color: context.subtle), onPressed: c.clearRoute),
        ]),
        Row(children: [
              for (final m in const [('driving', Icons.two_wheeler_rounded, 'Moto/Voiture'), ('walking', Icons.directions_walk_rounded, 'À pied'), ('cycling', Icons.pedal_bike_rounded, 'Vélo')]) ...[
                GestureDetector(
                  onTap: () => p == null ? null : c.startRoute(p, mode: m.$1),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: mode == m.$1 ? GPTheme.clubColor : Colors.transparent, borderRadius: BorderRadius.circular(14), border: Border.all(color: mode == m.$1 ? Colors.black87 : context.subtle.withValues(alpha: 0.4))),
                    child: Row(children: [Icon(m.$2, size: 15, color: mode == m.$1 ? Colors.black : context.subtle), const SizedBox(width: 4), Text(m.$3, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: mode == m.$1 ? Colors.black : context.subtle))]),
                  ),
                ),
              ],
            ]),
        const SizedBox(height: 10),
        if (c.routeLoading.value || r == null)
          const Padding(padding: EdgeInsets.all(6), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
        else
          Row(children: [
            Text(ClubLocationService.formatDuration(r.durationS), style: TextStyle(color: GPTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 24)),
            const SizedBox(width: 10),
            Text('${r.approximate ? '≈ ' : ''}${ClubLocationService.formatDistance(r.distanceM.toDouble())}', style: TextStyle(color: context.subtle, fontWeight: FontWeight.w700)),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: GPTheme.primaryColor, foregroundColor: Colors.white, shape: const StadiumBorder()),
              onPressed: p == null ? null : () => _openExternal(p, c),
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: const Text('Naviguer', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
      ]),
    );
  }
}

Future<void> _openExternal(PartnerFiche p, ClubMapController c) async {
  final u = c.userPos.value;
  final mode = {'driving': 'driving', 'walking': 'walking', 'cycling': 'bicycling'}[c.routeMode.value] ?? 'driving';
  final url = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}&travelmode=$mode${u != null ? '&origin=${u.latitude},${u.longitude}' : ''}',
  );
  await launchUrl(url, mode: LaunchMode.externalApplication);
}

/// Fiche détaillée : bandeau, logo, distance/ETA, offres, itinéraire, appel, partage.
class _PartnerSheet extends StatelessWidget {
  final PartnerFiche p;
  final ClubMapController c;
  const _PartnerSheet({required this.p, required this.c});

  @override
  Widget build(BuildContext context) {
    final d = c.distanceTo(p);
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.94,
      expand: false,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(color: context.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        clipBehavior: Clip.antiAlias,
        child: ListView(controller: sc, padding: EdgeInsets.zero, children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [GPTheme.clubColor, const Color(0xFFFF8A00), GPTheme.primaryColor]),
              ),
              child: (p.bannerUrl != null && p.bannerUrl!.isNotEmpty) ? Image.network(p.bannerUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()) : null,
            ),
            Positioned(top: 10, left: 0, right: 0, child: Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(2))))),
            Positioned(left: 18, bottom: -34, child: _Logo(url: p.logoUrl, size: 76)),
          ]),
          const SizedBox(height: 42),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.companyName, style: TextStyle(color: context.primary, fontWeight: FontWeight.w900, fontSize: 22)),
              if (p.address != null && p.address!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(children: [Icon(Icons.place_rounded, size: 15, color: context.subtle), const SizedBox(width: 4), Expanded(child: Text(p.address!, style: TextStyle(color: context.subtle, fontSize: 13)))]),
              ],
              const SizedBox(height: 14),
              Row(children: [
                _Stat(icon: Icons.near_me_rounded, label: 'Distance', value: d == null ? '—' : ClubLocationService.formatDistance(d)),
                const SizedBox(width: 10),
                _Stat(icon: Icons.directions_walk_rounded, label: 'À pied', value: d == null ? '—' : ClubLocationService.formatDuration(ClubLocationService.estimateSeconds(d, walking: true))),
                const SizedBox(width: 10),
                _Stat(icon: Icons.two_wheeler_rounded, label: 'Moto', value: d == null ? '—' : ClubLocationService.formatDuration(ClubLocationService.estimateSeconds(d))),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: GPTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: () {
                      Get.back();
                      c.startRoute(p);
                    },
                    icon: const Icon(Icons.directions_rounded),
                    label: const Text('Itinéraire', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 8),
                if (p.phone != null && p.phone!.isNotEmpty) ...[
                  _SquareBtn(icon: Icons.call_rounded, onTap: () => launchUrl(Uri.parse('tel:${p.phone}'))),
                  const SizedBox(width: 8),
                ],
                _SquareBtn(icon: Icons.ios_share_rounded, onTap: () => ShareHelper.showShareSheet(context, title: p.companyName, subtitle: p.address, type: 'partner', id: '${p.id}', imageUrl: p.logoUrl)),
              ]),
              const SizedBox(height: 20),
              Text(p.offers.isEmpty ? 'Aucune offre active pour le moment' : 'Offres du moment', style: TextStyle(color: context.primary, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 8),
              for (final o in p.offers)
                GestureDetector(
                  onTap: () {
                    Get.back();
                    Get.to(() => PartnerDetailView(partnerId: p.id));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: GPTheme.clubColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: GPTheme.clubColor.withValues(alpha: 0.5))),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (o.imageUrl != null && o.imageUrl!.isNotEmpty)
                            ? Image.network(o.imageUrl!, width: 58, height: 58, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _offerIcon())
                            : _offerIcon(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(o.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.primary, fontWeight: FontWeight.w800, fontSize: 14)),
                          if (o.endsAt != null) Text('Jusqu\'au ${o.endsAt}', style: TextStyle(color: context.subtle, fontSize: 11.5)),
                          if (o.gcoinPrice != null) Text('🪙 ${o.gcoinPrice} GCoin', style: TextStyle(color: GPTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 12)),
                        ]),
                      ),
                      Icon(Icons.chevron_right_rounded, color: context.subtle),
                    ]),
                  ),
                ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () => Get.to(() => PartnerDetailView(partnerId: p.id)),
                icon: const Icon(Icons.storefront_rounded),
                label: const Text('Voir la fiche complète'),
              ),
              const SizedBox(height: 30),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _offerIcon() => Container(width: 58, height: 58, color: GPTheme.clubColor.withValues(alpha: 0.3), child: const Icon(Icons.card_giftcard_rounded, color: Colors.black87));
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Stat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: context.subtle.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Icon(icon, size: 18, color: GPTheme.primaryColor),
            const SizedBox(height: 3),
            Text(value, style: TextStyle(color: context.primary, fontWeight: FontWeight.w900, fontSize: 14)),
            Text(label, style: TextStyle(color: context.subtle, fontSize: 10.5)),
          ]),
        ),
      );
}

class _SquareBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: context.subtle.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: context.primary),
        ),
      );
}
