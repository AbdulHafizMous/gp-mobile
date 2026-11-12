// Championnats / tournois Youwiiin : liste, fiche (tableau à élimination ou classements par tour), inscription, jeu.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/api_error_helper.dart';
import 'package:grand_public_v2/app/utils/share_helper.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/youwiiin_controller.dart';
import '../widgets/youwiiin_style.dart';
import 'youwiiin_game_view.dart';
import 'youwiiin_tournament_create.dart';

int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
String _unit(String c) => c == 'cash' ? 'F' : 'GCoin';

String _feeLabel(Map t) => t['currency'] == 'free' ? 'Gratuit' : '${t['entry_fee']} ${_unit(t['currency'])}';

class YouwiiinTournamentsView extends StatefulWidget {
  /// true : ouvert sous l'en-tête Youwiiin (overlay du module) -> pas de 2e AppBar.
  final bool embedded;
  const YouwiiinTournamentsView({super.key, this.embedded = false});

  @override
  State<YouwiiinTournamentsView> createState() => _YouwiiinTournamentsViewState();
}

class _YouwiiinTournamentsViewState extends State<YouwiiinTournamentsView> {
  String _status = 'open';
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await RequestService().get('/gamez/tournaments', queryParameters: {'status': _status});
      _items = List<Map<String, dynamic>>.from((r.data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final st = YwStyle.of(context);
    return Scaffold(
      backgroundColor: st.bg,
      appBar: widget.embedded ? null : AppBar(backgroundColor: st.bg, elevation: 0, foregroundColor: st.fg, iconTheme: IconThemeData(color: st.fg), title: const Text('Tournois', style: TextStyle(fontWeight: FontWeight.w900))),
      body: Column(children: [
        if (widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Align(alignment: Alignment.centerLeft, child: Text('Tournois', style: TextStyle(color: st.fg, fontSize: 20, fontWeight: FontWeight.w900))),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
          child: Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final id = await showCreateTournamentSheet(context);
                  if (id != null) {
                    await Get.to(() => YouwiiinTournamentDetailView(id: id));
                    _load();
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Organiser', style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(backgroundColor: st.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final id = await askTournamentCode(context);
                if (id != null) {
                  await Get.to(() => YouwiiinTournamentDetailView(id: id));
                  _load();
                }
              },
              icon: const Icon(Icons.vpn_key_rounded, size: 18),
              label: const Text('Code'),
              style: OutlinedButton.styleFrom(foregroundColor: st.fg, side: BorderSide(color: st.sub.withValues(alpha: .5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ]),
        ),
        SizedBox(
          height: 52,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), children: [
            for (final f in const [('open', 'Inscriptions'), ('running', 'En cours'), ('mine', 'Les miens'), ('finished', 'Terminés')]) ...[
              YwChoiceChip(label: f.$2, selected: _status == f.$1, onTap: () {
                _status = f.$1;
                _load();
              }),
              const SizedBox(width: 8),
            ],
          ]),
        ),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: st.accent))
              : _items.isEmpty
              ? Center(child: Text('Aucun tournoi ici pour le moment.', style: TextStyle(color: st.sub)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _TournamentCard(t: _items[i], onTap: () async {
                      await Get.to(() => YouwiiinTournamentDetailView(id: _i(_items[i]['id'])));
                      _load();
                    }),
                  ),
                ),
        ),
      ]),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final Map<String, dynamic> t;
  final VoidCallback onTap;
  const _TournamentCard({required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final st = YwStyle.of(context);
    final bracket = t['format'] == 'bracket';
    final grad = bracket ? const [Color(0xFF7C3AED), Color(0xFFDB2777)] : const [Color(0xFF0EA5E9), Color(0xFF16A34A)];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: st.card, borderRadius: BorderRadius.circular(YwStyle.rCard)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(gradient: LinearGradient(colors: grad)),
            child: Row(children: [
              Icon(bracket ? Icons.account_tree_rounded : Icons.format_list_numbered_rounded, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              Expanded(child: Text('${t['title']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
              _StatusChip(status: '${t['status']}'),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(spacing: 14, runSpacing: 8, children: [
              _info(st, Icons.groups_rounded, '${t['players_count']}/${t['max_players']} joueurs'),
              _info(st, Icons.confirmation_number_rounded, 'Entrée : ${_feeLabel(t)}'),
              _info(st, Icons.emoji_events_rounded, 'Cagnotte : ${t['pot']} ${t['currency'] == 'free' ? 'GCoin' : _unit('${t['currency']}')}'),
              _info(st, bracket ? Icons.bolt_rounded : Icons.layers_rounded, bracket ? 'Élimination directe' : '${t['rounds_total']} tour(s)'),
              if (t['joined'] == true) _info(st, Icons.check_circle_rounded, 'Inscrit', color: YwStyle.ok),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _info(YwStyle st, IconData i, String s, {Color? color}) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(i, size: 16, color: color ?? st.sub),
    const SizedBox(width: 5),
    Text(s, style: TextStyle(color: color ?? st.fg, fontSize: 12.5, fontWeight: FontWeight.w600)),
  ]);
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final m = {'registration': 'Inscriptions', 'running': 'En cours', 'finished': 'Terminé', 'cancelled': 'Annulé'};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
      child: Text(m[status] ?? status, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
    );
  }
}

// ═════════════════════════ Fiche tournoi ═════════════════════════

class YouwiiinTournamentDetailView extends StatefulWidget {
  final int id;
  const YouwiiinTournamentDetailView({super.key, required this.id});

  @override
  State<YouwiiinTournamentDetailView> createState() => _YouwiiinTournamentDetailViewState();
}

class _YouwiiinTournamentDetailViewState extends State<YouwiiinTournamentDetailView> {
  Map<String, dynamic>? _t;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await RequestService().get('/gamez/tournaments/${widget.id}');
      _t = Map<String, dynamic>.from(r.data['data']);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _act(String path, String ok) async {
    setState(() => _busy = true);
    try {
      final r = await RequestService().post('/gamez/tournaments/${widget.id}/$path');
      _t = Map<String, dynamic>.from(r.data['data']);
      gzController.loadMe();
      Get.snackbar(ok, '');
    } on DioException catch (e) {
      Get.snackbar('Impossible', ApiErrorHelper.messageFor(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _playRound() async {
    final t = _t!;
    final gid = _i(t['current_game_id']);
    if (gzController.catalog.isEmpty) await gzController.loadHome();
    final g = gzController.catalog.firstWhereOrNull((x) => x.id == gid);
    if (g == null) {
      Get.snackbar('Jeu introuvable', 'Réessaie dans un instant.');
      return;
    }
    await Get.to(() => YouwiiinGameView(game: g, tournamentId: widget.id), transition: Transition.downToUp);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final st = YwStyle.of(context);
    final t = _t;
    return Scaffold(
      backgroundColor: st.bg,
      appBar: AppBar(
        backgroundColor: st.bg,
        elevation: 0,
        foregroundColor: st.fg,
        iconTheme: IconThemeData(color: st.fg),
        actionsIconTheme: IconThemeData(color: st.fg),
        title: Text(t?['title'] ?? 'Tournoi', style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (t != null)
            IconButton(
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () => ShareHelper.showShareSheet(context, title: '${t['title']}', subtitle: 'Tournoi Youwiiin', type: 'tournament', id: '${t['id']}'),
            ),
        ],
      ),
      body: t == null
          ? Center(child: CircularProgressIndicator(color: st.accent))
          : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: _body(st, t))),
    );
  }

  List<Widget> _body(YwStyle st, Map<String, dynamic> t) {
    final bracket = t['format'] == 'bracket';
    final status = '${t['status']}';
    final split = (t['prize_split'] as List?)?.map(_i).toList() ?? [];
    final w = <Widget>[
      _TournamentCard(t: t, onTap: () {}),
      if ('${t['invite_code'] ?? ''}'.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: InkWell(
            onTap: () => SharePlus.instance.share(ShareParams(text: "Rejoins mon tournoi « ${t['title']} » sur Youwiiin avec le code ${t['invite_code']}")),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: st.accent.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(Icons.vpn_key_rounded, color: st.accent, size: 18),
                const SizedBox(width: 8),
                Text('Code d\'invitation : ${t['invite_code']}', style: TextStyle(color: st.fg, fontWeight: FontWeight.w800)),
                const Spacer(),
                Icon(Icons.share_rounded, color: st.accent, size: 18),
              ]),
            ),
          ),
        ),
      if ((t['description'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 14), child: Text('${t['description']}', style: TextStyle(color: st.sub, height: 1.4))),
      if (t['winner'] != null)
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: .15), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Text('🏆', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Text('Champion : ${t['winner']['name']}', style: TextStyle(color: st.fg, fontWeight: FontWeight.w900, fontSize: 16))),
          ]),
        ),
    ];

    // Action principale
    if (status == 'registration') {
      if (t['joined'] == true) {
        w.add(YwButton(label: 'Se désinscrire (remboursé)', icon: Icons.logout_rounded, outlined: true, busy: _busy, onTap: () => _act('leave', 'Désinscrit')));
        w.add(Padding(padding: const EdgeInsets.only(top: 8), child: Text('Démarre quand ${t['max_players']} joueurs sont inscrits${t['starts_at'] != null ? ' ou à la date prévue' : ''}.', style: TextStyle(color: st.sub, fontSize: 12.5))));
      } else if (t['can_join'] == true) {
        w.add(YwButton(label: t['currency'] == 'free' ? 'Participer gratuitement' : 'S\'inscrire · ${_feeLabel(t)}', icon: Icons.how_to_reg_rounded, busy: _busy, onTap: () => _act('join', 'Inscription confirmée 🎉')));
      }
    } else if (status == 'running' && t['joined'] == true && t['my_status'] != 'eliminated') {
      if (bracket) {
        final m = t['my_next_match'];
        w.add(YwButton(
          label: m != null && m['room_code'] != null ? 'Ouvrir mon match' : 'En attente de l\'adversaire…',
          icon: Icons.sports_esports_rounded,
          onTap: m != null && m['room_code'] != null ? () => Get.toNamed('/youwiiin/room/${m['room_code']}') : null,
        ));
      } else {
        w.add(YwButton(label: 'Jouer le tour ${t['current_round']}/${t['rounds_total']}', icon: Icons.play_arrow_rounded, onTap: _playRound));
        w.add(Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Ton meilleur score ce tour : ${t['my_round_score'] ?? 0}. Fin du tour : ${_fmtDate(t['round_ends_at'])}.', style: TextStyle(color: st.sub, fontSize: 12.5)),
        ));
      }
    } else if (t['my_status'] == 'eliminated') {
      w.add(Text('Tu es éliminé — classement final : ${t['my_rank'] ?? '—'}e.', style: TextStyle(color: st.sub)));
    }
    if (_i(t['my_prize']) > 0) {
      w.add(Padding(padding: const EdgeInsets.only(top: 10), child: Text('🎉 Gain : ${t['my_prize']} ${_unit('${t['currency']}')}', style: const TextStyle(color: YwStyle.ok, fontWeight: FontWeight.w900, fontSize: 15))));
    }

    if (split.isNotEmpty) {
      w.addAll([
        const SizedBox(height: 20),
        Text('Répartition des gains', style: TextStyle(color: st.fg, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [for (var i = 0; i < split.length; i++) Chip(label: Text('${i + 1}${i == 0 ? 'er' : 'e'} · ${split[i]} %'))]),
      ]);
    }

    // Tableau (bracket)
    if (bracket && t['bracket'] is List) {
      w.addAll([const SizedBox(height: 20), Text('Tableau', style: TextStyle(color: st.fg, fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 8)]);
      for (final r in t['bracket'] as List) {
        w.add(Padding(padding: const EdgeInsets.only(top: 10, bottom: 6), child: Text('${r['label']}', style: TextStyle(color: st.accent, fontWeight: FontWeight.w900))));
        for (final m in r['matches'] as List) {
          w.add(_MatchTile(m: Map<String, dynamic>.from(m)));
        }
      }
    }

    // Classements par tour (rounds)
    if (!bracket && t['rounds'] is List) {
      w.add(const SizedBox(height: 20));
      for (final r in (t['rounds'] as List).reversed) {
        w.add(Text('Tour ${r['round']}', style: TextStyle(color: st.fg, fontWeight: FontWeight.w900, fontSize: 16)));
        w.add(const SizedBox(height: 6));
        for (final s in r['scores'] as List) {
          w.add(ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(radius: 14, backgroundColor: st.faint, child: Text('${s['rank']}', style: TextStyle(color: st.fg, fontSize: 12, fontWeight: FontWeight.w900))),
            title: Text('${s['name']}', style: TextStyle(color: st.fg)),
            trailing: Text('${s['score']} pts · +${s['points']}', style: TextStyle(color: st.sub, fontSize: 12)),
          ));
        }
        w.add(const SizedBox(height: 10));
      }
    }

    // Participants / classement général
    final players = (t['players'] as List?) ?? [];
    if (players.isNotEmpty) {
      w.addAll([const SizedBox(height: 14), Text(bracket ? 'Participants' : 'Classement général', style: TextStyle(color: st.fg, fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 6)]);
      for (final p in players) {
        final elim = p['status'] == 'eliminated';
        w.add(ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(radius: 16, backgroundImage: p['avatar_url'] != null ? NetworkImage(p['avatar_url']) : null, child: p['avatar_url'] == null ? Text('${p['name'] ?? '?'}'.substring(0, 1)) : null),
          title: Text('${p['name']}', style: TextStyle(color: elim ? st.sub : st.fg, decoration: elim ? TextDecoration.lineThrough : null)),
          trailing: Text(bracket ? (p['rank'] != null ? '${p['rank']}e' : '') : '${p['points']} pts', style: TextStyle(color: st.sub, fontWeight: FontWeight.w700)),
        ));
      }
    }
    return w;
  }

  String _fmtDate(dynamic iso) {
    final d = DateTime.tryParse('$iso')?.toLocal();
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _MatchTile extends StatelessWidget {
  final Map<String, dynamic> m;
  const _MatchTile({required this.m});

  @override
  Widget build(BuildContext context) {
    final st = YwStyle.of(context);
    Widget side(Map? p, bool win) => Expanded(
      child: Text(p == null ? '— (bye)' : '${p['name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: win ? YwStyle.ok : st.fg, fontWeight: win ? FontWeight.w900 : FontWeight.w600)),
    );
    final wid = m['winner_id'];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: st.card, borderRadius: BorderRadius.circular(14), border: m['mine'] == true ? Border.all(color: st.accent, width: 1.5) : null),
      child: Row(children: [
        side(m['a'] as Map?, wid != null && m['a'] != null && m['a']['id'] == wid),
        Text('  vs  ', style: TextStyle(color: st.sub, fontSize: 12)),
        side(m['b'] as Map?, wid != null && m['b'] != null && m['b']['id'] == wid),
        if (m['status'] == 'playing') const Icon(Icons.sports_esports_rounded, size: 16, color: YwStyle.warn),
      ]),
    );
  }
}
