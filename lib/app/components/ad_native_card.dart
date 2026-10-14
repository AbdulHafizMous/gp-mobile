// Carte sponsorisée « native » à glisser dans une liste / grille
// (chaînes, vidéos, jeux, titres…) : placement `native_feed`.
import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/services/ad_service.dart';

class AdNativeCard extends StatefulWidget {
  final String screen;
  final int? channelId;
  final EdgeInsetsGeometry margin;
  const AdNativeCard({super.key, required this.screen, this.channelId, this.margin = const EdgeInsets.symmetric(horizontal: 14, vertical: 8)});

  @override
  State<AdNativeCard> createState() => _AdNativeCardState();
}

class _AdNativeCardState extends State<AdNativeCard> {
  AdItem? _ad;

  @override
  void initState() {
    super.initState();
    AdService.fetch('native_feed', screen: widget.screen, channelId: widget.channelId, limit: 1).then((l) {
      if (l.isEmpty || !mounted) return;
      setState(() => _ad = l.first);
      AdService.track(l.first, screen: widget.screen, channelId: widget.channelId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: widget.margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
      ),
      child: InkWell(
        onTap: () => AdService.openCta(ad, screen: widget.screen, channelId: widget.channelId),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (ad.mediaUrl != null && ad.mediaType != 'video')
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(ad.mediaUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sponsorisé · ${ad.advertiserName}', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(ad.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              if (ad.body != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(ad.body!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600))),
              if (ad.ctaLabel != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(ad.ctaLabel!, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w800, fontSize: 13))),
            ]),
          ),
        ]),
      ),
    );
  }
}
