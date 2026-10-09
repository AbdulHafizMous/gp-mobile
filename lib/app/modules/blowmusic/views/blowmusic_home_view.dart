import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grand_public_v2/app/components/live_fullscreen_page.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import 'package:grand_public_v2/app/components/empty_state_widget.dart';
import 'package:grand_public_v2/app/components/vinyl_disc.dart';
import 'package:grand_public_v2/app/components/module_bottom_bar.dart';
import 'package:grand_public_v2/app/components/module_drawer.dart';
import 'package:grand_public_v2/app/components/module_page_shell.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/services/recent_history_service.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

import '../controllers/blowmusic_controller.dart';
import 'bm_player_page.dart';
import 'bm_playlist_page.dart';

class BlowMusicHomeView extends GetView<BlowMusicController> {
  const BlowMusicHomeView({super.key});

  IconData _iconFor(String icon) {
    switch (icon) {
      case 'home':
        return Icons.home_rounded;
      case 'live':
        return Icons.podcasts_rounded;
      case 'library':
        return Icons.library_music_rounded;
      case 'playlist':
        return Icons.playlist_play_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = GPTheme.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0E0B12) : const Color(0xFFF7F5F8);
    final fg = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bg,

      drawer: ModuleDrawer(
        accentColor: accent,
        moduleName: 'Blowmusic',
        moduleLogo: LOGO_BLOWMUSIC,
        variableItems: [
          ModuleDrawerNavItem(
            title: 'Accueil',
            icon: Icons.home_rounded,
            onTap: () => controller.changeTab(0),
          ),
          ModuleDrawerNavItem(
            title: 'Live',
            icon: Icons.podcasts_rounded,
            onTap: () => controller.changeTab(1),
          ),
          ModuleDrawerNavItem(
            title: 'Biblio',
            icon: Icons.library_music_rounded,
            onTap: () => controller.changeTab(2),
          ),
          ModuleDrawerNavItem(
            title: 'Playlists',
            icon: Icons.playlist_play_rounded,
            onTap: () => controller.changeTab(3),
          ),
          ModuleDrawerNavItem(
            title: 'Favoris',
            icon: Icons.favorite_rounded,
            onTap: () => controller.changeTab(4),
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
        centerTitle: true,
        elevation: 0,
        actions: [
          ModuleBellAction(category: 'blowmusic', color: fg),
          const SizedBox(width: 4),
        ],
        title: SizedBox(
          height: 25,
          child: Image.asset(
            LOGO_BLOWMUSIC_NAV_LIGHT,
            height: 30,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value)
          return const Center(child: CircularProgressIndicator());
        switch (controller.currentTab.value) {
          case 1:
            return _LiveTab(accent: accent, fg: fg);
          case 2:
            return _LibraryTab(accent: accent, fg: fg);
          case 3:
            return _PlaylistsTab(fg: fg);
          case 4:
            return _FavoritesTab(accent: accent, fg: fg);
          default:
            return _HomeTab(accent: accent, fg: fg);
        }
      }),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _MiniPlayer(),
          Obx(
            // Même rendu que la barre de Grandpublic (composant partagé).
            () => ModuleBottomBar(
              backgroundColor: accent,
              accentColor: accent,
              activeIndex: controller.currentTab.value,
              onTap: controller.changeTab,
              items: kBlowMusicTabs
                  .map(
                    (t) => ModuleBottomBarItem(
                      icon: _iconFor(t.icon),
                      label: t.label,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// COMPOSANTS PARTAGÉS : en-tête de section, animation d'entrée, liste "Voir plus"
// -----------------------------------------------------------------------------

/// En-tête de section : pastille d'icône + titre + compteur.
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? count;
  final Color accent, fg;
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.accent,
    required this.fg,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accent.withOpacity(.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ),
        if (count != null && count! > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: fg.withOpacity(.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: fg.withOpacity(.6),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

/// Apparition douce : fondu + glissement vers le haut, avec délai.
class _FadeSlide extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _FadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<_FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<_FadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - _a.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Liste repliable : [max] éléments + "Voir plus (N)" / "Voir moins".
class _ExpandableList extends StatefulWidget {
  final List<Widget> children;
  final int max;
  final Color accent;
  const _ExpandableList({
    required this.children,
    required this.max,
    required this.accent,
  });

  @override
  State<_ExpandableList> createState() => _ExpandableListState();
}

class _ExpandableListState extends State<_ExpandableList> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.children;
    final max = widget.max;
    final count = _all ? items.length : math.min(items.length, max);

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              for (var i = 0; i < count; i++)
                _FadeSlide(
                  key: ValueKey('es_$i'),
                  delay: Duration(
                    milliseconds: i < max ? i * 70 : (i - max) * 55,
                  ),
                  child: items[i],
                ),
            ],
          ),
        ),
        if (items.length > max)
          TextButton.icon(
            onPressed: () => setState(() => _all = !_all),
            icon: AnimatedRotation(
              turns: _all ? .5 : 0,
              duration: const Duration(milliseconds: 250),
              child: Icon(Icons.expand_more_rounded, color: widget.accent),
            ),
            label: Text(
              _all ? 'Voir moins' : 'Voir plus (${items.length - max})',
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

// -----------------------------------------------------------------------------
// INDEX ALPHABÉTIQUE : utilitaires + rail vertical A-Z
// -----------------------------------------------------------------------------

/// Lettre d'index d'un titre (accents retirés). '#' si ce n'est pas A-Z.
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

String _titleSortKey(String name) {
  final l = _letterOf(name);
  return '${l == '#' ? '~' : l}${name.trim().toLowerCase()}';
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
  double? _finger;
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

// -----------------------------------------------------------------------------
// TAB 1: ACCUEIL
// -----------------------------------------------------------------------------
class _HomeTab extends StatelessWidget {
  final Color accent;
  final Color fg;
  const _HomeTab({required this.accent, required this.fg});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();
    final recent = RecentHistoryService.recentTracks
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return RefreshIndicator(
      onRefresh: ctrl.loadHome,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Obx(
            () => ctrl.hasError.value
                ? EmptyStateWidget(
                    icon: Icons.wifi_off_rounded,
                    message: 'Connexion impossible. Tirez pour réessayer.',
                    color: accent,
                  )
                : const SizedBox.shrink(),
          ),

          // ── Repris récemment : 3 max + Voir plus ────────────────────────────
          if (recent.isNotEmpty) ...[
            _SectionHeader(
              title: 'Repris récemment',
              icon: Icons.history_rounded,
              count: recent.length,
              accent: accent,
              fg: fg,
            ),
            const SizedBox(height: 12),
            _ExpandableList(
              max: 3,
              accent: accent,
              children: [
                for (final r in recent)
                  _RecentTile(data: r, accent: accent, fg: fg),
              ],
            ),
            const SizedBox(height: 22),
          ],

          // ── En ce moment : 4 max + Voir plus ────────────────────────────────
          Obx(() {
            final list = ctrl.latestTracks.toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'En ce moment',
                  icon: Icons.bolt_rounded,
                  count: list.length,
                  accent: accent,
                  fg: fg,
                ),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  const EmptyStateWidget(
                    icon: Icons.music_off_rounded,
                    message: 'Aucun morceau disponible.',
                  )
                else
                  _ExpandableList(
                    max: 4,
                    accent: accent,
                    children: [
                      for (final t in list)
                        _TrackTile(
                          track: t,
                          accent: accent,
                          fg: fg,
                          queue: list,
                          label: 'En ce moment',
                        ),
                    ],
                  ),
              ],
            );
          }),
          const SizedBox(height: 22),

          // ── Les plus écoutés : classement 5 max + Voir plus ─────────────────
          Obx(() {
            final list = ctrl.mostPlayed.toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Les plus écoutés',
                  icon: Icons.local_fire_department_rounded,
                  count: list.length,
                  accent: accent,
                  fg: fg,
                ),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  const EmptyStateWidget(
                    icon: Icons.trending_up_rounded,
                    message: 'Pas de classement disponible.',
                  )
                else
                  _ExpandableList(
                    max: 5,
                    accent: accent,
                    children: [
                      for (var i = 0; i < list.length; i++)
                        _TrackTile(
                          track: list[i],
                          accent: accent,
                          fg: fg,
                          queue: list,
                          label: 'Les plus écoutés',
                          rank: i + 1,
                        ),
                    ],
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Carte d'un titre repris récemment : relance la lecture au tap.
class _RecentTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color accent, fg;
  const _RecentTile({
    required this.data,
    required this.accent,
    required this.fg,
  });

  BmTrack? _resolve(BlowMusicController c) {
    final id = (data['id'] ?? data['track_id'])?.toString();
    final title = (data['title'] ?? '').toString();
    final pools = <BmTrack>[
      ...c.latestTracks,
      ...c.mostPlayed,
      ...c.libraryTracks,
    ];
    for (final t in pools) {
      if (id != null && id.isNotEmpty && t.id.toString() == id) return t;
    }
    for (final t in pools) {
      if (title.isNotEmpty && t.title == title) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1B1722) : Colors.white;
    final title = (data['title'] ?? '').toString();
    final artist =
        (data['artist'] ?? data['artist_name'] ?? data['artistName'] ?? '')
            .toString();
    final cover = (data['cover'] ?? data['cover_url'] ?? data['coverUrl'] ?? '')
        .toString();

    Widget fallback() => Container(
      color: accent.withOpacity(.15),
      child: Icon(Icons.music_note_rounded, color: accent, size: 22),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          final t = _resolve(ctrl);
          if (t != null) {
            ctrl.playTrack(t, label: 'Repris récemment');
          } else {
            Get.snackbar(
              'Titre indisponible',
              'Ce titre n\'est plus disponible.',
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: cover.isNotEmpty
                      ? Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => fallback(),
                        )
                      : fallback(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 13,
                          color: fg.withOpacity(.45),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            artist.isNotEmpty ? artist : 'Repris récemment',
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      accent,
                      Color.lerp(accent, const Color(0xFF7C3AED), .55)!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: LIVE (Gestion Streaming Audio & Vidéo OBS/HLS)
// -----------------------------------------------------------------------------
class _LiveTab extends StatelessWidget {
  final Color accent;
  final Color fg;
  const _LiveTab({required this.accent, required this.fg});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();

    return Obx(() {
      final live = ctrl.liveStream.value;
      if (live == null) {
        return RefreshIndicator(
          onRefresh: ctrl.refreshLive,
          child: ListView(
            children: const [
              SizedBox(height: 120),
              EmptyStateWidget(
                icon: Icons.podcasts_outlined,
                message: 'Pas de direct en cours pour le moment.',
              ),
            ],
          ),
        );
      }

      final state = ctrl.playbackState.value;
      final isThis = ctrl.isPlayingLive.value;
      final v = ctrl.videoPlayerController;
      final isAudio = live['media_type'] == 'audio';
      final isRadio = live['kind'] == 'radio';
      final playing = isThis && ctrl.isPlaying.value;
      final showVideo =
          isThis && v != null && v.value.isInitialized && ctrl.isVideo.value;

      return RefreshIndicator(
        onRefresh: ctrl.refreshLive,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Scène : vidéo ou visuel audio animé ──────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: showVideo
                    ? _VideoStage(key: const ValueKey('v'), ctrl: ctrl, v: v)
                    : _AudioStage(
                        key: ValueKey('a${live['id']}'),
                        accent: accent,
                        playing: playing,
                        radio: isRadio,
                        audio: isAudio,
                      ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LiveBadge(),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRadio
                              ? Icons.radio_rounded
                              : (isAudio
                                    ? Icons.headphones_rounded
                                    : Icons.videocam_rounded),
                          size: 14,
                          color: accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isRadio ? 'Radio' : (isAudio ? 'Audio' : 'Vidéo'),
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                live['title']?.toString() ?? 'Direct',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              if ((live['description'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    live['description'].toString(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg.withOpacity(.6), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (live['now_playing_title'] != null &&
                  live['now_playing_title'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.music_note_rounded, size: 16, color: accent),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          live['now_playing_title'].toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fg.withOpacity(.75),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              if (isThis && state == BmPlaybackState.loading)
                const CircularProgressIndicator()
              else if (isThis && state == BmPlaybackState.error)
                Column(
                  children: [
                    Text(
                      'Impossible de lire ce flux pour le moment.',
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: ctrl.playLive,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Réessayer'),
                    ),
                  ],
                )
              else
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: LinearGradient(
                      colors: [
                        accent,
                        Color.lerp(accent, const Color(0xFF7C3AED), .55)!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: playing ? ctrl.togglePlayPause : ctrl.playLive,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    icon: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    label: Text(
                      playing
                          ? 'Pause'
                          : (isThis ? 'Reprendre' : 'Écouter le direct'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _VideoStage extends StatelessWidget {
  final BlowMusicController ctrl;
  final VideoPlayerController v;
  const _VideoStage({super.key, required this.ctrl, required this.v});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AspectRatio(
          aspectRatio: v.value.aspectRatio > 0 ? v.value.aspectRatio : 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.black, child: VideoPlayer(v)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Color(0xAA000000), Colors.transparent],
                  ),
                ),
              ),
              Positioned(
                right: 4,
                bottom: 2,
                child: IconButton(
                  icon: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 30,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
                  ),
                  onPressed: () => ctrl.toggleFullScreen(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Visuel audio : disque dégradé + ondes animées (équaliseur) pendant la lecture.
class _AudioStage extends StatefulWidget {
  final Color accent;
  final bool playing, radio, audio;
  const _AudioStage({
    super.key,
    required this.accent,
    required this.playing,
    required this.radio,
    required this.audio,
  });

  @override
  State<_AudioStage> createState() => _AudioStageState();
}

class _AudioStageState extends State<_AudioStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.accent;
    return SizedBox(
      height: 220,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Builder(
                builder: (_) {
                  final t = widget.playing ? ((_c.value + i / 3) % 1.0) : 0.0;
                  return Opacity(
                    opacity: widget.playing ? (1 - t) * .35 : .12,
                    child: Container(
                      width: 120 + t * 100,
                      height: 120 + t * 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: a, width: 2),
                      ),
                    ),
                  );
                },
              ),
            VinylDisc(
              size: 150,
              playing: widget.playing,
              accent: a,
              fallbackIcon: widget.radio
                  ? Icons.radio_rounded
                  : (widget.audio
                        ? Icons.graphic_eq_rounded
                        : Icons.podcasts_rounded),
            ),
            // Équaliseur
            Positioned(
              bottom: 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 14; i++)
                    Container(
                      width: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: widget.playing
                          ? 6 +
                                26 *
                                    (0.5 +
                                            0.5 *
                                                math.sin(
                                                  (_c.value * 6.283 * 2) +
                                                      i * .9,
                                                ))
                                        .abs()
                          : 6,
                      decoration: BoxDecoration(
                        color: a.withOpacity(.8),
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
}

// -----------------------------------------------------------------------------
// TAB 3: BIBLIOTHÈQUE (triée A-Z, groupée par lettre, index vertical animé)
// -----------------------------------------------------------------------------
class _LibraryTab extends StatefulWidget {
  final Color accent;
  final Color fg;
  const _LibraryTab({required this.accent, required this.fg});

  @override
  State<_LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<_LibraryTab> {
  // Hauteurs fixes -> positions de scroll exactes, même avec une liste paresseuse.
  static const double _topPad = 4;
  static const double _headerH = 44;
  static const double _tileH = 74; // 66 (carte) + 8 (marge)
  static const _az = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  final ctrl = Get.find<BlowMusicController>();
  final _scroll = ScrollController();

  final _active = ValueNotifier<String>('');
  final _bubble = ValueNotifier<String?>(null);

  String _lastBubble = '';
  String? _lastTarget;
  bool _railBusy = false;

  // (lettre, offset de scroll) pour chaque section
  List<(String, double)> _sections = const [];
  List<String> _railLetters = const [];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _active.dispose();
    _bubble.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;

    // Pagination
    if (pos.pixels > pos.maxScrollExtent - 300) ctrl.loadLibrary();

    // Lettre active
    if (_railBusy || _sections.isEmpty) return;
    var current = _sections.first.$1;
    for (final s in _sections) {
      if (s.$2 <= pos.pixels + 12) {
        current = s.$1;
      } else {
        break;
      }
    }
    if (pos.maxScrollExtent > 0 && pos.pixels >= pos.maxScrollExtent - 4) {
      current = _sections.last.$1;
    }
    if (_active.value != current) _active.value = current;
  }

  /// Lettre sans titre -> on saute à la prochaine lettre disponible.
  String? _resolve(String letter) {
    if (_sections.isEmpty) return null;
    final avail = _sections.map((e) => e.$1).toList();
    if (avail.contains(letter)) return letter;
    final i = _railLetters.indexOf(letter);
    for (var k = i < 0 ? 0 : i; k < _railLetters.length; k++) {
      if (avail.contains(_railLetters[k])) return _railLetters[k];
    }
    return avail.last;
  }

  void _onPick(String letter) {
    final target = _resolve(letter);
    if (target == null) return;
    _railBusy = true;

    // Lettre au-delà de ce qui est chargé : on charge la suite du catalogue.
    if (target != letter && target == _sections.last.$1) {
      final i = _railLetters.indexOf(letter);
      final j = _railLetters.indexOf(target);
      if (i > j) ctrl.loadLibrary();
    }

    if (target == _lastTarget) return;
    _lastTarget = target;
    _bubble.value = target;
    _active.value = target;
    HapticFeedback.selectionClick();

    final off = _sections.firstWhere((e) => e.$1 == target).$2;
    if (_scroll.hasClients) {
      _scroll.animateTo(
        off.clamp(0.0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onRelease() {
    _railBusy = false;
    _lastTarget = null;
    _bubble.value = null;
  }

  Widget _letterHeader(String l, int n) {
    final accent = widget.accent;
    final fg = widget.fg;
    return SizedBox(
      height: _headerH,
      child: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: Row(
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
              '$n titre${n > 1 ? 's' : ''}',
              style: TextStyle(
                color: fg.withOpacity(.4),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.fg;
    final accent = widget.accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: TextField(
            onChanged: ctrl.searchLibrary,
            style: TextStyle(color: fg),
            decoration: InputDecoration(
              hintText: 'Rechercher un titre',
              hintStyle: TextStyle(color: fg.withOpacity(.4)),
              prefixIcon: Icon(Icons.search_rounded, color: fg.withOpacity(.5)),
              filled: true,
              fillColor: fg.withOpacity(.06),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            final list = ctrl.libraryTracks.toList();
            final loading = ctrl.libraryLoading.value;

            if (list.isEmpty) {
              return loading
                  ? const Center(child: CircularProgressIndicator())
                  : const EmptyStateWidget(
                      icon: Icons.library_music_outlined,
                      message: 'Aucun titre trouvé.',
                    );
            }

            // Tri A-Z + groupement par lettre
            final sorted = [...list]
              ..sort(
                (a, b) =>
                    _titleSortKey(a.title).compareTo(_titleSortKey(b.title)),
              );
            final counts = <String, int>{};
            for (final t in sorted) {
              final l = _letterOf(t.title);
              counts[l] = (counts[l] ?? 0) + 1;
            }

            // Liste aplatie : en-têtes (String) + titres (BmTrack)
            final flat = <Object>[];
            final sections = <(String, double)>[];
            var off = _topPad;
            String? cur;
            for (final t in sorted) {
              final l = _letterOf(t.title);
              if (l != cur) {
                cur = l;
                sections.add((l, off));
                flat.add(l);
                off += _headerH;
              }
              flat.add(t);
              off += _tileH;
            }
            _sections = sections;
            _railLetters = [..._az.split(''), if (counts.containsKey('#')) '#'];
            if (_active.value.isEmpty || !counts.containsKey(_active.value)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _onScroll();
              });
              if (_active.value.isEmpty) _active.value = sections.first.$1;
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: RefreshIndicator(
                    onRefresh: () => ctrl.loadLibrary(reset: true),
                    child: ListView.builder(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, _topPad, 30, 16),
                      itemCount: flat.length + 1,
                      itemBuilder: (_, i) {
                        if (i == flat.length) {
                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: Center(
                              child: loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }
                        final item = flat[i];
                        if (item is String) {
                          return _letterHeader(item, counts[item] ?? 0);
                        }
                        return SizedBox(
                          height: _tileH,
                          child: _TrackTile(
                            track: item as BmTrack,
                            accent: accent,
                            fg: fg,
                            queue: sorted,
                            label: 'Bibliothèque',
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Index alphabétique vertical
                Positioned(
                  right: 0,
                  top: 8,
                  bottom: 8,
                  child: SizedBox(
                    width: 30,
                    child: _AlphaRail(
                      letters: _railLetters,
                      enabled: counts.keys.toSet(),
                      active: _active,
                      onPick: _onPick,
                      onRelease: _onRelease,
                      accent: accent,
                      fg: fg,
                      isDark: isDark,
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
                                  gradient: LinearGradient(
                                    colors: [
                                      accent,
                                      Color.lerp(
                                        accent,
                                        const Color(0xFF7C3AED),
                                        .55,
                                      )!,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withOpacity(.45),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _lastBubble,
                                  style: const TextStyle(
                                    color: Colors.white,
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
          }),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 4: PLAYLISTS
// -----------------------------------------------------------------------------
class _PlaylistsTab extends StatelessWidget {
  final Color fg;
  const _PlaylistsTab({required this.fg});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();
    final accent = GPTheme.primaryColor;

    Future<void> create() async {
      final name = await bmAskName(
        context,
        title: 'Nouvelle playlist',
        action: 'Créer',
      );
      if (name == null) return;
      final p = await ctrl.createPlaylist(name);
      if (p != null && context.mounted)
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => BmPlaylistPage(playlist: p)));
    }

    return Obx(() {
      final list = ctrl.playlists.toList();
      return RefreshIndicator(
        onRefresh: () => ctrl.loadPlaylists(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: create,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      accent.withOpacity(.9),
                      Color.lerp(accent, const Color(0xFF7C3AED), .6)!,
                    ],
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.add_circle_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Créer une playlist',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (ctrl.playlistsLoading.value && list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: EmptyStateWidget(
                  icon: Icons.playlist_add_rounded,
                  message:
                      'Aucune playlist pour le moment.\nCréez la première !',
                ),
              )
            else
              ...list.map(
                (p) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.queue_music_rounded, color: accent),
                  ),
                  title: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${p.count} titre${p.count > 1 ? 's' : ''}',
                    style: TextStyle(color: fg.withOpacity(.5), fontSize: 12),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: fg.withOpacity(.6),
                    ),
                    onSelected: (v) async {
                      if (v == 'rename') {
                        final n = await bmAskName(
                          context,
                          title: 'Renommer',
                          initial: p.name,
                        );
                        if (n != null) ctrl.renamePlaylist(p, n);
                      } else if (v == 'delete') {
                        if (await bmConfirm(
                          context,
                          'Supprimer la playlist ?',
                          '« ${p.name} » sera définitivement supprimée.',
                        ))
                          ctrl.deletePlaylist(p);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Renommer')),
                      PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BmPlaylistPage(playlist: p),
                      ),
                    );
                    ctrl.playlists.refresh();
                  },
                ),
              ),
          ],
        ),
      );
    });
  }
}

// -----------------------------------------------------------------------------
// ONGLET FAVORIS : liste des titres aimés, lecture au tap, retrait (menu ou
// glissement), état vide.
// -----------------------------------------------------------------------------
class _FavoritesTab extends StatelessWidget {
  final Color accent;
  final Color fg;
  const _FavoritesTab({required this.accent, required this.fg});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();
    return Obx(() {
      final list = ctrl.favoriteTracks.toList();
      if (ctrl.favoritesLoading.value && list.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      return RefreshIndicator(
        onRefresh: () => ctrl.loadFavorites(),
        child: list.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 60),
                  EmptyStateWidget(
                    icon: Icons.favorite_border_rounded,
                    message:
                        'Aucun favori pour le moment.\nAppuyez sur le menu d\'un titre puis « Ajouter aux favoris ».',
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _SectionHeader(
                    icon: Icons.favorite_rounded,
                    title: 'Mes favoris',
                    count: list.length,
                    accent: accent,
                    fg: fg,
                  ),
                  const SizedBox(height: 12),
                  // Lecture de toute la liste dans l'ordre.
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: accent),
                      onPressed: () => ctrl.playTrack(
                        list.first,
                        queue: list,
                        label: 'Favoris',
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Tout lire'),
                    ),
                  ),
                  for (final t in list)
                    Dismissible(
                      key: ValueKey('fav_${t.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.only(right: 20),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.heart_broken_rounded,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (_) => ctrl.toggleFavorite(t),
                      child: _TrackTile(
                        track: t,
                        accent: accent,
                        fg: fg,
                        queue: list,
                        label: 'Favoris',
                      ),
                    ),
                ],
              ),
      );
    });
  }
}

// -----------------------------------------------------------------------------
// COMPOSANTS : TILE MORCEAU (carte, rang optionnel, état "en lecture" animé)
// -----------------------------------------------------------------------------
class _TrackTile extends StatelessWidget {
  final BmTrack track;
  final Color accent;
  final Color fg;
  final List<BmTrack>? queue;
  final String? label;
  final int? rank;
  const _TrackTile({
    required this.track,
    required this.accent,
    required this.fg,
    this.queue,
    this.label,
    this.rank,
  });

  Widget _coverFallback() => Container(
    color: accent.withOpacity(0.15),
    child: Icon(Icons.music_note_rounded, color: accent, size: 22),
  );

  Color? _medal() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFC107);
      case 2:
        return const Color(0xFFB0BEC5);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1B1722) : Colors.white;
    final medal = _medal();

    return Obx(() {
      final cur = ctrl.currentTrack.value?.id == track.id;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cur ? accent.withOpacity(isDark ? .16 : .09) : card,
          borderRadius: BorderRadius.circular(16),
          border: cur
              ? Border.all(color: accent.withOpacity(.5), width: 1.2)
              : (medal != null
                    ? Border.all(color: medal.withOpacity(.45), width: 1.2)
                    : null),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => ctrl.playTrack(track, queue: queue, label: label),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 2, 8),
            child: Row(
              children: [
                if (rank != null)
                  SizedBox(
                    width: 30,
                    child: medal != null
                        ? Icon(
                            Icons.workspace_premium_rounded,
                            color: medal,
                            size: 26,
                          )
                        : Text(
                            '$rank',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: fg.withOpacity(.45),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                  ),
                if (rank != null) const SizedBox(width: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        (track.coverUrl != null && track.coverUrl!.isNotEmpty)
                            ? Image.network(
                                track.coverUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _coverFallback(),
                              )
                            : _coverFallback(),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: cur ? 1 : 0,
                          child: Container(
                            color: Colors.black54,
                            child: Icon(
                              ctrl.isPlaying.value
                                  ? Icons.equalizer_rounded
                                  : Icons.pause_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cur ? accent : fg,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (track.artistName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          track.artistName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fg.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: fg.withOpacity(.55),
                  ),
                  onSelected: (v) {
                    if (v == 'fav') ctrl.toggleFavorite(track);
                    if (v == 'pl') bmAddToPlaylistSheet(context, track);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'fav',
                      child: Text(
                        ctrl.favoriteIds.contains(track.id)
                            ? 'Retirer des favoris'
                            : 'Ajouter aux favoris',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'pl',
                      child: Text('Ajouter à une playlist'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// -----------------------------------------------------------------------------
// COMPOSANTS : MINI PLAYER AVEC BARRE DE PROGRESSION
// -----------------------------------------------------------------------------
class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();

    return Obx(() {
      final track = ctrl.currentTrack.value;
      final showLive =
          ctrl.isPlayingLive.value && ctrl.liveStream.value != null;

      if (track == null && !showLive) return const SizedBox.shrink();

      final label =
          track?.title ??
          ctrl.liveStream.value?['title']?.toString() ??
          'Direct';
      final subtitle = track?.artistName ?? (showLive ? 'En Direct' : '');

      return GestureDetector(
        onTap: () => showLive ? ctrl.changeTab(1) : openBmPlayer(context),
        child: Container(
          decoration: BoxDecoration(
            color: GPTheme.primaryColor.withOpacity(0.12),
            border: Border(
              top: BorderSide(color: GPTheme.primaryColor.withOpacity(0.2)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barre de progression si c'est un morceau enregistré (non-Live)
              if (!showLive && ctrl.duration.value.inSeconds > 0)
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 4,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 8,
                    ),
                    activeTrackColor: GPTheme.primaryColor,
                    inactiveTrackColor: Colors.grey.withOpacity(0.3),
                    thumbColor: GPTheme.primaryColor,
                  ),
                  child: Slider(
                    value: ctrl.position.value.inSeconds.toDouble().clamp(
                      0.0,
                      ctrl.duration.value.inSeconds.toDouble(),
                    ),
                    max: ctrl.duration.value.inSeconds.toDouble(),
                    onChanged: (val) =>
                        ctrl.seekTo(Duration(seconds: val.toInt())),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child:
                            (track?.coverUrl != null &&
                                track!.coverUrl!.isNotEmpty)
                            ? Image.network(
                                track.coverUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.music_note_rounded,
                                  color: GPTheme.primaryColor,
                                ),
                              )
                            : Container(
                                color: GPTheme.primaryColor.withOpacity(.15),
                                child: Icon(
                                  showLive
                                      ? Icons.podcasts_rounded
                                      : Icons.music_note_rounded,
                                  color: GPTheme.primaryColor,
                                  size: 22,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (ctrl.playbackState.value == BmPlaybackState.loading)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          ctrl.isPlaying.value
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 32,
                          color: GPTheme.primaryColor,
                        ),
                        onPressed: ctrl.togglePlayPause,
                      ),
                    if (!showLive && ctrl.queue.length > 1)
                      IconButton(
                        icon: Icon(
                          Icons.skip_next_rounded,
                          size: 28,
                          color: GPTheme.primaryColor,
                        ),
                        onPressed: () => ctrl.next(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
