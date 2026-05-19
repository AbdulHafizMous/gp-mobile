// lib/app/modules/space/views/space_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/videos/views/videos_view.dart';
import 'package:grand_public_v2/app/data/models/space_model.dart';
import 'package:grand_public_v2/app/modules/space/controllers/space_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:video_player/video_player.dart';

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
              // Switch layout
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
// PREVIEW VIDEO DIALOG (inchangé)
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
// HERO HEADER (inchangé)
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
// CATEGORY TAB BAR (inchangé)
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

      return RefreshIndicator(
        color: GPTheme.primaryColor,
        onRefresh: () => ctrl.reloadCategory(category.id),
        child: CustomScrollView(
          slivers: [
            // Description banner
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
              // ── VUE LISTE (1 colonne) ─────────────────────────────
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
              // ── VUE GRILLE (2 colonnes) ───────────────────────────
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
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

String _formatDate(String raw) {
  try {
    final dt = DateTime.parse(raw);
    const months = [
      '',
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
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

// ── Stat pill (vue, commentaires) ─────────────────────────────────────────────
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
// VIDEO CARD — VUE GRILLE (2 colonnes)
// ─────────────────────────────────────────────────────────────────────────────
class _VideoCardGrid extends StatelessWidget {
  final SpaceVideo video;
  final Color accent;
  const _VideoCardGrid({required this.video, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return GestureDetector(
      onTap: () => Get.to(() => VideosView(videoId: video.id)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: context.cardSurface,
          border: isDark
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                )
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    child: SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: 16,
                          height: 9,
                          child: Image.network(
                            video.thumbnail,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, p) {
                              if (p == null) return child;
                              return Container(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200,
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: accent,
                                      value: p.expectedTotalBytes != null
                                          ? p.cumulativeBytesLoaded /
                                                p.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(14),
                                ),
                                color: accent.withValues(alpha: 0.12),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 32,
                                  color: accent.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Play overlay
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

                  // Badges top
                  if (video.isLiveNow)
                    Positioned(top: 6, left: 6, child: _liveBadge()),
                  if (video.isPremium && !video.isLiveNow)
                    Positioned(top: 6, right: 6, child: _premiumBadge()),

                  // Cadenas + prix bas droite
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

                  // Vues bas gauche
                  if (video.views > 0)
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

            // ── Infos texte ─────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
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

                    // Description ellipsée
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

                    // Stats + date
                    Row(
                      children: [
                        if (video.views > 0) ...[
                          _StatPill(
                            icon: Icons.visibility_outlined,
                            label: _formatCount(video.views),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (video.commentsCount > 0) ...[
                          _StatPill(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: _formatCount(video.commentsCount),
                          ),
                        ],
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIDEO CARD — VUE LISTE (1 colonne)
// Thumbnail 16:9 à gauche, toutes les infos à droite
// ─────────────────────────────────────────────────────────────────────────────
class _VideoCardList extends StatelessWidget {
  final SpaceVideo video;
  final Color accent;
  const _VideoCardList({required this.video, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return GestureDetector(
      onTap: () => Get.to(() => VideosView(videoId: video.id)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: context.cardSurface,
          border: isDark
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                )
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
          children: [
            // ── Thumbnail 16:9 ────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: SizedBox(
                width: 130,
                height: 115,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video.thumbnail,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, p) {
                        if (p == null) return child;
                        return Container(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accent,
                                value: p.expectedTotalBytes != null
                                    ? p.cumulativeBytesLoaded /
                                          p.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: accent.withValues(alpha: 0.12),
                        child: Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            size: 28,
                            color: accent.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),

                    // Play
                    Center(
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),

                    // Badges
                    if (video.isLiveNow)
                      Positioned(top: 5, left: 5, child: _liveBadge()),
                    if (video.isPremium && !video.isLiveNow)
                      Positioned(top: 5, right: 5, child: _premiumBadge()),
                    if (!video.canRead)
                      Positioned(bottom: 5, right: 5, child: _lockBadge()),

                    // Vues
                    if (video.views > 0)
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
            ),

            // ── Infos droite ───────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Titre
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

                    // Description
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

                    // Stats bas
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date
                        if (video.publicationDate.isNotEmpty)
                          Text(
                            _formatDate(video.publicationDate),
                            style: TextStyle(
                              fontSize: 10,
                              color: context.subtleText,
                            ),
                          ),

                        const SizedBox(height: 4),

                        // Vues + commentaires + prix PPV
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (video.commentsCount > 0)
                              _StatPill(
                                icon: Icons.chat_bubble_outline_rounded,
                                label: _formatCount(video.commentsCount),
                              ),
                            if (video.likesCount > 0)
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
          ],
        ),
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
