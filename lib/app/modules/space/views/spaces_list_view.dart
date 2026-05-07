// lib/app/modules/space/views/spaces_list_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/space_model.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get primaryText =>
      Theme.of(this).textTheme.bodyLarge?.color ??
      (isDark ? Colors.white : Colors.black87);
  Color get subtleText => Theme.of(this).hintColor;
  Color get cardColor => Theme.of(this).cardColor;
  Color get divColor => Theme.of(this).dividerColor;

  BoxDecoration get cardDecoration => BoxDecoration(
    color: isDark ? GPTheme.primaryColor.withValues(alpha: 0.05) : cardColor,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: isDark
          ? GPTheme.primaryColor.withValues(alpha: 0.45)
          : Colors.transparent,
      width: isDark ? 1.5 : 0,
    ),
    boxShadow: isDark
        ? null
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SPACES LIST VIEW
// ─────────────────────────────────────────────────────────────────────────────
class SpacesListView extends StatefulWidget {
  const SpacesListView({super.key});

  @override
  State<SpacesListView> createState() => _SpacesListViewState();
}

class _SpacesListViewState extends State<SpacesListView> {
  List<SpaceModel> _spaces = [];
  bool _loading = true;
  String? _error;

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
        await Future.delayed(const Duration(milliseconds: 500));
        // Mock : un espace avec catégories (sans médias — chargés dans SpaceController)
        _spaces = [
          SpaceModel(
            id: 1,
            title: 'Grand Public Bénin',
            description: 'Le meilleur des contenus vidéo du Bénin.',
            logoUrl:
                'http://192.168.100.19:8000/storage/spaces/LOjChoOVIMVa1xzPiWmObIsuqnyH4Fh551hBXFzE.jpg',
            isActive: true,
            categories: [
              SpaceCategory(
                id: 1,
                title: 'Portrait',
                description: 'Portraits inspirants',
              ),
              SpaceCategory(
                id: 2,
                title: 'Event',
                description: 'Les grands événements',
              ),
              SpaceCategory(
                id: 3,
                title: 'Music',
                description: 'Clips et concerts',
              ),
            ],
          ),
        ];
      } else {
        // GET /spaces → data.spaces[]  (chaque space a ses categories, sans médias)
        final r = await RequestService().get('/spaces');
        final list = (r.data['data']['spaces'] as List<dynamic>? ?? [])
            .map((j) => SpaceModel.fromJson(j as Map<String, dynamic>))
            .toList();
        _spaces = list;
      }
    } catch (e) {
      debugPrint('SpacesListView._load error: $e');
      _error = 'Impossible de charger les espaces.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _ShimmerList();

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
              icon: Icon(Icons.refresh_rounded, color: GPTheme.primaryColor),
              label: Text(
                'Réessayer',
                style: TextStyle(color: GPTheme.primaryColor),
              ),
            ),
          ],
        ),
      );
    }

    if (_spaces.isEmpty) {
      return Center(
        child: Text(
          'Aucun espace disponible',
          style: TextStyle(color: context.subtleText, fontSize: 15),
        ),
      );
    }

    return RefreshIndicator(
      color: GPTheme.primaryColor,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _spaces.length,
        itemBuilder: (_, i) => _SpaceCard(space: _spaces[i], index: i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPACE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SpaceCard extends StatefulWidget {
  final SpaceModel space;
  final int index;
  const _SpaceCard({required this.space, required this.index});

  @override
  State<_SpaceCard> createState() => _SpaceCardState();
}

class _SpaceCardState extends State<_SpaceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  bool _expanded = false;

  static const List<List<Color>> _accents = [
    [Color(0xFF6C63FF), Color(0xFF3B1FA8)],
    [Color(0xFFFF6B6B), Color(0xFF8B0000)],
    [Color(0xFF00C9A7), Color(0xFF006B5A)],
    [Color(0xFFFFB347), Color(0xFF8B4500)],
    [Color(0xFF56CCF2), Color(0xFF1A5276)],
  ];

  List<Color> get _accent => _accents[widget.index % _accents.length];

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    Future.delayed(Duration(milliseconds: widget.index * 90), () {
      if (mounted) _entry.forward();
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  /// Navigation vers la vue du space en passant l'ID et l'index de catégorie
  void _enterSpace({int categoryIndex = 0}) {
    Get.toNamed(
      '/home/spaces/${widget.space.id}',
      parameters: {'categoryIndex': '$categoryIndex'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entry,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: context.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(
                space: widget.space,
                accent: _accent,
                expanded: _expanded,
                onEnter: () => _enterSpace(),
                onToggle: () => setState(() => _expanded = !_expanded),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                child: _expanded
                    ? _CategoryGrid(
                        categories: widget.space.categories,
                        accent: _accent[0],
                        onTap: (catIdx) => _enterSpace(categoryIndex: catIdx),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _CardHeader extends StatelessWidget {
  final SpaceModel space;
  final List<Color> accent;
  final bool expanded;
  final VoidCallback onEnter;
  final VoidCallback onToggle;

  const _CardHeader({
    required this.space,
    required this.accent,
    required this.expanded,
    required this.onEnter,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onEnter,
            child: Row(
              children: [
                _SpaceLogo(space: space, accent: accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        space.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: context.primaryText,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        space.description,
                        style: TextStyle(
                          color: context.subtleText,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 0,
                child: _Badge(
                  label: '${space.categories.length} catégories',
                  icon: Icons.grid_view_rounded,
                  color: accent[0],
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: onEnter,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: GPTheme.primaryColor,
                  ),
                  child: const Text(
                    'Entrer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onToggle,
                child: AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 280),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GPTheme.primaryColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: GPTheme.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: GPTheme.primaryColor,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpaceLogo extends StatelessWidget {
  final SpaceModel space;
  final List<Color> accent;
  const _SpaceLogo({required this.space, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (space.logoUrl != null) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
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

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: accent,
        ),
        boxShadow: [
          BoxShadow(
            color: accent[0].withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.dashboard_customize_outlined,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Badge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY GRID (expandable)
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryGrid extends StatelessWidget {
  final List<SpaceCategory> categories;
  final Color accent;
  final void Function(int catIndex) onTap;

  const _CategoryGrid({
    required this.categories,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: context.divColor, height: 1),
          const SizedBox(height: 12),
          Text(
            'CATÉGORIES',
            style: TextStyle(
              color: context.subtleText,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              categories.length,
              (i) => _CategoryChip(
                category: categories[i],
                accent: accent,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final SpaceCategory category;
  final Color accent;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _pressed
              ? widget.accent.withValues(alpha: 0.18)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.shade100),
          border: Border.all(
            color: _pressed
                ? widget.accent.withValues(alpha: 0.5)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade300),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.accent,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.category.title,
              style: TextStyle(
                color: context.primaryText,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER
// ─────────────────────────────────────────────────────────────────────────────
class _ShimmerList extends StatefulWidget {
  const _ShimmerList();

  @override
  State<_ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<_ShimmerList>
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
        final baseColor = isDark
            ? Colors.white.withValues(alpha: 0.05 + _anim.value * 0.05)
            : Colors.grey.withValues(alpha: 0.1 + _anim.value * 0.08);
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: List.generate(
            3,
            (i) => Container(
              height: 110,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: baseColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
