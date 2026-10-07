// lib/app/modules/space/views/space_view.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/vinyl_disc.dart';
import 'package:grand_public_v2/app/data/models/space_model.dart';
import 'package:grand_public_v2/app/modules/space/controllers/space_controller.dart';
import 'package:grand_public_v2/app/modules/videos/views/videos_view.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get primaryText =>
      Theme.of(this).textTheme.bodyLarge?.color ??
      (isDark ? Colors.white : Colors.black87);
  Color get subtleText => Theme.of(this).hintColor;
  Color get cardSurface => isDark ? Colors.grey.shade800 : Colors.white;
}

// ─────────────────────────────────────────────────────────────────────────────
// SPACE VIEW
// ─────────────────────────────────────────────────────────────────────────────
class SpaceView extends GetView<SpaceController> {
  const SpaceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark ? null : GPTheme.primaryColor,
      body: Obx(() {
        if (controller.isLoading.value) return _ShimmerSkeleton();
        if (controller.space.value == null) return _buildNotFound(context);
        return _SpaceBody(
          space: controller.space.value!,
          initialCategoryIndex: controller.initialCategoryIndex,
        );
      }),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 56,
            color: context.subtleText,
          ),
          const SizedBox(height: 16),
          Text(
            'Espace introuvable',
            style: TextStyle(
              color: context.subtleText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: Get.back,
            icon: Icon(Icons.arrow_back_rounded, color: GPTheme.primaryColor),
            label: Text(
              'Retour',
              style: TextStyle(color: GPTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPACE BODY
// ─────────────────────────────────────────────────────────────────────────────
class _SpaceBody extends StatefulWidget {
  final SpaceModel space;
  final int initialCategoryIndex;
  const _SpaceBody({required this.space, this.initialCategoryIndex = 0});

  @override
  State<_SpaceBody> createState() => _SpaceBodyState();
}

class _SpaceBodyState extends State<_SpaceBody> with TickerProviderStateMixin {
  late final SpaceController _ctrl;
  late final TabController _tabController;
  late final AnimationController _headerAnim;

  static const List<List<Color>> _gradients = [
    [Color(0xFF6C63FF), Color(0xFF3B1FA8)],
    [Color(0xFFFF6B6B), Color(0xFF8B0000)],
    [Color(0xFF00C9A7), Color(0xFF006B5A)],
    [Color(0xFFFFB347), Color(0xFF8B4500)],
    [Color(0xFF56CCF2), Color(0xFF1A5276)],
  ];

  List<Color> get _gradient => _gradients[widget.space.id % _gradients.length];

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<SpaceController>();

    final catCount = widget.space.categories.length;
    final safeInit = catCount == 0
        ? 0
        : widget.initialCategoryIndex.clamp(0, catCount - 1);

    _tabController = TabController(
      length: catCount,
      vsync: this,
      initialIndex: safeInit,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _ctrl.onCategorySelected(_tabController.index);
      }
    });

    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = widget.space.categories;

    return Obx(() {
      final updatedSpace = _ctrl.space.value ?? widget.space;

      return NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            backgroundColor: context.isDark ? null : GPTheme.primaryColor,
            leading: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: Get.back,
            ),
            actions: [
              Obx(
                () => _LayoutToggleButton(
                  isSingleColumn: _ctrl.isSingleColumn.value,
                  onToggle: _ctrl.toggleLayout,
                ),
              ),
              if (updatedSpace.hasPreviewVideo) ...[
                IconButton(
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: const Icon(
                      Icons.play_circle_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  onPressed: () {
                    final video = updatedSpace.previewVideoUrl;
                    if (video == null) return;
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withValues(alpha: 0.85),
                      builder: (_) => _PreviewVideoDialog(videoUrl: video),
                    );
                  },
                ),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _SpaceHeroHeader(
                space: updatedSpace,
                gradient: _gradient,
                anim: _headerAnim,
              ),
            ),
            bottom: cats.isEmpty
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: _CategoryTabBar(
                      tabController: _tabController,
                      categories: updatedSpace.categories,
                      accentColor: _gradient[0],
                    ),
                  ),
          ),
        ],
        body: cats.isEmpty
            ? _EmptyCategoryBody()
            : TabBarView(
                controller: _tabController,
                children: updatedSpace.categories
                    .map(
                      (cat) => _CategoryContentView(
                        category: cat,
                        accentColor: _gradient[0],
                        ctrl: _ctrl,
                      ),
                    )
                    .toList(),
              ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LAYOUT TOGGLE BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _LayoutToggleButton extends StatelessWidget {
  final bool isSingleColumn;
  final VoidCallback onToggle;
  const _LayoutToggleButton({
    required this.isSingleColumn,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isSingleColumn ? 'Vue 2 colonnes' : 'Vue liste',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Container(
          key: ValueKey(isSingleColumn),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          child: Icon(
            isSingleColumn
                ? Icons.grid_view_rounded
                : Icons.view_agenda_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
      onPressed: onToggle,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREVIEW VIDEO DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _PreviewVideoDialog extends StatefulWidget {
  final String videoUrl;
  const _PreviewVideoDialog({required this.videoUrl});

  @override
  State<_PreviewVideoDialog> createState() => _PreviewVideoDialogState();
}

class _PreviewVideoDialogState extends State<_PreviewVideoDialog> {
  VideoPlayerController? _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _isReady = true);
        _controller!.play();
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null) return;
    _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _isReady
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_controller!),
                          GestureDetector(
                            onTap: _togglePlay,
                            child: AnimatedOpacity(
                              opacity: _controller!.value.isPlaying ? 0 : 1,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Center(child: CircularProgressIndicator()),
                    ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SpaceHeroHeader extends StatelessWidget {
  final SpaceModel space;
  final List<Color> gradient;
  final AnimationController anim;

  const _SpaceHeroHeader({
    required this.space,
    required this.gradient,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradient[0].withValues(alpha: 0.55),
            gradient[1].withValues(alpha: 0.4),
            GPTheme.primaryColor,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gradient[0].withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: AnimatedBuilder(
                animation: anim,
                builder: (_, child) => Opacity(
                  opacity: anim.value,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - anim.value)),
                    child: child,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _HeroLogo(space: space, gradient: gradient),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            space.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            space.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          _HeroBadge(
                            label: '${space.categories.length} catégories',
                            icon: Icons.grid_view_rounded,
                            color: gradient[0],
                          ),
                        ],
                      ),
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
}

class _HeroLogo extends StatelessWidget {
  final SpaceModel space;
  final List<Color> gradient;
  const _HeroLogo({required this.space, required this.gradient});

  @override
  Widget build(BuildContext context) {
    if (space.logoUrl != null) {
      return Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            space.logoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          ),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    width: 66,
    height: 66,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradient,
      ),
      boxShadow: [
        BoxShadow(
          color: gradient[0].withValues(alpha: 0.4),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: const Icon(
      Icons.dashboard_customize_outlined,
      color: Colors.white,
      size: 30,
    ),
  );
}

class _HeroBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _HeroBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.22),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY TAB BAR
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryTabBar extends StatelessWidget {
  final TabController tabController;
  final List<SpaceCategory> categories;
  final Color accentColor;

  const _CategoryTabBar({
    required this.tabController,
    required this.categories,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.isDark ? null : GPTheme.primaryColor,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: Colors.white,
        indicatorWeight: 2.5,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.45),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tabs: categories.map((cat) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                Text(cat.title),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY CONTENT VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryContentView extends StatelessWidget {
  final SpaceCategory category;
  final Color accentColor;
  final SpaceController ctrl;

  const _CategoryContentView({
    required this.category,
    required this.accentColor,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = ctrl.categoryLoading[category.id] ?? false;
      final isSingle = ctrl.isSingleColumn.value;

      final updatedCat =
          ctrl.space.value?.categories.firstWhere(
            (c) => c.id == category.id,
            orElse: () => category,
          ) ??
          category;

      if (isLoading && updatedCat.videos.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final hasDescription = updatedCat.description.trim().isNotEmpty;

      return RefreshIndicator(
        color: GPTheme.primaryColor,
        onRefresh: () => ctrl.reloadCategory(category.id),
        child: CustomScrollView(
          slivers: [
            // Description : affichée uniquement si elle existe
            if (hasDescription)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: context.cardSurface.withValues(alpha: 0.2),
                    border: Border.all(
                      color: context.isDark
                          ? GPTheme.primaryColor.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          updatedCat.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Section LIVE (uniquement si la catégorie a un live actif)
            if (updatedCat.live != null)
              SliverToBoxAdapter(
                child: _LiveCard(
                  key: ValueKey('live-${updatedCat.live!['id']}'),
                  live: Map<String, dynamic>.from(updatedCat.live as Map),
                  accent: accentColor,
                ),
              ),

            if (updatedCat.videos.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 48,
                        color: context.subtleText,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bientôt disponible',
                        style: TextStyle(
                          color: context.subtleText,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (isSingle)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _VideoCardList(
                        video: updatedCat.videos[i],
                        accent: accentColor,
                      ),
                    ),
                    childCount: updatedCat.videos.length,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _VideoCardGrid(
                      video: updatedCat.videos[i],
                      accent: accentColor,
                    ),
                    childCount: updatedCat.videos.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.72,
                    mainAxisExtent: 190,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIVE CARD — vidéo (HLS…) ou audio (mp3, aac, radio…)
// Badge EN DIRECT en haut à gauche, type de flux en haut à droite.
// Un seul bouton lecture/pause. Bouton plein écran en mode vidéo.
// "Réessayer" uniquement en cas d'erreur.
// ─────────────────────────────────────────────────────────────────────────────
class _LiveCard extends StatefulWidget {
  final Map<String, dynamic> live;
  final Color accent;
  const _LiveCard({super.key, required this.live, required this.accent});

  @override
  State<_LiveCard> createState() => _LiveCardState();
}

class _LiveCardState extends State<_LiveCard>
    with SingleTickerProviderStateMixin {
  // Clés possibles de l'URL du flux dans la map `live` (adapte si besoin)
  static const _streamKeys = [
    'stream_url',
    'hls_url',
    'playback_url',
    'audio_url',
    'video_url',
    'url',
    'stream',
    'source',
  ];

  VideoPlayerController? _c;
  bool _loading = false;
  bool _error = false;
  bool _playing = false;
  bool _inFullscreen = false;
  int _gen = 0; // protège contre les initialisations concurrentes

  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  Map<String, dynamic> get _live => widget.live;

  String get _url {
    for (final k in _streamKeys) {
      final v = _live[k]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  bool get _isRadio => _live['kind']?.toString() == 'radio';

  bool get _isAudio {
    final mt = _live['media_type']?.toString().toLowerCase();
    if (mt == 'audio') return true;
    if (mt == 'video') return false;
    if (_isRadio) return true;
    final path = (Uri.tryParse(_url)?.path ?? '').toLowerCase();
    return path.endsWith('.mp3') ||
        path.endsWith('.aac') ||
        path.endsWith('.ogg') ||
        path.endsWith('.m4a') ||
        path.endsWith('.opus');
  }

  String get _cover {
    for (final k in ['cover', 'cover_url', 'thumbnail', 'image', 'logo']) {
      final v = _live[k]?.toString() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  String get _title {
    final t = _live['title']?.toString().trim() ?? '';
    return t.isEmpty ? 'Direct' : t;
  }

  String get _description => (_live['description'] ?? '').toString().trim();

  String get _nowPlaying =>
      (_live['now_playing_title'] ?? '').toString().trim();

  // ── Lecture ────────────────────────────────────────────────────────────────
  Future<void> _start() async {
    final url = _url;
    if (url.isEmpty) {
      if (mounted) setState(() => _error = true);
      return;
    }

    final gen = ++_gen;
    await _releaseController();
    if (!mounted || gen != _gen) return;
    setState(() {
      _loading = true;
      _error = false;
    });

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
    );
    _c = controller;

    try {
      await controller.initialize();
      if (!mounted || gen != _gen) return;
      controller.addListener(_onTick);
      await controller.setVolume(1);
      await controller.play();
      if (!mounted || gen != _gen) return;
      setState(() {
        _loading = false;
        _playing = true;
      });
      _anim.repeat();
    } catch (_) {
      if (!mounted || gen != _gen) return;
      await _releaseController();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
        _playing = false;
      });
    }
  }

  void _onTick() {
    final c = _c;
    if (c == null || !mounted) return;
    final v = c.value;
    if (v.hasError) {
      _releaseController();
      setState(() {
        _error = true;
        _playing = false;
        _loading = false;
      });
      _anim.stop();
      return;
    }
    if (v.isPlaying != _playing) {
      setState(() => _playing = v.isPlaying);
      if (v.isPlaying) {
        _anim.repeat();
      } else {
        _anim.stop();
      }
    }
  }

  Future<void> _releaseController() async {
    final c = _c;
    _c = null;
    if (c == null) return;
    c.removeListener(_onTick);
    try {
      await c.dispose();
    } catch (_) {}
  }

  Future<void> _toggle() async {
    if (_loading) return;
    final c = _c;
    if (c == null || !c.value.isInitialized) {
      await _start();
      return;
    }
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
  }

  // ── Plein écran (vidéo uniquement) ─────────────────────────────────────────
  // Réutilise le même controller : pas de rechargement du flux, la lecture
  // continue de la carte vers le plein écran et inversement.
  Future<void> _openFullscreen() async {
    final c = _c;
    if (c == null || !c.value.isInitialized || _inFullscreen) return;
    _inFullscreen = true;

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (!mounted) {
      _inFullscreen = false;
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _LiveFullscreenPage(controller: c, title: _title),
      ),
    );

    // Retour : on restaure l'UI système et l'orientation portrait
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    _inFullscreen = false;
  }

  @override
  void dispose() {
    _gen++;
    final c = _c;
    _c = null;
    c?.removeListener(_onTick);
    c?.dispose();
    _anim.dispose();
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isAudio = _isAudio;
    final accent = widget.accent;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: context.isDark ? const Color(0xFF1B1722) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Scène + badges en coin ────────────────────────────────
            Stack(
              children: [
                isAudio ? _audioStage(accent) : _videoStage(accent),
                Positioned(top: 10, left: 10, child: _liveCornerBadge()),
                Positioned(top: 10, right: 10, child: _typeChip()),
              ],
            ),

            // ── Infos + contrôle ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.subtleText,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  if (_nowPlaying.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.music_note_rounded,
                            size: 16,
                            color: accent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _nowPlaying,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.primaryText.withValues(
                                  alpha: 0.75,
                                ),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isAudio) ...[
                    const SizedBox(height: 14),
                    _audioButton(accent),
                  ],
                  if (_error) ...[const SizedBox(height: 10), _errorRow()],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Badge EN DIRECT (coin haut-gauche)
  Widget _liveCornerBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.red.shade600,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(right: 5),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
        const Text(
          'EN DIRECT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );

  // Type de flux (coin haut-droit)
  Widget _typeChip() {
    final isAudio = _isAudio;
    final icon = _isRadio
        ? Icons.radio_rounded
        : (isAudio ? Icons.headphones_rounded : Icons.videocam_rounded);
    final label = _isRadio ? 'Radio' : (isAudio ? 'Audio' : 'Vidéo');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // Scène VIDÉO
  Widget _videoStage(Color accent) {
    final c = _c;
    final ready = c != null && c.value.isInitialized;
    final ratio = ready && c.value.aspectRatio > 0
        ? c.value.aspectRatio
        : 16 / 9;

    return AspectRatio(
      aspectRatio: ratio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          if (!ready && _cover.isNotEmpty)
            Opacity(
              opacity: 0.6,
              child: Image.network(
                _cover,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if (ready) VideoPlayer(c),
          // dégradé haut pour la lisibilité des badges
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Color(0x99000000), Colors.transparent],
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.6,
                      ),
                    )
                  : AnimatedOpacity(
                      opacity: _playing ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
            ),
          ),
          // Bouton plein écran (coin bas-droit, au-dessus du GestureDetector)
          if (ready)
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: _openFullscreen,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Scène AUDIO : vinyle + ondes + équaliseur (inspiré de Blowmusic)
  Widget _audioStage(Color accent) {
    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(accent, Colors.black, 0.45)!,
            const Color(0xFF0B0810),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Builder(
                builder: (_) {
                  final t = _playing ? ((_anim.value + i / 3) % 1.0) : 0.0;
                  return Opacity(
                    opacity: _playing ? (1 - t) * 0.35 : 0.12,
                    child: Container(
                      width: 110 + t * 90,
                      height: 110 + t * 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: accent, width: 2),
                      ),
                    ),
                  );
                },
              ),
            VinylDisc(
              size: 120,
              playing: _playing,
              accent: accent,
              coverUrl: _cover.isNotEmpty ? _cover : null,
              fallbackIcon: _isRadio
                  ? Icons.radio_rounded
                  : Icons.graphic_eq_rounded,
            ),
            Positioned(
              bottom: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 14; i++)
                    Container(
                      width: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: _playing
                          ? 6 +
                                22 *
                                    (0.5 +
                                            0.5 *
                                                math.sin(
                                                  _anim.value * 6.283 * 2 +
                                                      i * 0.9,
                                                ))
                                        .abs()
                          : 6,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _audioButton(Color accent) {
    final label = _loading
        ? 'Connexion…'
        : (_playing ? 'Pause' : 'Écouter le direct');
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: LinearGradient(
            colors: [accent, Color.lerp(accent, const Color(0xFF7C3AED), .55)!],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _loading ? null : _toggle,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          icon: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                )
              : Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorRow() => Row(
    children: [
      Icon(Icons.error_outline_rounded, size: 16, color: Colors.red.shade400),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          'Impossible de lire ce flux pour le moment.',
          style: TextStyle(color: Colors.red.shade400, fontSize: 12.5),
        ),
      ),
      TextButton(
        onPressed: _start,
        child: Text(
          'Réessayer',
          style: TextStyle(color: widget.accent, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// LIVE FULLSCREEN — réutilise le controller de la carte (pas de rechargement)
// ─────────────────────────────────────────────────────────────────────────────
class _LiveFullscreenPage extends StatefulWidget {
  final VideoPlayerController controller;
  final String title;
  const _LiveFullscreenPage({required this.controller, required this.title});

  @override
  State<_LiveFullscreenPage> createState() => _LiveFullscreenPageState();
}

class _LiveFullscreenPageState extends State<_LiveFullscreenPage> {
  bool _showControls = true;

  VideoPlayerController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onUpdate);
    _autoHide();
  }

  @override
  void dispose() {
    _c.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    // Si le flux est tombé (la carte libère le controller), on ferme
    if (_c.value.hasError) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {});
  }

  void _autoHide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _c.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _autoHide();
  }

  void _togglePlay() {
    _c.value.isPlaying ? _c.pause() : _c.play();
    _autoHide();
  }

  @override
  Widget build(BuildContext context) {
    final v = _c.value;
    final ratio = v.isInitialized && v.aspectRatio > 0 ? v.aspectRatio : 16 / 9;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(aspectRatio: ratio, child: VideoPlayer(_c)),
            ),
            AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xAA000000),
                            Colors.transparent,
                            Colors.transparent,
                            Color(0xAA000000),
                          ],
                          stops: [0, 0.3, 0.7, 1],
                        ),
                      ),
                    ),
                    // Titre + EN DIRECT
                    Positioned(
                      top: 16,
                      left: 20,
                      right: 70,
                      child: SafeArea(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'EN DIRECT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Quitter le plein écran
                    Positioned(
                      top: 12,
                      right: 16,
                      child: SafeArea(
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fullscreen_exit_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Play / pause
                    Center(
                      child: GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.55),
                          ),
                          child: Icon(
                            v.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (v.isBuffering)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

String _formatDate(String raw) {
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

String _formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
  return '$n';
}

// ── Badges inline ─────────────────────────────────────────────────────────────

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

Widget _lockBadge() => Container(
  padding: const EdgeInsets.all(4),
  decoration: BoxDecoration(
    color: Colors.black.withValues(alpha: 0.65),
    shape: BoxShape.circle,
  ),
  child: const Icon(Icons.lock_rounded, color: Colors.white70, size: 12),
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
// INLINE PREVIEW — appui long : preview avec son. Double-tap : like.
// Tap simple : ouvre le détail.
// ─────────────────────────────────────────────────────────────────────────────
class _ThumbnailInteractive extends StatefulWidget {
  final SpaceVideo video;
  final Color accent;
  final BorderRadius borderRadius;
  final List<Widget> overlayBadges;

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
        await controller.setVolume(1);
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
      // Best-effort
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
                child: YoutubePlayer(
                  controller: _ytCtrl!,
                  showVideoProgressIndicator: false,
                  topActions: const [],
                  bottomActions: const [],
                  aspectRatio: 16 / 9,
                ),
              ),

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

            ...widget.overlayBadges,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIDEO CARD — VUE GRILLE (2 colonnes)
// ─────────────────────────────────────────────────────────────────────────────
class _VideoCardGrid extends StatelessWidget {
  final SpaceVideo video;
  final Color accent;
  const _VideoCardGrid({required this.video, required this.accent});

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
                          _formatCount(video.views),
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
              ],
            ),
          ),
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
                  Row(
                    children: [
                      _StatPill(
                        icon: Icons.visibility_outlined,
                        label: _formatCount(video.views),
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: _formatCount(video.commentsCount),
                      ),
                      const Spacer(),
                      if (video.publicationDate.isNotEmpty)
                        Text(
                          _formatDate(video.publicationDate),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// VIDEO CARD — VUE LISTE (1 colonne)
// ─────────────────────────────────────────────────────────────────────────────
class _VideoCardList extends StatelessWidget {
  final SpaceVideo video;
  final Color accent;
  const _VideoCardList({required this.video, required this.accent});

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
                if (!video.canRead)
                  Positioned(bottom: 5, right: 5, child: _lockBadge()),
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
                          _formatCount(video.views),
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
              ],
            ),
          ),
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
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.subtleText,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (video.publicationDate.isNotEmpty)
                          Text(
                            _formatDate(video.publicationDate),
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
                              label: _formatCount(video.commentsCount),
                            ),
                            _StatPill(
                              icon: Icons.thumb_up_outlined,
                              label: _formatCount(video.likesCount),
                              color: GPTheme.primaryColor,
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
                                    color: GPTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${video.ppvPrice!.toStringAsFixed(0)} XOF',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: GPTheme.primaryColor,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY + SHIMMER
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyCategoryBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      'Aucune catégorie',
      style: TextStyle(color: context.subtleText, fontSize: 16),
    ),
  );
}

class _ShimmerSkeleton extends StatefulWidget {
  @override
  State<_ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<_ShimmerSkeleton>
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
        final shimmerColor = isDark
            ? Colors.white.withValues(alpha: o)
            : Colors.grey.withValues(alpha: o);
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 230,
              pinned: true,
              backgroundColor: GPTheme.primaryColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: Get.back,
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(color: shimmerColor),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Container(
                    height: 90,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: shimmerColor,
                    ),
                  ),
                  childCount: 4,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
