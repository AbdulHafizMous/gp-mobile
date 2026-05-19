// lib/app/modules/main_page/views/main_page_view.dart
//
// Changements vs version précédente :
//   • _navigateToHomeSection() : centralise la navigation vers /home
//   • _SimpleContent  : bouton "Explorer" appelle _navigateToHomeSection
//   • _SpaceCardHeader: bouton "Entrer"   navigue vers la page d'un espace
//   • Aucun autre changement fonctionnel

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/models/space_model.dart';
import 'package:grand_public_v2/app/data/models/section_model.dart';
import 'package:grand_public_v2/app/modules/main_page/controllers/main_page_controller.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const double _kItemWidth = 90.0;
const double _kBeltHeight = 130.0;
const int _kLoopMultiplier = 100;

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  // Color get primaryText =>
  //     Theme.of(this).textTheme.bodyLarge?.color ??
  //     (isDark ? Colors.white : Colors.black87);
  // Color get subtleText => Theme.of(this).hintColor;
  // // Color get surfaceColor => isDark ? Colors.grey.shade900 : Colors.grey.shade50;
  // Color get cardSurface => isDark ? Colors.grey.shade800 : Colors.white;
  // Color get divColor => Theme.of(this).dividerColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// NAVIGATION HELPER
// Navigate to /home and land on the correct section tab.
// If HomeController is not yet registered (first visit), we store the target
// index in GetStorage so HomeView can read it on init.
// ─────────────────────────────────────────────────────────────────────────────
void _navigateToHomeSection(int sectionIndex) {
  // If the controller is already alive, set the index directly.
  if (Get.isRegistered<HomeController>()) {
    Get.find<HomeController>().goToSection(sectionIndex);
  } else {
    // Store pending section so HomeView reads it on first build.
    GetStorage().write('_pendingSection', sectionIndex);
  }
  Get.offAllNamed('/home');
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN PAGE VIEW
// ─────────────────────────────────────────────────────────────────────────────
class MainPageView extends StatefulWidget {
  const MainPageView({super.key});

  @override
  State<MainPageView> createState() => _MainPageViewState();
}

class _MainPageViewState extends State<MainPageView>
    with TickerProviderStateMixin {
  // ignore: unused_field
  late final MainPageController _ctrl;

  late final ScrollController _beltController;
  late final AnimationController _contentAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _tiltAnim;
  late final AnimationController _pulseAnim;

  int _activeIndex = 0;
  final int _virtualCount = sections.length * _kLoopMultiplier;
  late double _initialOffset;
  bool _beltScrolling = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<MainPageController>();

    _initialOffset = (sections.length * _kLoopMultiplier ~/ 2) * _kItemWidth;
    _beltController = ScrollController(initialScrollOffset: _initialOffset);
    _beltController.addListener(_onBeltScroll);

    _contentAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _buildContentAnimations(fromRight: true);
    _contentAnim.forward();

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  void _buildContentAnimations({required bool fromRight}) {
    final xStart = fromRight ? 0.18 : -0.18;
    _slideAnim = Tween<Offset>(begin: Offset(xStart, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _contentAnim, curve: Curves.easeOutCubic),
        );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnim,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _tiltAnim = Tween<double>(begin: fromRight ? 0.04 : -0.04, end: 0.0)
        .animate(
          CurvedAnimation(parent: _contentAnim, curve: Curves.easeOutCubic),
        );
  }

  void _changeIndex(int newIndex, {required bool fromRight}) {
    if (newIndex == _activeIndex) return;
    setState(() => _activeIndex = newIndex);
    _buildContentAnimations(fromRight: fromRight);
    _contentAnim.forward(from: 0);
  }

  void _onBeltScroll() {
    if (_beltScrolling) return;
    final offset = _beltController.offset;
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = offset + screenWidth / 2 - _kItemWidth / 2;
    final raw = (centerX / _kItemWidth).round() % sections.length;
    final normalized =
        ((raw % sections.length) + sections.length) % sections.length;
    if (normalized != _activeIndex) {
      _changeIndex(
        normalized,
        fromRight:
            normalized > _activeIndex ||
            (_activeIndex == sections.length - 1 && normalized == 0),
      );
    }
  }

  void _snapBeltToIndex(int virtualIndex) {
    final screenWidth = MediaQuery.of(context).size.width;
    final target =
        virtualIndex * _kItemWidth - screenWidth / 2 + _kItemWidth / 2;
    _beltScrolling = true;
    _beltController
        .animateTo(
          target,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() => _beltScrolling = false);
  }

  void _snapBeltToSection(int sectionIndex) {
    if (!_beltController.hasClients) return;
    final offset = _beltController.offset;
    final screenWidth = MediaQuery.of(context).size.width;
    final currentVirtual =
        ((offset + screenWidth / 2 - _kItemWidth / 2) / _kItemWidth).round();
    final base =
        currentVirtual - (currentVirtual % sections.length) + sectionIndex;
    _snapBeltToIndex(base);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300) {
      final next = (_activeIndex + 1) % sections.length;
      _changeIndex(next, fromRight: true);
      _snapBeltToSection(next);
    } else if (velocity > 300) {
      final prev = (_activeIndex - 1 + sections.length) % sections.length;
      _changeIndex(prev, fromRight: false);
      _snapBeltToSection(prev);
    }
  }

  @override
  void dispose() {
    _beltController.removeListener(_onBeltScroll);
    _beltController.dispose();
    _contentAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark ? null : GPTheme.primaryColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _BackgroundMesh(),
          Column(
            children: [
              const SizedBox(height: 25),
              _BeltWidget(
                controller: _beltController,
                virtualCount: _virtualCount,
                activeIndex: _activeIndex,
                pulseAnim: _pulseAnim,
                onTapIndex: (vi, si) {
                  _changeIndex(
                    si,
                    fromRight:
                        si > _activeIndex ||
                        (_activeIndex == sections.length - 1 && si == 0),
                  );
                  _snapBeltToIndex(vi);
                },
              ),
              const SizedBox(height: 10),
              _SectionDots(count: sections.length, active: _activeIndex),
              const SizedBox(height: 20),
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                  behavior: HitTestBehavior.translucent,
                  child: AnimatedBuilder(
                    animation: _contentAnim,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnim.value,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..translateByDouble(
                              _slideAnim.value.dx *
                                  MediaQuery.of(context).size.width,
                              0.0,
                              0.0,
                              1.0,
                            )
                            ..translateByDouble(
                              0.0,
                              _slideAnim.value.dy * 120,
                              0.0,
                              1.0,
                            )
                            ..rotateX(_tiltAnim.value),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_activeIndex),
                      child: _buildActiveContent(),
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

  Widget _buildActiveContent() {
    final section = sections[_activeIndex];
    // Sinon la liste des espaces : Mais il existe pour cela 'package:grand_public_v2/app/modules/space/views/spaces_list_view.dart'; donc faut alléger
    if (section.hasSub) {
      return _SpacesContent(ctrl: _ctrl, sectionIndex: _activeIndex);
    }
    return _SimpleContent(
      section: section,
      sectionIndex: _activeIndex,
      pulseAnim: _pulseAnim,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUND MESH
// ─────────────────────────────────────────────────────────────────────────────
class _BackgroundMesh extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Positioned.fill(child: CustomPaint(painter: _MeshPainter()));
}

class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = Colors.white.withValues(alpha: 0.04);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.1),
      size.width * 0.5,
      paint,
    );
    paint.color = Colors.white.withValues(alpha: 0.03);
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.6),
      size.width * 0.6,
      paint,
    );
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 8; i++) {
      final y = size.height * i / 8;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// BELT WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _BeltWidget extends StatelessWidget {
  final ScrollController controller;
  final int virtualCount;
  final int activeIndex;
  final AnimationController pulseAnim;
  final void Function(int, int) onTapIndex;

  const _BeltWidget({
    required this.controller,
    required this.virtualCount,
    required this.activeIndex,
    required this.pulseAnim,
    required this.onTapIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kBeltHeight,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: virtualCount,
        itemExtent: _kItemWidth,
        itemBuilder: (context, vi) {
          final si = vi % sections.length;
          return GestureDetector(
            onTap: () => onTapIndex(vi, si),
            child: _BeltItem(
              section: sections[si],
              isActive: si == activeIndex,
              pulseAnim: pulseAnim,
            ),
          );
        },
      ),
    );
  }
}

class _BeltItem extends StatelessWidget {
  final SectionModel section;
  final bool isActive;
  final AnimationController pulseAnim;

  const _BeltItem({
    required this.section,
    required this.isActive,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: isActive ? 1.0 + pulseAnim.value * 0.06 : 1.0,
              child: child,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isActive)
                  AnimatedBuilder(
                    animation: pulseAnim,
                    builder: (_, _) => Container(
                      width: 62 + pulseAnim.value * 8,
                      height: 62 + pulseAnim.value * 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.25 * (1 - pulseAnim.value),
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  width: isActive ? 56 : 44,
                  height: isActive ? 56 : 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.12),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    section.icon,
                    size: isActive ? 26 : 20,
                    color: isActive ? GPTheme.primaryColor : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.45),
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              fontSize: isActive ? 11.5 : 10.5,
              letterSpacing: 0.2,
            ),
            child: Text(section.title, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION DOTS
// ─────────────────────────────────────────────────────────────────────────────
class _SectionDots extends StatelessWidget {
  final int count;
  final int active;

  const _SectionDots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 5,
          height: 5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIMPLE CONTENT  (Music, Club, Social, Shop)
// ─────────────────────────────────────────────────────────────────────────────
class _SimpleContent extends StatefulWidget {
  final SectionModel section;
  final int sectionIndex;
  final AnimationController pulseAnim;

  const _SimpleContent({
    required this.section,
    required this.sectionIndex,
    required this.pulseAnim,
  });

  @override
  State<_SimpleContent> createState() => _SimpleContentState();
}

class _SimpleContentState extends State<_SimpleContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryAnim;

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _entryAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AnimatedIconHero(
            section: widget.section,
            entryAnim: _entryAnim,
            pulseAnim: widget.pulseAnim,
          ),
          const SizedBox(height: 28),
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _entryAnim,
              curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
            ),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _entryAnim,
                      curve: const Interval(
                        0.3,
                        1.0,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  ),
              child: Text(
                widget.section.title,
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _entryAnim,
              curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
            ),
            child: Text(
              widget.section.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 15,
                height: 1.55,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(height: 40),
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _entryAnim,
              curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
            ),
            child: _GlassButton(
              label: "Explorer",
              // ← Navigate to /home on the correct section tab
              onTap: () => _navigateToHomeSection(widget.sectionIndex),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedIconHero extends StatelessWidget {
  final SectionModel section;
  final AnimationController entryAnim;
  final AnimationController pulseAnim;

  const _AnimatedIconHero({
    required this.section,
    required this.entryAnim,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([entryAnim, pulseAnim]),
      builder: (_, _) {
        final entry = CurvedAnimation(
          parent: entryAnim,
          curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
        ).value;
        final pulse = pulseAnim.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 0.85 + pulse * 0.25,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04 * (1 - pulse)),
                ),
              ),
            ),
            Transform.scale(
              scale: 0.9 + pulse * 0.12,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: 0.07 * (1 - pulse * 0.5),
                  ),
                ),
              ),
            ),
            Transform.scale(
              scale: entry,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.12),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(section.icon, size: 40, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _GlassButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _GlassButton({required this.label, required this.onTap});

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pressAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _pressAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _pressAnim.forward();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _pressAnim.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _pressAnim.reverse();
      },
      child: AnimatedBuilder(
        animation: _pressAnim,
        builder: (_, child) =>
            Transform.scale(scale: 1.0 - _pressAnim.value * 0.04, child: child),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white.withValues(alpha: _pressed ? 0.3 : 0.18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPACES CONTENT
// ─────────────────────────────────────────────────────────────────────────────
// ignore: unused_element
class _SpacesContent extends StatelessWidget {
  final MainPageController ctrl;
  final int sectionIndex;

  const _SpacesContent({required this.ctrl, required this.sectionIndex});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isSpacesLoading.value) {
        return const Center(child: _SpacesLoadingSkeleton());
      }
      if (ctrl.spaces.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dashboard_outlined,
                size: 48,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Aucun espace disponible',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: ctrl.spaces.length,
        itemBuilder: (_, i) => _SpaceCard(space: ctrl.spaces[i], index: i),
      );
    });
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
  late final AnimationController _entryAnim;
  bool _expanded = false;

  static const List<List<Color>> _gradients = [
    [Color(0xFF6C63FF), Color(0xFF3B1FA8)],
    [Color(0xFFFF6B6B), Color(0xFF8B0000)],
    [Color(0xFF00C9A7), Color(0xFF006B5A)],
    [Color(0xFFFFB347), Color(0xFF8B4500)],
    [Color(0xFF56CCF2), Color(0xFF1A5276)],
  ];

  List<Color> get _cardGradient => _gradients[widget.index % _gradients.length];

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.index * 120), () {
      if (mounted) _entryAnim.forward();
    });
  }

  @override
  void dispose() {
    _entryAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entryAnim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: _entryAnim, curve: Curves.easeOutCubic),
            ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _cardGradient[0].withValues(alpha: 0.25),
                _cardGradient[1].withValues(alpha: 0.15),
              ],
            ),
            border: Border.all(
              color: _cardGradient[0].withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SpaceCardHeader(
                    space: widget.space,
                    gradient: _cardGradient,
                    expanded: _expanded,
                    onToggle: () => setState(() => _expanded = !_expanded),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    child: _expanded
                        ? _SpaceCategoryGrid(
                            categories: widget.space.categories,
                            accentColor: _cardGradient[0],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpaceCardHeader extends StatelessWidget {
  final SpaceModel space;
  final List<Color> gradient;
  final bool expanded;
  final VoidCallback onToggle;

  const _SpaceCardHeader({
    required this.space,
    required this.gradient,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: space.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(space.logoUrl!, fit: BoxFit.cover),
                      )
                    : const Icon(
                        Icons.dashboard_customize_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      space.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
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
          const SizedBox(height: 14),
          Row(
            children: [
              _Badge(
                label: "${space.categories.length} catégories",
                icon: Icons.grid_view_rounded,
                color: gradient[0],
              ),
              if (space.previewVideoUrl != null) ...[
                const SizedBox(width: 8),
                _Badge(
                  label: "Vidéo promo",
                  icon: Icons.play_circle_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  // ← "Entrer" goes to the dedicated space page
                  GestureDetector(
                    onTap: () => Get.toNamed('/home/spaces/${space.id}'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      child: Text(
                        "Entrer",
                        style: TextStyle(
                          color: gradient[1],
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
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
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
// CATEGORY GRID
// ─────────────────────────────────────────────────────────────────────────────
class _SpaceCategoryGrid extends StatelessWidget {
  final List<SpaceCategory> categories;
  final Color accentColor;

  const _SpaceCategoryGrid({
    required this.categories,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
            margin: const EdgeInsets.only(bottom: 14),
          ),
          Text(
            'CATÉGORIES',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: categories
                .map((cat) => _CategoryChip(category: cat, accent: accentColor))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final SpaceCategory category;
  final Color accent;

  const _CategoryChip({required this.category, required this.accent});

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _pressed
              ? widget.accent.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: _pressed
                ? widget.accent.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accent,
                ),
              ),
            Text(
              widget.category.title,
              style: const TextStyle(
                color: Colors.white,
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
// LOADING SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class _SpacesLoadingSkeleton extends StatefulWidget {
  const _SpacesLoadingSkeleton();

  @override
  State<_SpacesLoadingSkeleton> createState() => _SpacesLoadingSkeletonState();
}

class _SpacesLoadingSkeletonState extends State<_SpacesLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, _) {
        final opacity = 0.06 + _shimmer.value * 0.1;
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: List.generate(
            3,
            (i) => Container(
              height: 100,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: opacity),
              ),
            ),
          ),
        );
      },
    );
  }
}
