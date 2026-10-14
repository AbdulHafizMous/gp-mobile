// lib/app/modules/youwiiin/views/youwiiin_home_view.dart
//
// Coquille Youwiiin : couleur primaire (GPTheme.primaryColor), drawer partagé, 3 onglets
// (Jeux, Mon profil GCoin, Classement). Theme-aware, états vides gérés.
//
// Onglet Jeux :
//  - "Parties récentes" : 3 max + "Voir plus"
//  - "Tous les jeux" : groupés par lettre + index alphabétique vertical animé
//    à droite (tap / glisser, bulle de lettre, effet vague, haptique).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/components/ad_banner_widget.dart';
import 'package:grand_public_v2/app/modules/channels/views/channels_list_view.dart';
import 'package:grand_public_v2/app/components/profile_completion_banner.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/empty_state_widget.dart';
import 'package:grand_public_v2/app/components/module_bottom_bar.dart';
import 'package:grand_public_v2/app/components/module_drawer.dart';
import 'package:grand_public_v2/app/components/module_page_shell.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

import '../controllers/youwiiin_controller.dart';
import '../widgets/youwiiin_create_room_sheet.dart';
import '../widgets/youwiiin_player_picker.dart' show gzAvatar;
import '../widgets/youwiiin_style.dart';
import 'youwiiin_game_view.dart';

class YouwiiinHomeView extends StatelessWidget {
  const YouwiiinHomeView({super.key});

  // Accès sûr : jamais de « YouwiiinController not found ».
  YouwiiinController get controller => gzController;

  @override
  Widget build(BuildContext context) {
    final st = YwStyle.of(context);
    final accent = st.accent;
    final bg = st.bg;
    final fg = st.fg;

    return Scaffold(
      backgroundColor: bg,
      drawer: ModuleDrawer(
        accentColor: accent,
        moduleName: 'Youwiiin',
        moduleLogo: LOGO_YOUWIIIN_NAV,
        variableItems: [
          ModuleDrawerNavItem(
            title: 'Jeux',
            icon: Icons.grid_view_rounded,
            onTap: () {
              controller.changeTab(0);
              controller.setHomeFilter(0);
            },
          ),
          ModuleDrawerNavItem(
            title: 'Favoris',
            icon: Icons.favorite_rounded,
            onTap: () {
              controller.changeTab(0);
              controller.setHomeFilter(1);
            },
          ),
          ModuleDrawerNavItem(
            title: 'Invitations',
            icon: Icons.mail_rounded,
            onTap: () {
              controller.changeTab(0);
              controller.setHomeFilter(2);
            },
          ),
          ModuleDrawerNavItem(
            title: 'GCoin',
            icon: Icons.monetization_on_outlined,
            onTap: () => controller.changeTab(1),
          ),
          ModuleDrawerNavItem(
            title: 'Classement',
            icon: Icons.leaderboard_rounded,
            onTap: () => controller.changeTab(2),
          ),
        ],
      ),
      appBar: AppBar(
        backgroundColor: bg,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            color: fg,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          ModuleBellAction(category: 'youwiiin', color: fg),
          const SizedBox(width: 4),
        ],
        title: Row(
          children: [
            Image.asset(
              LOGO_YOUWIIIN,
              width: 30,
              height: 30,
              errorBuilder: (_, __, ___) => Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Youwiiin',
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const ProfileCompletionBanner(module: 'youwiiin'),
          Obx(
            () => controller.currentTab.value == 3
                ? const SizedBox.shrink()
                : const AdBannerWidget(screen: 'youwiiin'),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.catalog.isEmpty &&
                  controller.currentTab.value == 0) {
                return const Center(child: CircularProgressIndicator());
              }
              switch (controller.currentTab.value) {
                case 1:
                  return _ProfileTab(accent: accent, fg: fg);
                case 2:
                  return _LeaderboardTab(accent: accent, fg: fg);
                case 3:
                  return ChannelsListBody(accent: accent);
                default:
                  return _CatalogTab(accent: accent, fg: fg);
              }
            }),
          ),
        ],
      ),
      // Même rendu que la barre de Grandpublic (composant partagé).
      bottomNavigationBar: Obx(
        () => ModuleBottomBar(
          backgroundColor: accent,
          accentColor: accent,
          activeIndex: controller.currentTab.value,
          onTap: controller.changeTab,
          items: const [
            ModuleBottomBarItem(icon: Icons.grid_view_rounded, label: 'Jeux'),
            ModuleBottomBarItem(
              icon: Icons.monetization_on_outlined,
              label: 'GCoin',
            ),
            ModuleBottomBarItem(
              icon: Icons.leaderboard_rounded,
              label: 'Classement',
            ),
            // ModuleBottomBarItem(
            //   icon: Icons.live_tv_rounded,
            //   label: 'Chaînes',
            // ),
          ],
        ),
      ),
    );
  }
}

FaIconData gzIcon(String name) => switch (name) {
  'worm' => FontAwesomeIcons.worm,
  'grid-2x2' => FontAwesomeIcons.tableCellsLarge,
  'layout-grid' => FontAwesomeIcons.tableCells,
  'zap' => FontAwesomeIcons.bolt,
  'circle-help' => FontAwesomeIcons.circleQuestion,
  'blocks' => FontAwesomeIcons.cubes,
  'music' => FontAwesomeIcons.music,
  'bird' => FontAwesomeIcons.dove,
  'target' => FontAwesomeIcons.bullseye,
  'hash' => FontAwesomeIcons.hashtag,
  'crown' => FontAwesomeIcons.chess,
  'ghost' => FontAwesomeIcons.ghost,
  'flame' => FontAwesomeIcons.fire,
  'brick-wall' => FontAwesomeIcons.tableCellsLarge,
  'rocket' => FontAwesomeIcons.rocket,
  'layers' => FontAwesomeIcons.layerGroup,
  'circle-dot' => FontAwesomeIcons.circleDot,
  'bomb' => FontAwesomeIcons.bomb,
  'spell-check' => FontAwesomeIcons.spellCheck,
  'footprints' => FontAwesomeIcons.shoePrints,
  'gem' => FontAwesomeIcons.gem,
  'ping-pong' => FontAwesomeIcons.tableTennisPaddleBall,
  'grid-3x3' => FontAwesomeIcons.tableCells,
  'hand' => FontAwesomeIcons.handBackFist,
  'calculator' => FontAwesomeIcons.calculator,
  'palette' => FontAwesomeIcons.palette,
  'keyboard' => FontAwesomeIcons.keyboard,
  _ => FontAwesomeIcons.gamepad,
};

String fmtDuration(int s) {
  if (s < 60) return '${s}s';
  final m = s ~/ 60;
  if (m < 60) return '${m}min ${s % 60}s';
  return '${m ~/ 60}h ${m % 60}min';
}

String ago(dynamic iso) {
  final d = DateTime.tryParse('$iso');
  return d == null ? '' : timeago.format(d.toLocal(), locale: 'fr');
}

Widget _gameBadge(GzGame g, {double size = 48}) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [g.accent, Color.lerp(g.accent, Colors.black, .35)!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(size * .3),
    boxShadow: [
      BoxShadow(
        color: g.accent.withOpacity(.35),
        blurRadius: 12,
        offset: const Offset(0, 5),
      ),
    ],
  ),
  child: Center(
    child: FaIcon(gzIcon(g.icon), color: Colors.white, size: size * .42),
  ),
);

void playGame(GzGame g) =>
    Get.to(() => YouwiiinGameView(game: g), transition: Transition.downToUp);

/// Lettre d'index d'un nom (accents retirés). '#' si ce n'est pas A-Z.
String _letterOf(String name) {
  final s = name.trim();
  if (s.isEmpty) return '#';
  const from = 'ÀÁÂÃÄÅàáâãäåÇçÈÉÊËèéêëÌÍÎÏìíîïÑñÒÓÔÕÖòóôõöÙÚÛÜùúûüÝýÿ';
  const to = 'AAAAAAaaaaaaCcEEEEeeeeIIIIiiiiNnOOOOOoooooUUUUuuuuYyy';
  var ch = s[0];
  final i = from.indexOf(ch);
  if (i >= 0) ch = to[i];
  ch = ch.toUpperCase();
  return RegExp(r'^[A-Z]$').hasMatch(ch) ? ch : '#';
}

String _sortKey(GzGame g) {
  final l = _letterOf(g.name);
  return '${l == '#' ? '~' : l}${g.name.toLowerCase()}';
}

// ─────────────────────────────────────────────────────────────────────────────
// ONGLET JEUX : récents (relançables) + catalogue A-Z avec index vertical
// ─────────────────────────────────────────────────────────────────────────────
class _CatalogTab extends StatefulWidget {
  final Color accent;
  final Color fg;
  const _CatalogTab({required this.accent, required this.fg});

  @override
  State<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<_CatalogTab> with WidgetsBindingObserver {
  static const _az = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  final _scroll = ScrollController();
  final _viewportKey = GlobalKey();
  final _allTitleKey = GlobalKey();
  final Map<String, GlobalKey> _keys = {};

  final _active = ValueNotifier<String>('');
  final _showRail = ValueNotifier<bool>(false);
  final _bubble = ValueNotifier<String?>(null);

  String _lastBubble = '';
  String? _lastTarget;
  bool _railBusy = false;
  List<String> _available = const [];
  List<String> _railLetters = const [];

  // Invitations : rafraîchies toutes les ~20 s tant que l'accueil est visible.
  Timer? _invTimer;
  bool _appResumed = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
    gzController.loadInvitations();
    _invTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _tickInvites(),
    );
  }

  void _tickInvites() {
    if (!mounted || !_appResumed) return;
    // Lobby / jeu ouvert par-dessus : on ne sollicite pas le serveur pour rien.
    if (ModalRoute.of(context)?.isCurrent != true) return;
    gzController.loadInvitations();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    if (_appResumed && mounted) gzController.loadInvitations();
  }

  @override
  void dispose() {
    _invTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _active.dispose();
    _showRail.dispose();
    _bubble.dispose();
    super.dispose();
  }

  /// Met à jour la lettre active et la visibilité de l'index selon le scroll.
  void _onScroll() {
    if (!mounted || !_scroll.hasClients) return;
    final vp = _viewportKey.currentContext?.findRenderObject();
    if (vp is! RenderBox || !vp.attached) return;
    final top = vp.localToGlobal(Offset.zero).dy;
    final h = vp.size.height;

    // L'index n'apparaît qu'à partir de la section "Tous les jeux".
    final tObj = _allTitleKey.currentContext?.findRenderObject();
    if (tObj is RenderBox && tObj.attached) {
      final ty = tObj.localToGlobal(Offset.zero).dy - top;
      final show = ty < h * .55;
      if (_showRail.value != show) _showRail.value = show;
    } else if (_showRail.value) {
      _showRail.value = false;
    }

    if (_railBusy || _available.isEmpty) return;

    String? current;
    for (final l in _available) {
      final o = _keys[l]?.currentContext?.findRenderObject();
      if (o is! RenderBox || !o.attached) continue;
      final y = o.localToGlobal(Offset.zero).dy - top;
      if (y <= 80) {
        current = l;
      } else {
        break;
      }
    }
    current ??= _available.first;

    final pos = _scroll.position;
    if (pos.maxScrollExtent > 0 && pos.pixels >= pos.maxScrollExtent - 4) {
      current = _available.last;
    }
    if (_active.value != current) _active.value = current;
  }

  /// Si la lettre n'a aucun jeu, on saute à la prochaine lettre disponible.
  String? _resolve(String letter) {
    if (_available.isEmpty) return null;
    if (_available.contains(letter)) return letter;
    final i = _railLetters.indexOf(letter);
    for (var k = i < 0 ? 0 : i; k < _railLetters.length; k++) {
      if (_available.contains(_railLetters[k])) return _railLetters[k];
    }
    return _available.last;
  }

  void _onPick(String letter) {
    final target = _resolve(letter);
    if (target == null) return;
    _railBusy = true;
    if (target == _lastTarget) return;
    _lastTarget = target;
    _bubble.value = target;
    _active.value = target;
    HapticFeedback.selectionClick();
    final ctx = _keys[target]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: 0,
      );
    }
  }

  void _onRelease() {
    _railBusy = false;
    _lastTarget = null;
    _bubble.value = null;
  }

  Widget _letterHeader(String l, int n, Color accent, Color fg) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withOpacity(.16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          l,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 1, color: fg.withOpacity(.08))),
      const SizedBox(width: 10),
      Text(
        '$n jeu${n > 1 ? 'x' : ''}',
        style: TextStyle(
          color: fg.withOpacity(.4),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final c = gzController;
    final st = YwStyle.of(context);
    final isDark = st.dark;
    final card = st.card;
    final accent = widget.accent;
    final fg = widget.fg;

    return Obx(() {
      final filter = c.homeFilter.value;
      final showAll = filter == 0 && !c.hasError.value && c.catalog.isNotEmpty;

      // Parties récentes + catalogue A-Z (uniquement pour « Tous »)
      final recentEntries = <(GzGame, Map<String, dynamic>)>[];
      final groups = <String, List<GzGame>>{};
      if (showAll) {
        final byId = {for (final g in c.catalog) g.id: g};
        for (final r in c.recent) {
          final raw = r['game'];
          if (raw is! Map) continue;
          final parsed = GzGame.fromJson(Map<String, dynamic>.from(raw));
          recentEntries.add((
            byId[parsed.id] ?? parsed,
            Map<String, dynamic>.from(r),
          ));
        }
        final sorted = [...c.catalog]
          ..sort((a, b) => _sortKey(a).compareTo(_sortKey(b)));
        for (final g in sorted) {
          groups.putIfAbsent(_letterOf(g.name), () => []).add(g);
        }
      }
      _available = groups.keys.toList();
      _railLetters = [..._az.split(''), if (groups.containsKey('#')) '#'];
      if (_active.value.isEmpty && _available.isNotEmpty) {
        _active.value = _available.first;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());

      final invCount = c.invitations.length;
      final favCount = c.favoriteIds.length;

      Widget body;
      if (filter == 2) {
        body = _InvitationsBody(st: st, onRefresh: c.loadInvitations);
      } else if (filter == 1) {
        if (c.favoritesLoading.value && c.favorites.isEmpty) {
          body = const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (c.favorites.isEmpty) {
          body = const EmptyStateWidget(
            icon: Icons.favorite_border_rounded,
            message:
                'Aucun jeu favori.\nTouchez le cœur d\'un jeu pour le retrouver ici.',
          );
        } else {
          body = GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: c.favorites.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 156,
            ),
            itemBuilder: (_, i) =>
                _GameCard(game: c.favorites[i], card: card, fg: fg),
          );
        }
      } else if (c.hasError.value) {
        body = const EmptyStateWidget(
          icon: Icons.wifi_off_rounded,
          message: 'Impossible de charger les jeux.\nTirez pour réessayer.',
        );
      } else if (c.catalog.isEmpty) {
        body = const EmptyStateWidget(
          icon: Icons.sports_esports_outlined,
          message: 'Aucun jeu disponible pour le moment.',
        );
      } else {
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recentEntries.isNotEmpty) ...[
              _title('Parties récentes', Icons.history_rounded, fg, accent),
              const SizedBox(height: 10),
              _RecentList(
                entries: recentEntries,
                card: card,
                fg: fg,
                accent: accent,
              ),
              const SizedBox(height: 22),
            ],
            KeyedSubtree(
              key: _allTitleKey,
              child: _title(
                'Tous les jeux',
                Icons.grid_view_rounded,
                fg,
                accent,
              ),
            ),
            const SizedBox(height: 10),
            for (final e in groups.entries)
              Padding(
                padding: const EdgeInsets.only(right: 22),
                child: Column(
                  key: _keys.putIfAbsent(e.key, () => GlobalKey()),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 10),
                      child: _letterHeader(e.key, e.value.length, accent, fg),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: e.value.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 156,
                          ),
                      itemBuilder: (_, i) =>
                          _GameCard(game: e.value[i], card: card, fg: fg),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
          ],
        );
      }

      return Stack(
        children: [
          Positioned.fill(
            child: SizedBox.expand(
              key: _viewportKey,
              child: RefreshIndicator(
                color: accent,
                onRefresh: c.refreshAll,
                child: SingleChildScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FilterBar(
                        st: st,
                        filter: filter,
                        favCount: favCount,
                        invCount: invCount,
                        onPick: c.setHomeFilter,
                      ),
                      const SizedBox(height: 14),
                      body,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Index alphabétique vertical (apparaît à la section "Tous les jeux")
          if (showAll)
            Positioned(
              right: 0,
              top: 8,
              bottom: 8,
              child: ValueListenableBuilder<bool>(
                valueListenable: _showRail,
                builder: (_, show, child) => IgnorePointer(
                  ignoring: !show,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    offset: show ? Offset.zero : const Offset(1.2, 0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: show ? 1 : 0,
                      child: child,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: 30,
                  child: _AlphaRail(
                    letters: _railLetters,
                    enabled: _available.toSet(),
                    active: _active,
                    onPick: _onPick,
                    onRelease: _onRelease,
                    accent: accent,
                    fg: fg,
                    isDark: isDark,
                  ),
                ),
              ),
            ),

          // Bulle centrale de la lettre pendant l'appui / glissement
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: ValueListenableBuilder<String?>(
                  valueListenable: _bubble,
                  builder: (_, v, __) {
                    if (v != null) _lastBubble = v;
                    return AnimatedScale(
                      scale: v != null ? 1 : .5,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: AnimatedOpacity(
                        opacity: v != null ? 1 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          width: 88,
                          height: 88,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: .45),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            _lastBubble,
                            style: const TextStyle(
                              color: YwStyle.onAccent,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// Index A-Z vertical : tap ou glisser. Effet "vague" autour du doigt.
class _AlphaRail extends StatefulWidget {
  final List<String> letters;
  final Set<String> enabled;
  final ValueListenable<String> active;
  final ValueChanged<String> onPick;
  final VoidCallback onRelease;
  final Color accent, fg;
  final bool isDark;
  const _AlphaRail({
    required this.letters,
    required this.enabled,
    required this.active,
    required this.onPick,
    required this.onRelease,
    required this.accent,
    required this.fg,
    required this.isDark,
  });

  @override
  State<_AlphaRail> createState() => _AlphaRailState();
}

class _AlphaRailState extends State<_AlphaRail> {
  double? _finger; // index flottant sous le doigt (null = pas d'appui)
  int _lastIdx = -1;

  void _touch(double dy, double itemH) {
    final n = widget.letters.length;
    final idx = (dy / itemH).floor().clamp(0, n - 1);
    setState(() => _finger = dy / itemH - .5);
    if (idx != _lastIdx) {
      _lastIdx = idx;
      widget.onPick(widget.letters[idx]);
    }
  }

  void _release() {
    _lastIdx = -1;
    if (mounted) setState(() => _finger = null);
    widget.onRelease();
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.letters;
    final n = letters.length;

    return LayoutBuilder(
      builder: (_, cons) {
        final itemH = math.min(22.0, cons.maxHeight / n);
        final h = itemH * n;
        final pressed = _finger != null;
        final fontSize = itemH >= 17 ? 11.5 : 9.5;

        return Align(
          alignment: Alignment.center,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _touch(e.localPosition.dy, itemH),
            onPointerMove: (e) => _touch(e.localPosition.dy, itemH),
            onPointerUp: (_) => _release(),
            onPointerCancel: (_) => _release(),
            child: ValueListenableBuilder<String>(
              valueListenable: widget.active,
              builder: (_, act, __) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 30,
                height: h,
                decoration: BoxDecoration(
                  color: pressed
                      ? (widget.isDark
                            ? Colors.white.withOpacity(.10)
                            : Colors.black.withOpacity(.07))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < n; i++)
                      Builder(
                        builder: (_) {
                          final l = letters[i];
                          final isAct = l == act;
                          final on = widget.enabled.contains(l);
                          final f = pressed
                              ? (1 - (i - _finger!).abs() / 3).clamp(0.0, 1.0)
                              : 0.0;
                          return SizedBox(
                            height: itemH,
                            child: AnimatedSlide(
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOut,
                              offset: Offset(-.7 * f, 0),
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeOut,
                                scale:
                                    1 + .9 * f + (isAct && !pressed ? .25 : 0),
                                child: SizedBox(
                                  width: 30,
                                  child: Center(
                                    child: Text(
                                      l,
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        fontWeight: isAct || f > .5
                                            ? FontWeight.w900
                                            : FontWeight.w700,
                                        color: isAct
                                            ? widget.accent
                                            : on
                                            ? widget.fg.withOpacity(.7)
                                            : widget.fg.withOpacity(.2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _title(String t, IconData i, Color fg, Color accent) => Row(
  children: [
    Icon(i, size: 20, color: accent),
    const SizedBox(width: 8),
    Text(
      t,
      style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.w800),
    ),
  ],
);

/// Cœur de favori animé (rebond au changement d'état).
class _FavHeart extends StatelessWidget {
  final bool fav;
  final VoidCallback onTap;
  final double size;
  const _FavHeart({required this.fav, required this.onTap, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (c, a) => ScaleTransition(
            scale: CurvedAnimation(parent: a, curve: Curves.elasticOut),
            child: c,
          ),
          child: Icon(
            fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(fav),
            size: size,
            color: fav ? GPTheme.primaryColor : Colors.grey,
          ),
        ),
      ),
    );
  }
}

/// Barre de filtres de l'accueil : Tous · Favoris · Invitations (badge).
class _FilterBar extends StatelessWidget {
  final YwStyle st;
  final int filter, favCount, invCount;
  final ValueChanged<int> onPick;
  const _FilterBar({
    required this.st,
    required this.filter,
    required this.favCount,
    required this.invCount,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _pill(0, 'Tous', null, 0),
        const SizedBox(width: 8),
        _pill(1, 'Favoris', Icons.favorite_rounded, favCount),
        const SizedBox(width: 8),
        _pill(2, 'Invitations', Icons.mail_rounded, invCount, badge: true),
      ],
    );
  }

  Widget _pill(
    int i,
    String label,
    IconData? icon,
    int count, {
    bool badge = false,
  }) {
    final on = filter == i;
    final fgc = on ? YwStyle.onAccent : st.fg;
    return Expanded(
      child: Material(
        color: on ? st.accent : st.card,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            HapticFeedback.selectionClick();
            onPick(i);
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: YwStyle.minTap),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 15,
                        color: on ? YwStyle.onAccent : st.accent,
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      !badge && count > 0 ? '$label ($count)' : label,
                      maxLines: 1,
                      style: TextStyle(
                        color: fgc,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    if (badge && count > 0) ...[
                      const SizedBox(width: 6),
                      YwCountBadge(count: count, onAccent: on),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Contenu de l'onglet « Invitations » : cartes + état vide.
class _InvitationsBody extends StatelessWidget {
  final YwStyle st;
  final Future<void> Function() onRefresh;
  const _InvitationsBody({required this.st, required this.onRefresh});

  @override
  Widget build(BuildContext context) => Obx(_content);

  Widget _content() {
    final c = gzController;
    final list = c.invitations;
    if (list.isEmpty) {
      if (!c.invitationsLoaded.value) {
        return const Padding(
          padding: EdgeInsets.all(30),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return SizedBox(
        height: 340,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: st.accent.withValues(alpha: .12),
                  ),
                  child: Icon(
                    Icons.mark_email_unread_outlined,
                    size: 34,
                    color: st.accent,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune invitation',
                  style: TextStyle(
                    color: st.fg,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Quand un ami vous invite à une partie, elle apparaît ici et reste disponible tant que la salle est ouverte.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: st.sub, fontSize: 13, height: 1.35),
                ),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: onRefresh,
                  icon: Icon(Icons.refresh_rounded, color: st.accent, size: 18),
                  label: Text(
                    'Actualiser',
                    style: TextStyle(
                      color: st.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final inv in list)
          _InvitationCard(key: ValueKey(inv.code), room: inv, st: st),
      ],
    );
  }
}

/// Invitation reçue : hôte, jeu, mise, joueurs. Rejoindre → lobby (qui fait le join).
class _InvitationCard extends StatefulWidget {
  final GzRoom room;
  final YwStyle st;
  const _InvitationCard({super.key, required this.room, required this.st});

  @override
  State<_InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends State<_InvitationCard> {
  bool _busy = false;

  void _join() => Get.toNamed(
    '/youwiiin/room/${widget.room.code}',
    arguments: {'join': true},
  );

  Future<void> _decline() async {
    if (_busy) return;
    setState(() => _busy = true);
    final r = await gzController.declineRoom(widget.room.code);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok)
      ToastHelper.showToast(
        r.error ?? 'Impossible de refuser l\'invitation.',
        backgroundColor: YwStyle.danger,
      );
  }

  Widget _chip(IconData icon, String text) {
    final st = widget.st;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: st.fg.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: st.accent),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: st.fg,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.st;
    final room = widget.room;
    final host = room.player(room.hostId);
    final hostName = (host?.name ?? '').isEmpty ? 'Un joueur' : host!.name;
    final g = room.toGame();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: st.card,
        borderRadius: BorderRadius.circular(YwStyle.rCard),
        border: Border.all(color: st.accent.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              gzAvatar(hostName, host?.avatarUrl, size: 44, color: st.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hostName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: st.fg,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'vous invite à jouer',
                      style: TextStyle(color: st.sub, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _gameBadge(g, size: 44),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            room.gameName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: st.fg,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                Icons.toll_rounded,
                room.stake == 0 ? 'Gratuit' : '${room.stake} GCoin',
              ),
              _chip(
                Icons.group_rounded,
                '${room.joinedCount}/${room.maxPlayers} joueurs',
              ),
              if (room.mode != null)
                _chip(
                  room.isScoreDuel
                      ? Icons.emoji_events_outlined
                      : Icons.grid_view_rounded,
                  gzModeLabel(room.mode),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: _busy ? null : _decline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: st.fg,
                      side: BorderSide(color: st.fg.withValues(alpha: .25)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(YwStyle.rBtn),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Refuser',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _join,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: st.accent,
                      foregroundColor: YwStyle.onAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(YwStyle.rBtn),
                      ),
                    ),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text(
                      'Rejoindre',
                      style: TextStyle(fontWeight: FontWeight.w800),
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

class _GameCard extends StatelessWidget {
  final GzGame game;
  final Color card, fg;
  const _GameCard({required this.game, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) {
    final c = gzController;
    return Stack(
      children: [
        Positioned.fill(child: _card(context)),
        // Cœur favori (réactif)
        Positioned(
          top: 4,
          right: 4,
          child: Obx(
            () => _FavHeart(
              fav: c.isFav(game),
              onTap: () => c.toggleFavorite(game),
            ),
          ),
        ),
        if (game.isMultiplayer)
          Positioned(
            top: 16,
            right: 48,
            child: Icon(
              Icons.groups_rounded,
              size: 18,
              color: fg.withOpacity(.4),
            ),
          ),
      ],
    );
  }

  Widget _card(BuildContext context) {
    return Material(
      color: card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showGameSheet(context, game),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _gameBadge(game, size: 52),
              const Spacer(),
              Text(
                game.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 14,
                    color: game.accent,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      game.myBest > 0
                          ? 'Record ${game.myBest}'
                          : 'Pas encore joué',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg.withOpacity(.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Parties récentes : 3 max + "Voir plus" (même logique que _PerGameList).
class _RecentList extends StatefulWidget {
  final List<(GzGame, Map<String, dynamic>)> entries;
  final Color card, fg, accent;
  const _RecentList({
    required this.entries,
    required this.card,
    required this.fg,
    required this.accent,
  });

  @override
  State<_RecentList> createState() => _RecentListState();
}

class _RecentListState extends State<_RecentList> {
  bool _all = false;
  static const _max = 3;

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final shown = _all ? entries : entries.take(_max).toList();
    return Column(
      children: [
        ...shown.map(
          (e) => _RecentTile(
            game: e.$1,
            data: e.$2,
            playable: e.$2['is_playable'] == true,
            card: widget.card,
            fg: widget.fg,
          ),
        ),
        if (entries.length > _max)
          TextButton.icon(
            onPressed: () => setState(() => _all = !_all),
            icon: Icon(
              _all ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: widget.accent,
            ),
            label: Text(
              _all ? 'Voir moins' : 'Voir plus (${entries.length - _max})',
              style: TextStyle(
                color: widget.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentTile extends StatelessWidget {
  final GzGame game;
  final Map<String, dynamic> data;
  final bool playable;
  final Color card, fg;
  const _RecentTile({
    required this.game,
    required this.data,
    required this.playable,
    required this.card,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final last = data['last_score'];
    return Opacity(
      opacity: playable ? 1 : .5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: playable
              ? () => playGame(game)
              : () => Get.snackbar(
                  'Jeu en pause',
                  'Ce jeu est momentanément indisponible.',
                ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _gameBadge(game, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${ago(data['last_played_at'])} · ${data['sessions']} partie${(data['sessions'] ?? 0) > 1 ? 's' : ''} · ${fmtDuration((data['total_duration_seconds'] ?? 0) as int)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg.withOpacity(.55),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _mini(
                            Icons.emoji_events_rounded,
                            '${data['best_score']}',
                            game.accent,
                          ),
                          if (last != null)
                            _mini(
                              Icons.flag_rounded,
                              '$last',
                              fg.withOpacity(.6),
                            ),
                          if (data['last_level'] != null)
                            _mini(
                              Icons.tune_rounded,
                              '${data['last_level']}',
                              fg.withOpacity(.6),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: playable ? game.accent : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    playable ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mini(IconData i, String t, Color c) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(i, size: 13, color: c),
      const SizedBox(width: 3),
      Text(
        t,
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

/// Fiche d'un jeu : statistiques personnelles + top 10 + bouton Jouer.
void _showGameSheet(BuildContext context, GzGame g) {
  final c = gzController;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final fg = isDark ? Colors.white : Colors.black87;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: YwStyle.of(context).sheet,
    shape: YwStyle.sheetShape,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      maxChildSize: .95,
      builder: (ctx, scroll) => FutureBuilder<Map<String, dynamic>?>(
        future: c.gameStats(g),
        builder: (_, snap) {
          final d = snap.data;
          final mine = d?['mine'] as Map<String, dynamic>?;
          final top = (d?['top'] as List?) ?? const [];
          final hist = (d?['history'] as List?) ?? const [];
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _gameBadge(g, size: 62),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fg,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if ((g.description ?? '').isNotEmpty)
                          Text(
                            g.description!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: fg.withOpacity(.6),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Cœur favori
                  Obx(
                    () => _FavHeart(
                      fav: c.isFav(g),
                      size: 28,
                      onTap: () => c.toggleFavorite(g),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    playGame(g);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GPTheme.primaryColor,
                    foregroundColor: YwStyle.onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: const Text(
                    'Jouer',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
              if (g.isMultiplayer) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      showYouwiiinCreateRoomSheet(context, g);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: fg,
                      side: BorderSide(color: GPTheme.primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(
                      Icons.groups_rounded,
                      color: GPTheme.primaryColor,
                    ),
                    label: const Text(
                      'Jouer avec des amis',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (snap.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (d == null)
                Text(
                  'Statistiques indisponibles.',
                  style: TextStyle(color: fg.withOpacity(.5)),
                )
              else ...[
                _StatGrid(
                  children: [
                    _stat(
                      'Record',
                      '${mine?['best_score'] ?? 0}',
                      Icons.emoji_events_rounded,
                      g.accent,
                      fg,
                      isDark,
                    ),
                    _stat(
                      'Moyenne',
                      '${mine?['avg_score'] ?? 0}',
                      Icons.show_chart_rounded,
                      g.accent,
                      fg,
                      isDark,
                    ),
                    _stat(
                      'Parties',
                      '${mine?['plays'] ?? 0}',
                      Icons.sports_esports_rounded,
                      g.accent,
                      fg,
                      isDark,
                    ),
                    _stat(
                      'Temps de jeu',
                      fmtDuration(
                        (mine?['total_duration_seconds'] ?? 0) as int,
                      ),
                      Icons.timer_rounded,
                      g.accent,
                      fg,
                      isDark,
                    ),
                    _stat(
                      'Mon rang',
                      mine?['rank'] != null ? '#${mine!['rank']}' : '—',
                      Icons.leaderboard_rounded,
                      g.accent,
                      fg,
                      isDark,
                    ),
                    _stat(
                      'GCoin gagnés',
                      '${mine?['gcoin_earned'] ?? 0}',
                      Icons.toll_rounded,
                      g.accent,
                      fg,
                      isDark,
                    ),
                  ],
                ),
                if (top.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text(
                    'Top joueurs',
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...top
                      .take(5)
                      .map(
                        (r) => _LbRow(
                          row: Map<String, dynamic>.from(r),
                          game: true,
                          fg: fg,
                          isDark: isDark,
                          accent: g.accent,
                        ),
                      ),
                ],
                if (hist.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text(
                    'Mes dernières parties',
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...hist
                      .take(8)
                      .map(
                        (h) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.flag_rounded,
                            color: g.accent,
                            size: 20,
                          ),
                          title: Text(
                            '${h['score']} pts${h['level'] != null ? ' · ${h['level']}' : ''}',
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${ago(h['created_at'])} · ${fmtDuration((h['duration_seconds'] ?? 0) as int)}',
                            style: TextStyle(
                              color: fg.withOpacity(.5),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                ],
              ],
            ],
          );
        },
      ),
    ),
  );
}

/// Grille de cartes de stats : 2 par ligne, chacune prend exactement la moitié
/// de la largeur disponible (jamais de largeur fixe -> pas de vide ni d'overflow).
class _StatGrid extends StatelessWidget {
  final List<Widget> children;
  const _StatGrid({required this.children});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, c) {
      const gap = 10.0;
      final w = (c.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final ch in children) SizedBox(width: w, child: ch)],
      );
    },
  );
}

Widget _stat(String l, String v, IconData i, Color a, Color fg, bool dark) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(YwStyle.rBtn),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: a.withOpacity(.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(i, size: 19, color: a),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    v,
                    maxLines: 1,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  l,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg.withOpacity(.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

// ─────────────────────────────────────────────────────────────────────────────
// ONGLET GCOIN : solde + gains par jeu + historique détaillé
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final Color accent;
  final Color fg;
  const _ProfileTab({required this.accent, required this.fg});

  @override
  Widget build(BuildContext context) {
    final c = gzController;
    // final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = YwStyle.of(context).card;

    return Obx(
      () => RefreshIndicator(
        onRefresh: c.loadGcoin,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [accent, Color.lerp(accent, Colors.black, .35)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.toll_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Mon solde GCoin',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: c.gcoinBalance.value.toDouble(),
                    ),
                    duration: const Duration(milliseconds: 700),
                    builder: (_, v, __) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${v.round()}',
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _pill(
                        Icons.south_west_rounded,
                        '${c.totalEarned.value} gagnés',
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      _pill(
                        Icons.north_east_rounded,
                        '${c.totalSpent.value} dépensés',
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (c.gcoinPerGame.isNotEmpty) ...[
              const SizedBox(height: 22),
              _title('Gains par jeu', Icons.sports_esports_rounded, fg, accent),
              const SizedBox(height: 10),
              _PerGameList(
                rows: c.gcoinPerGame.toList(),
                card: card,
                fg: fg,
                accent: accent,
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _title(
                    'Historique',
                    Icons.receipt_long_rounded,
                    fg,
                    accent,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Filtrer',
                  initialValue: c.historyType.value,
                  onSelected: c.setHistoryType,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: '', child: Text('Tout')),
                    PopupMenuItem(value: 'earned', child: Text('Gains')),
                    PopupMenuItem(value: 'spent', child: Text('Dépenses')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: c.historyType.value.isEmpty
                          ? fg.withOpacity(.08)
                          : accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: 18,
                          color: c.historyType.value.isEmpty
                              ? fg
                              : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          c.historyType.value == 'earned'
                              ? 'Gains'
                              : c.historyType.value == 'spent'
                              ? 'Dépenses'
                              : 'Filtre',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.historyType.value.isEmpty
                                ? fg
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (c.historyLoading.value && c.gcoinHistory.isEmpty)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (c.gcoinHistory.isEmpty)
              const EmptyStateWidget(
                icon: Icons.receipt_long_outlined,
                message:
                    'Aucune transaction pour le moment.\nJouez pour gagner des GCoin !',
                minHeight: 220,
              )
            else
              ...c.gcoinHistory.map((t) {
                final amt = (t['amount'] ?? 0) as int;
                final pos = amt >= 0;
                final game = t['game'] is Map
                    ? GzGame.fromJson(Map<String, dynamic>.from(t['game']))
                    : null;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      game != null
                          ? _gameBadge(game, size: 40)
                          : Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: (pos ? Colors.green : Colors.red)
                                    .withOpacity(.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                pos ? Icons.add_rounded : Icons.remove_rounded,
                                color: pos ? Colors.green : Colors.red,
                              ),
                            ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game != null
                                  ? '${game.name}${t['score'] != null ? ' · ${t['score']} pts' : ''}'
                                  : '${t['label']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${t['label']} · ${ago(t['created_at'])}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: fg.withOpacity(.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${pos ? '+' : ''}$amt',
                        style: TextStyle(
                          color: pos ? const Color(0xFF16A34A) : Colors.red,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _pill(IconData i, String t, {Color? color}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black12,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, size: 14, color: color ?? Colors.black87),
        const SizedBox(width: 4),
        Text(
          t,
          style: TextStyle(
            color: color ?? Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ONGLET CLASSEMENT : général (1 ligne / joueur) + détail par jeu
// ─────────────────────────────────────────────────────────────────────────────
class _LeaderboardTab extends StatelessWidget {
  final Color accent;
  final Color fg;
  const _LeaderboardTab({required this.accent, required this.fg});

  @override
  Widget build(BuildContext context) {
    final c = gzController;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isGame = c.lbGame.value.isNotEmpty;
      return RefreshIndicator(
        onRefresh: c.loadLeaderboard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Row(
                children: [
                  _chip(
                    'Général',
                    c.lbGame.value.isEmpty,
                    () => c.setLbGame(''),
                    accent,
                    fg,
                  ),
                  ...c.catalog.map(
                    (g) => _chip(
                      g.name,
                      c.lbGame.value == g.slug,
                      () => c.setLbGame(g.slug),
                      g.accent,
                      fg,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Row(
                children: [
                  for (final p in const [
                    ('all', 'Tout temps'),
                    ('monthly', 'Ce mois'),
                    ('weekly', 'Cette semaine'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          p.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.lbPeriod.value == p.$1 ? Colors.white : fg,
                          ),
                        ),
                        selected: c.lbPeriod.value == p.$1,
                        selectedColor: accent,
                        onSelected: (_) => c.setLbPeriod(p.$1),
                        checkmarkColor: Colors.white,
                        iconTheme: const IconThemeData(size: 16),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (c.lbMe.value != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [accent, Color.lerp(accent, Colors.black, .35)!],
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '#${c.lbMe.value!['rank']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Votre position',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'sur ${c.lbTotal.value} joueur${c.lbTotal.value > 1 ? 's' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      isGame
                          ? '${c.lbMe.value!['best_score']} pts'
                          : '${c.lbMe.value!['points']} pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (c.lbLoading.value && c.lbRows.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (c.lbRows.isEmpty)
              const EmptyStateWidget(
                icon: Icons.leaderboard_outlined,
                message: 'Aucun score pour cette période.\nSoyez le premier !',
                minHeight: 260,
              )
            else
              ...c.lbRows.map(
                (r) => _LbRow(
                  row: r,
                  game: isGame,
                  fg: fg,
                  isDark: isDark,
                  accent: accent,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _chip(String t, bool on, VoidCallback f, Color a, Color fg) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(
        t,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: on ? Colors.white : fg,
        ),
      ),
      selected: on,
      selectedColor: a,
      checkmarkColor: Colors.white,
      onSelected: (_) => f(),
    ),
  );
}

class _PerGameList extends StatefulWidget {
  final List<Map<String, dynamic>> rows;
  final Color card, fg, accent;
  const _PerGameList({
    required this.rows,
    required this.card,
    required this.fg,
    required this.accent,
  });

  @override
  State<_PerGameList> createState() => _PerGameListState();
}

class _PerGameListState extends State<_PerGameList> {
  bool _all = false;
  static const _max = 4;

  @override
  Widget build(BuildContext context) {
    final rows = widget.rows;
    final shown = _all ? rows : rows.take(_max).toList();
    return Column(
      children: [
        ...shown.map((r) {
          final gg = GzGame.fromJson(
            Map<String, dynamic>.from(r['game'] as Map),
          );
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _gameBadge(gg, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    gg.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '+${r['total']}',
                  style: const TextStyle(
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }),
        if (rows.length > _max)
          TextButton.icon(
            onPressed: () => setState(() => _all = !_all),
            icon: Icon(
              _all ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: widget.accent,
            ),
            label: Text(
              _all ? 'Voir moins' : 'Voir plus (${rows.length - _max})',
              style: TextStyle(
                color: widget.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _LbRow extends StatefulWidget {
  final Map<String, dynamic> row;
  final bool game, isDark;
  final Color fg, accent;
  const _LbRow({
    required this.row,
    required this.game,
    required this.fg,
    required this.isDark,
    required this.accent,
  });

  @override
  State<_LbRow> createState() => _LbRowState();
}

class _LbRowState extends State<_LbRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    final rank = (r['rank'] ?? 0) as int;
    final medal = rank == 1
        ? const Color(0xFFFFC107)
        : rank == 2
        ? const Color(0xFFB0BEC5)
        : rank == 3
        ? const Color(0xFFCD7F32)
        : null;
    final avatar = r['avatar_url']?.toString();

    final details = widget.game
        ? <(IconData, String)>[
            (
              Icons.tune_rounded,
              r['level'] != null ? 'Niveau ${r['level']}' : 'Niveau —',
            ),
            (
              Icons.timer_rounded,
              'Durée ${fmtDuration((r['duration_seconds'] ?? 0) as int)}',
            ),
            (Icons.event_rounded, 'Le ${ago(r['achieved_at'])}'),
            (Icons.sports_esports_rounded, '${r['plays']} parties'),
            (Icons.show_chart_rounded, 'Moyenne ${r['avg_score']}'),
            (
              Icons.hourglass_bottom_rounded,
              'Total ${fmtDuration((r['total_duration_seconds'] ?? 0) as int)}',
            ),
          ]
        : <(IconData, String)>[
            (Icons.grid_view_rounded, '${r['games_played']} jeux joués'),
            (Icons.sports_esports_rounded, '${r['plays']} parties'),
            (
              Icons.timer_rounded,
              fmtDuration((r['total_duration_seconds'] ?? 0) as int),
            ),
            (Icons.event_rounded, 'Dernière : ${ago(r['last_played_at'])}'),
          ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.fg.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(YwStyle.rBtn),
        border: medal != null
            ? Border.all(color: medal.withOpacity(.6), width: 1.4)
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: medal != null
                        ? Icon(
                            Icons.workspace_premium_rounded,
                            color: medal,
                            size: 28,
                          )
                        : Text(
                            '$rank',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: widget.fg.withOpacity(.5),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: widget.accent.withOpacity(.25),
                    backgroundImage: avatar != null && avatar.isNotEmpty
                        ? NetworkImage(avatar)
                        : null,
                    child: avatar == null || avatar.isEmpty
                        ? Text(
                            '${r['name'] ?? '?'}'.characters.first
                                .toUpperCase(),
                            style: TextStyle(
                              color: widget.fg,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${r['name']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.fg,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    widget.game ? '${r['best_score']}' : '${r['points']}',
                    style: TextStyle(
                      color: widget.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Icon(
                    _open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: widget.fg.withOpacity(.4),
                  ),
                ],
              ),
              if (_open)
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 4),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      for (final d in details)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              d.$1,
                              size: 14,
                              color: widget.fg.withOpacity(.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              d.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: widget.fg.withOpacity(.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
