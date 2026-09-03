// lib/app/modules/pages/favorites_page.dart
//
// Page des vidéos sauvegardées (favoris)
// • Layout et interactions alignés sur SpaceView (grille 2 col / liste 1 col)
// • Thumbnail interactif : appui long = preview vidéo avec son, double-tap =
//   like animé, tap simple = ouvre le détail (voir _ThumbnailInteractive)
// • Le badge bookmark (toujours affiché ici) a son propre tap pour retirer
//   des favoris, puisque l'appui long est désormais pris par la preview.
// • Appelle GET /api/videos/saved
// • Tap → VideosView(videoId: video.id)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/space_model.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/videos/views/videos_view.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS (même pattern que le reste de l'app)
// ─────────────────────────────────────────────────────────────────────────────
extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get primaryText =>
      Theme.of(this).textTheme.bodyLarge?.color ??
      (isDark ? Colors.white : Colors.black87);
  Color get subtleText => Theme.of(this).hintColor;
  Color get cardSurface => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get separator =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEAEAEA);
}

// ─────────────────────────────────────────────────────────────────────────────
// FAVORITES PAGE
// ─────────────────────────────────────────────────────────────────────────────
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<SpaceVideo> _videos = [];
  bool _loading = true;
  String? _error;
  bool _isSingleColumn = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 600));
        _videos = _mockFavorites();
      } else {
        final r = await RequestService().get('/videos/saved');
        final list = r.data['data']['medias'] as List<dynamic>? ?? [];
        _videos = list
            .map((e) => SpaceVideo.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('FavoritesPage._load error: $e');
      _error = 'Impossible de charger vos favoris.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Retire une vidéo des favoris localement après unsave
  void _removeVideo(int videoId) {
    setState(() => _videos.removeWhere((v) => v.id == videoId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark ? null : Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF111111) : Colors.white,
        border: Border(bottom: BorderSide(color: context.separator, width: 1)),
      ),
      child: Row(
        children: [
          // Titre + compteur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes favoris',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: context.primaryText,
                    letterSpacing: -0.4,
                  ),
                ),
                if (!_loading)
                  Text(
                    '${_videos.length} vidéo${_videos.length > 1 ? 's' : ''} sauvegardée${_videos.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.subtleText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Switch layout
          if (!_loading && _videos.isNotEmpty)
            IconButton(
              tooltip: _isSingleColumn ? 'Vue grille' : 'Vue liste',
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  key: ValueKey(_isSingleColumn),
                  _isSingleColumn
                      ? Icons.grid_view_rounded
                      : Icons.view_agenda_rounded,
                  color: context.primaryText,
                  size: 22,
                ),
              ),
              onPressed: () =>
                  setState(() => _isSingleColumn = !_isSingleColumn),
            ),
        ],
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context) {
    if (_loading) return _Shimmer(isSingle: _isSingleColumn);

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: context.subtleText),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: context.subtleText, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _load,
              icon: Icon(Icons.refresh_rounded, color: context.primaryText),
              label: Text(
                'Réessayer',
                style: TextStyle(color: context.primaryText),
              ),
            ),
          ],
        ),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_outline_rounded,
              size: 56,
              color: context.subtleText,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune vidéo sauvegardée',
              style: TextStyle(
                color: context.subtleText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sauvegardez des vidéos pour les retrouver ici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.subtleText, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: context.primaryText,
      onRefresh: _load,
      child: _isSingleColumn
          ? _buildListView(context)
          : _buildGridView(context),
    );
  }

  Widget _buildGridView(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
        mainAxisExtent: 190,
      ),
      itemCount: _videos.length,
      itemBuilder: (_, i) => _VideoCardGrid(
        video: _videos[i],
        accent: context.primaryText,
        onUnsaved: () => _removeVideo(_videos[i].id),
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: _videos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _VideoCardList(
        video: _videos[i],
        accent: context.primaryText,
        onUnsaved: () => _removeVideo(_videos[i].id),
      ),
    );
  }

  // ── Mock ─────────────────────────────────────────────────────────────────
  List<SpaceVideo> _mockFavorites() {
    return [
      SpaceVideo(
        id: 1,
        title: 'WELOVeya Dadju & Gims — Edition 2024',
        description: 'Un concert mémorable à Cotonou.',
        thumbnail: 'https://img.youtube.com/vi/3shs6DYjXtY/hqdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=3shs6DYjXtY',
        youtubeId: '3shs6DYjXtY',
        views: 213000,
        likesCount: 12800,
        commentsCount: 19,
        publicationDate: '2026-04-20 10:00:00',
        isPremium: true,
        ppvPrice: 500,
        canRead: true,
        isSaved: true,
        spaceName: 'Grand Public Bénin',
        categoryName: 'Event',
      ),
      SpaceVideo(
        id: 2,
        title: 'Portrait inspirant — Série documentaire',
        description: 'Une histoire touchante et pleine d\'inspiration.',
        thumbnail: 'https://img.youtube.com/vi/eNG_hpiDYbA/hqdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=eNG_hpiDYbA',
        youtubeId: 'eNG_hpiDYbA',
        views: 45000,
        likesCount: 3200,
        commentsCount: 7,
        publicationDate: '2026-04-15 08:00:00',
        isPremium: false,
        canRead: true,
        isSaved: true,
        spaceName: 'Grand Public Bénin',
        categoryName: 'Portrait',
      ),
      SpaceVideo(
        id: 3,
        title: 'Intro à la migration – Épisode 1',
        description: 'Tout ce qu\'il faut savoir sur la migration.',
        thumbnail: 'https://img.youtube.com/vi/tvYSnXC6CfY/hqdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=tvYSnXC6CfY',
        youtubeId: 'tvYSnXC6CfY',
        views: 8000,
        likesCount: 420,
        commentsCount: 3,
        publicationDate: '2026-04-10 12:00:00',
        isPremium: true,
        ppvPrice: 500,
        canRead: false,
        isSaved: true,
        spaceName: 'Grand Public Bénin',
        categoryName: 'Portrait',
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS (copie de space_view.dart pour éviter les imports croisés)
// ─────────────────────────────────────────────────────────────────────────────

String _fmtDate(String raw) {
  try {
    final dt = DateTime.parse(raw);
    const months = [
      '',
      'Jan.',
      'Fév.',
      'Mar.',
      'Avr.',
      'Mai.',
      'Juin.',
      'Juil.',
      'Aoû.',
      'Sep.',
      'Oct.',
      'Nov.',
      'Déc.',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month]} ${dt.year}';
  } catch (_) {
    return raw;
  }
}

String _fmtCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
  return '$n';
}

Widget _liveBadge() => Container(
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decoration: BoxDecoration(
    color: Colors.red.shade600,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.only(right: 4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      ),
      const Text(
        'LIVE',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    ],
  ),
);

Widget _premiumBadge() => Container(
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decoration: BoxDecoration(
    color: Colors.amber.shade600,
    borderRadius: BorderRadius.circular(8),
  ),
  child: const Text(
    'PREMIUM',
    style: TextStyle(
      fontSize: 8,
      fontWeight: FontWeight.w900,
      color: Colors.white,
    ),
  ),
);

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _StatPill({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.subtleText;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: c),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THUMBNAIL INTERACTIF — copie de space_view.dart (mêmes gestes) :
// appui long = preview vidéo avec son, sans contrôles, dans le cadre de la
// miniature (relâcher revient à l'image fixe). Double-tap = like animé.
// Tap simple = ouvre le détail.
// ─────────────────────────────────────────────────────────────────────────────
class _ThumbnailInteractive extends StatefulWidget {
  final SpaceVideo video;
  final Color accent;
  final BorderRadius borderRadius;
  final List<Widget> overlayBadges; // badges positionnés par l'appelant

  const _ThumbnailInteractive({
    required this.video,
    required this.accent,
    required this.borderRadius,
    this.overlayBadges = const [],
  });

  @override
  State<_ThumbnailInteractive> createState() => _ThumbnailInteractiveState();
}

class _ThumbnailInteractiveState extends State<_ThumbnailInteractive>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _nativeCtrl;
  YoutubePlayerController? _ytCtrl;
  bool _isPreviewing = false;
  bool _isPreviewLoading = false;

  bool _showHeart = false;
  late final AnimationController _heartAnim;

  bool get _canPreview =>
      widget.video.canRead &&
      ((widget.video.sourceType == 'upload' &&
              (widget.video.videoFileUrl?.isNotEmpty ?? false)) ||
          (widget.video.sourceType != 'upload' &&
              _extractYoutubeId().isNotEmpty));

  @override
  void initState() {
    super.initState();
    _heartAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  String _extractYoutubeId() {
    final raw = widget.video.youtubeId.isNotEmpty
        ? widget.video.youtubeId
        : widget.video.videoUrl;
    final id = YoutubePlayer.convertUrlToId(raw);
    if (id != null && id.isNotEmpty) return id;
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(raw)) return raw;
    return '';
  }

  Future<void> _startPreview() async {
    if (!_canPreview || _isPreviewing) return;
    setState(() {
      _isPreviewing = true;
      _isPreviewLoading = true;
    });

    if (widget.video.sourceType == 'upload') {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoFileUrl!),
      );
      _nativeCtrl = controller;
      try {
        await controller.initialize();
        if (!mounted || !_isPreviewing) return;
        await controller.setVolume(1); // son activé, comme demandé
        await controller.play();
        setState(() => _isPreviewLoading = false);
      } catch (_) {
        if (mounted) _stopPreview();
      }
    } else {
      final ytId = _extractYoutubeId();
      _ytCtrl = YoutubePlayerController(
        initialVideoId: ytId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          hideControls: true,
          hideThumbnail: true,
          disableDragSeek: true,
          controlsVisibleAtStart: false,
          enableCaption: false,
        ),
      );
      setState(() => _isPreviewLoading = false);
    }
  }

  void _stopPreview() {
    if (!_isPreviewing) return;
    _nativeCtrl?.pause();
    _nativeCtrl?.dispose();
    _nativeCtrl = null;
    _ytCtrl?.pause();
    _ytCtrl?.dispose();
    _ytCtrl = null;
    if (mounted) {
      setState(() {
        _isPreviewing = false;
        _isPreviewLoading = false;
      });
    }
  }

  Future<void> _handleDoubleTap() async {
    setState(() => _showHeart = true);
    _heartAnim.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) setState(() => _showHeart = false);
    });

    try {
      await RequestService().post('/videos/${widget.video.id}/like');
    } catch (_) {
      // Best-effort : le like sera de toute façon reflété au prochain
      // chargement de la page depuis le backend.
    }
  }

  @override
  void dispose() {
    _nativeCtrl?.dispose();
    _ytCtrl?.dispose();
    _heartAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return GestureDetector(
      onTap: () => Get.to(() => VideosView(videoId: widget.video.id)),
      onDoubleTap: _handleDoubleTap,
      onLongPressStart: (_) => _startPreview(),
      onLongPressEnd: (_) => _stopPreview(),
      onLongPressCancel: _stopPreview,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Image fixe (toujours en fond, sous la preview) ──────────
            Image.network(
              widget.video.thumbnail,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, p) {
                if (p == null) return child;
                return Container(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.accent,
                        value: p.expectedTotalBytes != null
                            ? p.cumulativeBytesLoaded / p.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: widget.accent.withValues(alpha: 0.12),
                child: Center(
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    size: 32,
                    color: widget.accent.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),

            // ── Preview vidéo par-dessus, uniquement en appui long ──────
            if (_isPreviewing &&
                _nativeCtrl != null &&
                _nativeCtrl!.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _nativeCtrl!.value.size.width,
                  height: _nativeCtrl!.value.size.height,
                  child: VideoPlayer(_nativeCtrl!),
                ),
              ),
            if (_isPreviewing && _ytCtrl != null)
              IgnorePointer(
                // les gestes restent gérés par le GestureDetector parent
                child: YoutubePlayer(
                  controller: _ytCtrl!,
                  showVideoProgressIndicator: false,
                  topActions: const [],
                  bottomActions: const [],
                  aspectRatio: 16 / 9,
                ),
              ),

            // ── Spinner pendant le chargement de la preview ─────────────
            if (_isPreviewing && _isPreviewLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  ),
                ),
              ),

            // ── Bouton play (masqué pendant la preview) ─────────────────
            if (!_isPreviewing)
              Center(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

            // ── Cœur d'animation double-tap ──────────────────────────────
            if (_showHeart)
              Center(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.6, end: 1.3).animate(
                    CurvedAnimation(
                      parent: _heartAnim,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 1, end: 0).animate(
                      CurvedAnimation(
                        parent: _heartAnim,
                        curve: const Interval(0.6, 1.0),
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 56,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 12)],
                    ),
                  ),
                ),
              ),

            // Badges fournis par l'appelant (LIVE, PREMIUM, vues, bookmark…)
            ...widget.overlayBadges,
          ],
        ),
      ),
    );
  }
}

// ── Badge bookmark tapable (retire des favoris) ──────────────────────────────
// L'appui long du thumbnail étant pris par la preview, le retrait des
// favoris se fait désormais via un tap direct sur ce badge.
Widget _bookmarkBadge({
  required BuildContext context,
  required VoidCallback onTap,
  double size = 11,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.primaryText.withValues(alpha: 0.85),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.bookmark_rounded, color: Colors.white, size: size),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// VIDEO CARD — VUE GRILLE (2 colonnes)
// ─────────────────────────────────────────────────────────────────────────────
class _VideoCardGrid extends StatelessWidget {
  final SpaceVideo video;
  final Color accent;
  final VoidCallback onUnsaved;

  const _VideoCardGrid({
    required this.video,
    required this.accent,
    required this.onUnsaved,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: context.cardSurface,
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1)
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail ───────────────────────────────────────────
          Expanded(
            flex: 5,
            child: _ThumbnailInteractive(
              video: video,
              accent: accent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              overlayBadges: [
                if (video.isLiveNow)
                  Positioned(top: 6, left: 6, child: _liveBadge()),
                if (video.isPremium && !video.isLiveNow)
                  Positioned(top: 6, right: 6, child: _premiumBadge()),

                if (!video.canRead)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_rounded,
                            color: Colors.white70,
                            size: 10,
                          ),
                          if (video.ppvPrice != null) ...[
                            const SizedBox(width: 3),
                            Text(
                              '${video.ppvPrice!.toStringAsFixed(0)} XOF',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          size: 10,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _fmtCount(video.views),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bookmark — tap direct pour retirer des favoris
                Positioned(
                  top: 6,
                  left: video.isLiveNow ? 60 : 6,
                  child: _bookmarkBadge(
                    context: context,
                    onTap: () => _showUnsaveDialog(context),
                  ),
                ),
              ],
            ),
          ),

          // ── Infos texte ─────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: context.primaryText,
                      height: 1.3,
                    ),
                  ),
                  if (video.description != null &&
                      video.description!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      video.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: context.subtleText,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Stats + date — toujours affichées, même à 0 (comme SpaceView)
                  Row(
                    children: [
                      _StatPill(
                        icon: Icons.visibility_outlined,
                        label: _fmtCount(video.views),
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: _fmtCount(video.commentsCount),
                      ),
                      const Spacer(),
                      if (video.publicationDate.isNotEmpty)
                        Text(
                          _fmtDate(video.publicationDate),
                          style: TextStyle(
                            fontSize: 9,
                            color: context.subtleText,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnsaveDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: BoxDecoration(
          color: context.cardSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.separator,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: context.primaryText,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: BorderSide(color: Colors.red.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                onUnsaved();
              },
              icon: Icon(
                Icons.bookmark_remove_rounded,
                color: Colors.red.shade400,
              ),
              label: Text(
                'Retirer des favoris',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryText,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Get.to(() => VideosView(videoId: video.id));
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'Regarder',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIDEO CARD — VUE LISTE (1 colonne)
// ─────────────────────────────────────────────────────────────────────────────
class _VideoCardList extends StatelessWidget {
  final SpaceVideo video;
  final Color accent;
  final VoidCallback onUnsaved;

  const _VideoCardList({
    required this.video,
    required this.accent,
    required this.onUnsaved,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: context.cardSurface,
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1)
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail 16:9 ────────────────────────────────────
          SizedBox(
            width: 130,
            height: 115,
            child: _ThumbnailInteractive(
              video: video,
              accent: accent,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              overlayBadges: [
                if (video.isLiveNow)
                  Positioned(top: 5, left: 5, child: _liveBadge()),
                if (video.isPremium && !video.isLiveNow)
                  Positioned(top: 5, right: 5, child: _premiumBadge()),
                Positioned(
                  bottom: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          size: 9,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _fmtCount(video.views),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bookmark — tap direct pour retirer des favoris
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: _bookmarkBadge(
                    context: context,
                    onTap: () => _showUnsaveSheet(context),
                    size: 10,
                  ),
                ),
              ],
            ),
          ),

          // ── Infos droite ───────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: () => Get.to(() => VideosView(videoId: video.id)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.primaryText,
                        height: 1.3,
                      ),
                    ),
                    if (video.description != null &&
                        video.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        video.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.subtleText,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),

                    // Tags (espace / catégorie)
                    if ((video.spaceName ?? '').isNotEmpty ||
                        (video.categoryName ?? '').isNotEmpty)
                      Wrap(
                        spacing: 5,
                        children: [
                          if ((video.spaceName ?? '').isNotEmpty)
                            _MiniTag(
                              label: video.spaceName!,
                              color: context.primaryText,
                            ),
                          if ((video.categoryName ?? '').isNotEmpty)
                            _MiniTag(
                              label: video.categoryName!,
                              color: context.subtleText,
                            ),
                        ],
                      ),

                    const SizedBox(height: 4),

                    // Stats — toujours affichées, même à 0 (comme SpaceView)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (video.publicationDate.isNotEmpty)
                          Text(
                            _fmtDate(video.publicationDate),
                            style: TextStyle(
                              fontSize: 10,
                              color: context.subtleText,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _StatPill(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: _fmtCount(video.commentsCount),
                            ),
                            _StatPill(
                              icon: Icons.thumb_up_outlined,
                              label: _fmtCount(video.likesCount),
                              color: context.primaryText,
                            ),
                            if (video.isPremium &&
                                !video.canRead &&
                                video.ppvPrice != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 10,
                                    color: context.primaryText,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${video.ppvPrice!.toStringAsFixed(0)} XOF',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: context.primaryText,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnsaveSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: BoxDecoration(
          color: context.cardSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.separator,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: context.primaryText,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: BorderSide(color: Colors.red.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                onUnsaved();
              },
              icon: Icon(
                Icons.bookmark_remove_rounded,
                color: Colors.red.shade400,
              ),
              label: Text(
                'Retirer des favoris',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryText,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Get.to(() => VideosView(videoId: video.id));
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'Regarder',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mini tag pour la vue liste
class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER
// ─────────────────────────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final bool isSingle;
  const _Shimmer({required this.isSingle});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final o = isDark ? 0.05 + _anim.value * 0.06 : 0.1 + _anim.value * 0.08;
        final color = isDark
            ? Colors.white.withValues(alpha: o)
            : Colors.grey.withValues(alpha: o);

        if (widget.isSingle) {
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, __) => Container(
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: color,
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.72,
            mainAxisExtent: 190,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: color,
            ),
          ),
        );
      },
    );
  }
}
