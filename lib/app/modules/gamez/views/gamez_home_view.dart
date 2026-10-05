// lib/app/modules/gamez/views/gamez_home_view.dart
//
// Coquille GameZ : or (GPTheme.clubColor), drawer partagé, 3 onglets
// (Jeux, Mon profil GCoin, Classement). Theme-aware, états vides gérés.

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/empty_state_widget.dart';
import 'package:grand_public_v2/app/components/module_drawer.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

import '../controllers/gamez_controller.dart';
import 'gamez_game_view.dart';

class GameZHomeView extends GetView<GameZController> {
  const GameZHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = GPTheme.clubColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111014) : const Color(0xFFF7F5F0);
    final fg = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bg,
      drawer: ModuleDrawer(
        accentColor: accent,
        moduleName: 'GameZ',
        moduleLogo: LOGO_GAMEZ,
        variableItems: [
          ModuleDrawerNavItem(title: 'Jeux', icon: Icons.grid_view_rounded, onTap: () => controller.changeTab(0)),
          ModuleDrawerNavItem(title: 'GCoin', icon: Icons.monetization_on_outlined, onTap: () => controller.changeTab(1)),
          ModuleDrawerNavItem(title: 'Classement', icon: Icons.leaderboard_rounded, onTap: () => controller.changeTab(2)),
        ],
      ),
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              LOGO_GAMEZ_NAV,
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
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'GameZ',
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.currentTab.value == 0) {
          return const Center(child: CircularProgressIndicator());
        }
        switch (controller.currentTab.value) {
          case 1:
            return _ProfileTab(accent: accent, fg: fg);
          case 2:
            return _LeaderboardTab(accent: accent, fg: fg);
          default:
            return _CatalogTab(accent: accent, fg: fg);
        }
      }),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          backgroundColor: bg,
          selectedItemColor: accent,
          unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
          currentIndex: controller.currentTab.value,
          onTap: controller.changeTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Jeux',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monetization_on_outlined),
              label: 'GCoin',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_rounded),
              label: 'Classement',
            ),
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
        gradient: LinearGradient(colors: [g.accent, Color.lerp(g.accent, Colors.black, .35)!], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(size * .3),
        boxShadow: [BoxShadow(color: g.accent.withOpacity(.35), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Center(child: FaIcon(gzIcon(g.icon) as FaIconData?, color: Colors.white, size: size * .42)),
    );

void playGame(GzGame g) => Get.to(() => GameZGameView(game: g), transition: Transition.downToUp);

// ─────────────────────────────────────────────────────────────────────────────
// ONGLET JEUX : récents (relançables) + catalogue
// ─────────────────────────────────────────────────────────────────────────────
class _CatalogTab extends StatelessWidget {
  final Color accent;
  final Color fg;
  const _CatalogTab({required this.accent, required this.fg});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<GameZController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1B1A22) : Colors.white;

    return Obx(() {
      if (c.hasError.value) {
        return RefreshIndicator(
          onRefresh: c.refreshAll,
          child: ListView(children: const [EmptyStateWidget(icon: Icons.wifi_off_rounded, message: 'Impossible de charger les jeux.\nTirez pour réessayer.')]),
        );
      }
      if (c.catalog.isEmpty) {
        return RefreshIndicator(
          onRefresh: c.refreshAll,
          child: ListView(children: const [EmptyStateWidget(icon: Icons.sports_esports_outlined, message: 'Aucun jeu disponible pour le moment.')]),
        );
      }
      final byId = {for (final g in c.catalog) g.id: g};

      return RefreshIndicator(
        onRefresh: c.refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (c.recent.isNotEmpty) ...[
              _title('Parties récentes', Icons.history_rounded, fg, accent),
              const SizedBox(height: 10),
              ...c.recent.map((r) {
                final raw = r['game'];
                final g = raw is Map ? (byId[GzGame.fromJson(Map<String, dynamic>.from(raw)).id] ?? GzGame.fromJson(Map<String, dynamic>.from(raw))) : null;
                if (g == null) return const SizedBox.shrink();
                final playable = r['is_playable'] == true;
                return _RecentTile(game: g, data: r, playable: playable, card: card, fg: fg);
              }),
              const SizedBox(height: 22),
            ],
            _title('Tous les jeux', Icons.grid_view_rounded, fg, accent),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: c.catalog.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .98),
              itemBuilder: (_, i) => _GameCard(game: c.catalog[i], card: card, fg: fg),
            ),
          ],
        ),
      );
    });
  }
}

Widget _title(String t, IconData i, Color fg, Color accent) => Row(children: [
      Icon(i, size: 20, color: accent),
      const SizedBox(width: 8),
      Text(t, style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.w800)),
    ]);

class _GameCard extends StatelessWidget {
  final GzGame game;
  final Color card, fg;
  const _GameCard({required this.game, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showGameSheet(context, game),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _gameBadge(game, size: 52),
            const Spacer(),
            Text(game.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.emoji_events_rounded, size: 14, color: game.accent),
              const SizedBox(width: 4),
              Text(game.myBest > 0 ? 'Record ${game.myBest}' : 'Pas encore joué', style: TextStyle(color: fg.withOpacity(.55), fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final GzGame game;
  final Map<String, dynamic> data;
  final bool playable;
  final Color card, fg;
  const _RecentTile({required this.game, required this.data, required this.playable, required this.card, required this.fg});

  @override
  Widget build(BuildContext context) {
    final last = data['last_score'];
    return Opacity(
      opacity: playable ? 1 : .5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: playable ? () => playGame(game) : () => Get.snackbar('Jeu en pause', 'Ce jeu est momentanément indisponible.'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              _gameBadge(game, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(game.name, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text('${ago(data['last_played_at'])} · ${data['sessions']} partie${(data['sessions'] ?? 0) > 1 ? 's' : ''} · ${fmtDuration((data['total_duration_seconds'] ?? 0) as int)}',
                      style: TextStyle(color: fg.withOpacity(.55), fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(children: [
                    _mini(Icons.emoji_events_rounded, '${data['best_score']}', game.accent),
                    if (last != null) ...[const SizedBox(width: 12), _mini(Icons.flag_rounded, '$last', fg.withOpacity(.6))],
                    if (data['last_level'] != null) ...[const SizedBox(width: 12), _mini(Icons.tune_rounded, '${data['last_level']}', fg.withOpacity(.6))],
                  ]),
                ]),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: playable ? game.accent : Colors.grey, shape: BoxShape.circle),
                child: Icon(playable ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.white),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _mini(IconData i, String t, Color c) => Row(children: [
        Icon(i, size: 13, color: c),
        const SizedBox(width: 3),
        Text(t, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
      ]);
}

/// Fiche d'un jeu : statistiques personnelles + top 10 + bouton Jouer.
void _showGameSheet(BuildContext context, GzGame g) {
  final c = Get.find<GameZController>();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final fg = isDark ? Colors.white : Colors.black87;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF16151C) : Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
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
          return ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(20, 14, 20, 28), children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(.4), borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 18),
            Row(children: [
              _gameBadge(g, size: 62),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g.name, style: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.w900)),
                  if ((g.description ?? '').isNotEmpty) Text(g.description!, style: TextStyle(color: fg.withOpacity(.6), fontSize: 13)),
                ]),
              ),
            ]),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  playGame(g);
                },
                style: ElevatedButton.styleFrom(backgroundColor: g.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text('Jouer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
            if (snap.connectionState != ConnectionState.done)
              const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
            else if (d == null)
              Text('Statistiques indisponibles.', style: TextStyle(color: fg.withOpacity(.5)))
            else ...[
              Wrap(spacing: 10, runSpacing: 10, children: [
                _stat('Record', '${mine?['best_score'] ?? 0}', Icons.emoji_events_rounded, g.accent, fg, isDark),
                _stat('Moyenne', '${mine?['avg_score'] ?? 0}', Icons.show_chart_rounded, g.accent, fg, isDark),
                _stat('Parties', '${mine?['plays'] ?? 0}', Icons.sports_esports_rounded, g.accent, fg, isDark),
                _stat('Temps de jeu', fmtDuration((mine?['total_duration_seconds'] ?? 0) as int), Icons.timer_rounded, g.accent, fg, isDark),
                _stat('Mon rang', mine?['rank'] != null ? '#${mine!['rank']}' : '—', Icons.leaderboard_rounded, g.accent, fg, isDark),
                _stat('GCoin gagnés', '${mine?['gcoin_earned'] ?? 0}', Icons.toll_rounded, g.accent, fg, isDark),
              ]),
              if (top.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text('Top joueurs', style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                ...top.take(5).map((r) => _LbRow(row: Map<String, dynamic>.from(r), game: true, fg: fg, isDark: isDark, accent: g.accent)),
              ],
              if (hist.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text('Mes dernières parties', style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                ...hist.take(8).map((h) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.flag_rounded, color: g.accent, size: 20),
                      title: Text('${h['score']} pts${h['level'] != null ? ' · ${h['level']}' : ''}', style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
                      subtitle: Text('${ago(h['created_at'])} · ${fmtDuration((h['duration_seconds'] ?? 0) as int)}', style: TextStyle(color: fg.withOpacity(.5), fontSize: 12)),
                    )),
              ],
            ],
          ]);
        },
      ),
    ),
  );
}

Widget _stat(String l, String v, IconData i, Color a, Color fg, bool dark) => Container(
      width: 104,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: dark ? const Color(0xFF211F29) : const Color(0xFFF4F2EC), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(i, size: 18, color: a),
        const SizedBox(height: 6),
        Text(v, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 18)),
        Text(l, style: TextStyle(color: fg.withOpacity(.55), fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
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
    final c = Get.find<GameZController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1B1A22) : Colors.white;

    return Obx(() => RefreshIndicator(
          onRefresh: c.loadGcoin,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 28), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(colors: [accent, const Color(0xFFF59E0B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [BoxShadow(color: accent.withOpacity(.35), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Icon(Icons.toll_rounded, color: Colors.black87), SizedBox(width: 8), Text('Mon solde GCoin', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: c.gcoinBalance.value.toDouble()),
                  duration: const Duration(milliseconds: 700),
                  builder: (_, v, __) => Text('${v.round()}', style: const TextStyle(color: Colors.black, fontSize: 44, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  _pill(Icons.south_west_rounded, '${c.totalEarned.value} gagnés'),
                  const SizedBox(width: 8),
                  _pill(Icons.north_east_rounded, '${c.totalSpent.value} dépensés'),
                ]),
              ]),
            ),
            if (c.gcoinPerGame.isNotEmpty) ...[
              const SizedBox(height: 22),
              _title('Gains par jeu', Icons.sports_esports_rounded, fg, accent),
              const SizedBox(height: 10),
              ...c.gcoinPerGame.map((r) {
                final g = r['game'] as Map<String, dynamic>;
                final gg = GzGame.fromJson(g);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    _gameBadge(gg, size: 38),
                    const SizedBox(width: 12),
                    Expanded(child: Text(gg.name, style: TextStyle(color: fg, fontWeight: FontWeight.w700))),
                    Text('+${r['total']}', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w900, fontSize: 16)),
                  ]),
                );
              }),
            ],
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: _title('Historique', Icons.receipt_long_rounded, fg, accent)),
              for (final f in const [('', 'Tout'), ('earned', 'Gains'), ('spent', 'Dépenses')])
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoiceChip(
                    label: Text(f.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.historyType.value == f.$1 ? Colors.black : fg)),
                    selected: c.historyType.value == f.$1,
                    selectedColor: accent,
                    onSelected: (_) => c.setHistoryType(f.$1),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ]),
            const SizedBox(height: 10),
            if (c.historyLoading.value && c.gcoinHistory.isEmpty)
              const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
            else if (c.gcoinHistory.isEmpty)
              const EmptyStateWidget(icon: Icons.receipt_long_outlined, message: 'Aucune transaction pour le moment.\nJouez pour gagner des GCoin !', minHeight: 220)
            else
              ...c.gcoinHistory.map((t) {
                final amt = (t['amount'] ?? 0) as int;
                final pos = amt >= 0;
                final game = t['game'] is Map ? GzGame.fromJson(Map<String, dynamic>.from(t['game'])) : null;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    game != null
                        ? _gameBadge(game, size: 40)
                        : Container(width: 40, height: 40, decoration: BoxDecoration(color: (pos ? Colors.green : Colors.red).withOpacity(.12), shape: BoxShape.circle), child: Icon(pos ? Icons.add_rounded : Icons.remove_rounded, color: pos ? Colors.green : Colors.red)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(game != null ? '${game.name}${t['score'] != null ? ' · ${t['score']} pts' : ''}' : '${t['label']}', style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('${t['label']} · ${ago(t['created_at'])}', style: TextStyle(color: fg.withOpacity(.5), fontSize: 12)),
                      ]),
                    ),
                    Text('${pos ? '+' : ''}$amt', style: TextStyle(color: pos ? const Color(0xFF16A34A) : Colors.red, fontWeight: FontWeight.w900, fontSize: 17)),
                  ]),
                );
              }),
          ]),
        ));
  }

  Widget _pill(IconData i, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(i, size: 14, color: Colors.black87), const SizedBox(width: 4), Text(t, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w700))]),
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
    final c = Get.find<GameZController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isGame = c.lbGame.value.isNotEmpty;
      return RefreshIndicator(
        onRefresh: c.loadLeaderboard,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 28), children: [
          SizedBox(
            height: 40,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              _chip('Général', c.lbGame.value.isEmpty, () => c.setLbGame(''), accent, fg),
              ...c.catalog.map((g) => _chip(g.name, c.lbGame.value == g.slug, () => c.setLbGame(g.slug), g.accent, fg)),
            ]),
          ),
          const SizedBox(height: 10),
          Row(children: [
            for (final p in const [('all', 'Tout temps'), ('monthly', 'Ce mois'), ('weekly', 'Cette semaine')])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(p.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.lbPeriod.value == p.$1 ? Colors.black : fg)),
                  selected: c.lbPeriod.value == p.$1,
                  selectedColor: accent,
                  onSelected: (_) => c.setLbPeriod(p.$1),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ]),
          const SizedBox(height: 14),
          if (c.lbMe.value != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(colors: [accent.withOpacity(.9), const Color(0xFFF59E0B)]),
              ),
              child: Row(children: [
                Text('#${c.lbMe.value!['rank']}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Votre position', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800)),
                    Text('sur ${c.lbTotal.value} joueur${c.lbTotal.value > 1 ? 's' : ''}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ]),
                ),
                Text(isGame ? '${c.lbMe.value!['best_score']} pts' : '${c.lbMe.value!['points']} pts', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
              ]),
            ),
            const SizedBox(height: 14),
          ],
          if (c.lbLoading.value && c.lbRows.isEmpty)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (c.lbRows.isEmpty)
            const EmptyStateWidget(icon: Icons.leaderboard_outlined, message: 'Aucun score pour cette période.\nSoyez le premier !', minHeight: 260)
          else
            ...c.lbRows.map((r) => _LbRow(row: r, game: isGame, fg: fg, isDark: isDark, accent: accent)),
        ]),
      );
    });
  }

  Widget _chip(String t, bool on, VoidCallback f, Color a, Color fg) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(t, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: on ? Colors.black : fg)),
          selected: on,
          selectedColor: a,
          onSelected: (_) => f(),
        ),
      );
}

class _LbRow extends StatefulWidget {
  final Map<String, dynamic> row;
  final bool game, isDark;
  final Color fg, accent;
  const _LbRow({required this.row, required this.game, required this.fg, required this.isDark, required this.accent});

  @override
  State<_LbRow> createState() => _LbRowState();
}

class _LbRowState extends State<_LbRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    final rank = (r['rank'] ?? 0) as int;
    final medal = rank == 1 ? const Color(0xFFFFC107) : rank == 2 ? const Color(0xFFB0BEC5) : rank == 3 ? const Color(0xFFCD7F32) : null;
    final avatar = r['avatar_url']?.toString();

    final details = widget.game
        ? <(IconData, String)>[
            (Icons.tune_rounded, r['level'] != null ? 'Niveau ${r['level']}' : 'Niveau —'),
            (Icons.timer_rounded, 'Durée ${fmtDuration((r['duration_seconds'] ?? 0) as int)}'),
            (Icons.event_rounded, 'Le ${ago(r['achieved_at'])}'),
            (Icons.sports_esports_rounded, '${r['plays']} parties'),
            (Icons.show_chart_rounded, 'Moyenne ${r['avg_score']}'),
            (Icons.hourglass_bottom_rounded, 'Total ${fmtDuration((r['total_duration_seconds'] ?? 0) as int)}'),
          ]
        : <(IconData, String)>[
            (Icons.grid_view_rounded, '${r['games_played']} jeux joués'),
            (Icons.sports_esports_rounded, '${r['plays']} parties'),
            (Icons.timer_rounded, fmtDuration((r['total_duration_seconds'] ?? 0) as int)),
            (Icons.event_rounded, 'Dernière : ${ago(r['last_played_at'])}'),
          ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1B1A22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: medal != null ? Border.all(color: medal.withOpacity(.6), width: 1.4) : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
              SizedBox(
                width: 34,
                child: medal != null ? Icon(Icons.workspace_premium_rounded, color: medal, size: 28) : Text('$rank', textAlign: TextAlign.center, style: TextStyle(color: widget.fg.withOpacity(.5), fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: widget.accent.withOpacity(.25),
                backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                child: avatar == null || avatar.isEmpty ? Text('${r['name'] ?? '?'}'.characters.first.toUpperCase(), style: TextStyle(color: widget.fg, fontWeight: FontWeight.w800)) : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('${r['name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: widget.fg, fontWeight: FontWeight.w800, fontSize: 15))),
              Text(widget.game ? '${r['best_score']}' : '${r['points']}', style: TextStyle(color: widget.accent, fontWeight: FontWeight.w900, fontSize: 18)),
              Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: widget.fg.withOpacity(.4)),
            ]),
            if (_open)
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 4),
                child: Wrap(spacing: 14, runSpacing: 8, children: [
                  for (final d in details)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(d.$1, size: 14, color: widget.fg.withOpacity(.5)),
                      const SizedBox(width: 4),
                      Text(d.$2, style: TextStyle(color: widget.fg.withOpacity(.7), fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}
