// Carrousel d'images d'un média « article » (façon photos TikTok) + visionneuse plein écran zoomable.
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ArticleCarousel extends StatefulWidget {
  final List<String> images;
  final bool active; // visible à l'écran (démarre / arrête le défilement)
  final bool autoplay;
  final VoidCallback? onFinished; // fin de la dernière image (passage au short suivant)
  final bool storyTaps; // tap gauche / droite = image précédente / suivante
  final bool segments; // barres de progression en haut (sinon points en bas)
  final BoxFit fit;
  const ArticleCarousel({
    super.key,
    required this.images,
    this.active = true,
    this.autoplay = false,
    this.onFinished,
    this.storyTaps = false,
    this.segments = false,
    this.fit = BoxFit.cover,
  });

  @override
  State<ArticleCarousel> createState() => _ArticleCarouselState();
}

class _ArticleCarouselState extends State<ArticleCarousel> {
  final _page = PageController();
  Timer? _t;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(covariant ArticleCarousel old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active || old.autoplay != widget.autoplay) {
      if (widget.active && !old.active && _i != 0 && _page.hasClients) _page.jumpToPage(0);
      _arm();
    }
  }

  void _arm() {
    _t?.cancel();
    if (widget.active && widget.autoplay && widget.images.isNotEmpty) {
      _t = Timer.periodic(const Duration(seconds: 4), (_) => _advance());
    }
  }

  void _advance() {
    if (!mounted || !_page.hasClients) return;
    if (_i < widget.images.length - 1) {
      _page.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else if (widget.onFinished != null) {
      widget.onFinished!();
    } else {
      _page.animateToPage(0, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    }
  }

  void _go(int d) {
    final n = (_i + d).clamp(0, widget.images.length - 1);
    if (n != _i && _page.hasClients) _page.animateToPage(n, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
    _arm(); // relance le minuteur après une navigation manuelle
  }

  @override
  void dispose() {
    _t?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgs = widget.images;
    if (imgs.isEmpty) return const ColoredBox(color: Colors.black);
    return Stack(fit: StackFit.expand, children: [
      PageView.builder(
        controller: _page,
        itemCount: imgs.length,
        onPageChanged: (i) => setState(() => _i = i),
        itemBuilder: (_, i) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            if (widget.storyTaps) {
              final w = context.size?.width ?? 1;
              d.localPosition.dx < w * 0.3 ? _go(-1) : _go(1);
            } else {
              Get.to(() => ArticleImageViewer(images: imgs, initial: i), transition: Transition.fadeIn);
            }
          },
          child: Stack(fit: StackFit.expand, children: [
            // fond flouté + image entière quand on ne « cover » pas (évite les bandes noires)
            if (widget.fit == BoxFit.contain) CachedNetworkImage(imageUrl: imgs[i], fit: BoxFit.cover, color: Colors.black54, colorBlendMode: BlendMode.darken),
            CachedNetworkImage(
              imageUrl: imgs[i],
              fit: widget.fit,
              placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
              errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 48)),
            ),
          ]),
        ),
      ),
      if (imgs.length > 1)
        widget.segments
            ? Positioned(
                left: 10,
                right: 10,
                top: MediaQuery.of(context).padding.top + 6,
                child: Row(children: [
                  for (var k = 0; k < imgs.length; k++)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(color: k <= _i ? Colors.white : Colors.white30, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                ]),
              )
            : Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var k = 0; k < imgs.length; k++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: k == _i ? 18 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(color: k == _i ? Colors.white : Colors.white54, borderRadius: BorderRadius.circular(4)),
                    ),
                ]),
              ),
      if (imgs.length > 1 && !widget.segments)
        Positioned(
          right: 12,
          bottom: 28,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
            child: Text('${_i + 1}/${imgs.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
    ]);
  }
}

/// Visionneuse plein écran : glisser entre les images, pincer pour zoomer.
class ArticleImageViewer extends StatefulWidget {
  final List<String> images;
  final int initial;
  const ArticleImageViewer({super.key, required this.images, this.initial = 0});
  @override
  State<ArticleImageViewer> createState() => _ArticleImageViewerState();
}

class _ArticleImageViewerState extends State<ArticleImageViewer> {
  late final PageController _c = PageController(initialPage: widget.initial);
  late int _i = widget.initial;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _c,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _i = i),
          itemBuilder: (_, i) => InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Center(child: CachedNetworkImage(imageUrl: widget.images[i], fit: BoxFit.contain)),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              IconButton(style: IconButton.styleFrom(backgroundColor: Colors.black45), icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: Get.back),
              const Spacer(),
              if (widget.images.length > 1) Text('${_i + 1} / ${widget.images.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
            ]),
          ),
        ),
      ]),
    );
  }
}
