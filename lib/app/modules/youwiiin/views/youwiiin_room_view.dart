// lib/app/modules/youwiiin/views/youwiiin_room_view.dart
//
// Lobby d'une salle multijoueur : /youwiiin/room/:code
// Polling ~2 s (joueurs, statuts, pot). Hôte : Lancer / Inviter / Annuler ;
// invité : Accepter / Refuser ; joueur : Quitter. À `playing`, ouvre la
// vue de jeu (WebView) en mode multijoueur.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

import '../controllers/youwiiin_controller.dart';
import '../widgets/youwiiin_player_picker.dart';
import 'youwiiin_game_view.dart';
import 'youwiiin_home_view.dart' show gzIcon;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class YouwiiinRoomView extends StatefulWidget {
  const YouwiiinRoomView({super.key});

  @override
  State<YouwiiinRoomView> createState() => _YouwiiinRoomViewState();
}

class _YouwiiinRoomViewState extends State<YouwiiinRoomView> {
  final _c = Get.find<YouwiiinController>();
  late final String _code = Get.parameters['code'] ?? '';
  GzRoom? _room;
  String? _error;
  bool _loading = true;
  bool _busy = false;
  bool _inGame = false; // la vue de jeu est ouverte par-dessus
  bool _closed = false;
  bool _pollBusy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _closed = true;
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_pollBusy || _closed || _inGame || _code.isEmpty) return;
    _pollBusy = true;
    final r = await _c.fetchRoom(_code);
    _pollBusy = false;
    if (!mounted || _closed) return;
    if (!r.ok) {
      // Erreur réseau transitoire : on garde l'état affiché, message si rien à montrer.
      setState(() {
        _loading = false;
        if (_room == null) _error = r.error;
      });
      return;
    }
    setState(() {
      _room = r.data;
      _error = null;
      _loading = false;
    });
    final room = r.data!;
    if (room.isPlaying && room.player(_c.myId)?.status == 'joined') _openGame(room);
  }

  Future<void> _openGame(GzRoom room) async {
    if (_inGame) return;
    _inGame = true;
    await Get.to(() => YouwiiinGameView(game: room.toGame(), room: room), transition: Transition.downToUp);
    _inGame = false;
    if (_closed || !mounted) return;
    _c.loadMe();
    _c.loadInvitations();
    // Partie terminée / quittée : retour à l'accueil du module.
    Get.back();
  }

  Future<void> _act(Future<GzResult<GzRoom>> Function() run, {bool closeAfter = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final r = await run();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r.ok) _room = r.data;
    });
    if (!r.ok) {
      ToastHelper.showToast(r.error ?? 'Action impossible.', backgroundColor: Colors.red);
      return;
    }
    _c.loadInvitations();
    _c.loadMe();
    if (closeAfter) {
      Get.back();
    } else if (r.data!.isPlaying) {
      _openGame(r.data!);
    }
  }

  Future<void> _invite(GzRoom room) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : Colors.black87;
    var picked = <GzUserLite>[];
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF16151C) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Inviter des joueurs', style: TextStyle(color: fg, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            YouwiiinPlayerPicker(
              accent: GPTheme.primaryColor,
              fg: fg,
              maxSelect: (room.maxPlayers - room.players.length).clamp(0, 99),
              excludeIds: room.players.map((p) => p.userId).toList(),
              onChanged: (l) => picked = l,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: GPTheme.primaryColor, foregroundColor: Colors.white),
                child: const Text('Inviter', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      ),
    );
    if (ok != true || picked.isEmpty) return;
    final r = await _c.inviteToRoom(_code, picked.map((u) => u.id).toList());
    ToastHelper.showToast(r.ok ? 'Invitation envoyée.' : (r.error ?? 'Invitation impossible.'));
    _refresh();
  }

  Future<void> _confirmLeave(GzRoom room) async {
    final host = room.hostId == _c.myId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(host ? 'Annuler la salle ?' : 'Quitter la salle ?'),
        content: Text(host ? 'La salle sera annulée pour tous les joueurs.' : 'Vous ne participerez plus à cette partie.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui')),
        ],
      ),
    );
    if (ok == true) _act(() => _c.leaveRoom(_code), closeAfter: true);
  }

  // ───────────────────────── UI ─────────────────────────
  String _statusLabel(GzRoomPlayer p, GzRoom room) {
    if (room.hostId == p.userId && p.status == 'joined') return 'Hôte';
    switch (p.status) {
      case 'joined':
        return 'Prêt';
      case 'invited':
        return 'Invité';
      case 'declined':
        return 'A refusé';
      case 'left':
        return 'A quitté';
    }
    return p.status;
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'joined':
        return const Color(0xFF22C55E);
      case 'invited':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111014) : const Color(0xFFF7F5F0);
    final fg = isDark ? Colors.white : Colors.black87;
    final card = isDark ? const Color(0xFF1B1A22) : Colors.white;
    final accent = GPTheme.primaryColor;
    final room = _room;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20), onPressed: () => Get.back()),
        title: Text('Salle $_code', style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : room == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.meeting_room_outlined, size: 54, color: fg.withValues(alpha: .35)),
                  const SizedBox(height: 12),
                  Text(_error ?? 'Salle introuvable.', textAlign: TextAlign.center, style: TextStyle(color: fg.withValues(alpha: .7))),
                  const SizedBox(height: 14),
                  OutlinedButton(onPressed: _refresh, child: const Text('Réessayer')),
                ]),
              ),
            )
          : _body(room, fg, card, accent),
    );
  }

  Widget _body(GzRoom room, Color fg, Color card, Color accent) {
    final me = _c.myId;
    final mine = room.player(me);
    final isHost = room.hostId == me;
    final g = room.toGame();
    final canStart = isHost && room.isWaiting && room.joinedCount >= room.minPlayers;
    final invitedMe = mine?.status == 'invited' && room.isWaiting;
    final joinedMe = mine?.status == 'joined';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        // Jeu + statut
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [g.accent, Color.lerp(g.accent, Colors.black, .35)!]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: FaIcon(gzIcon(g.icon), color: Colors.white, size: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(room.gameName, style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  room.isWaiting
                      ? 'En attente des joueurs'
                      : room.isPlaying
                      ? 'Partie en cours'
                      : room.isFinished
                      ? 'Partie terminée'
                      : 'Salle annulée',
                  style: TextStyle(color: fg.withValues(alpha: .55), fontSize: 13),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // Pot / mise
        Row(children: [
          Expanded(child: _infoTile(Icons.toll_rounded, 'Pot', '${room.pot > 0 ? room.pot : room.stake * room.joinedCount} GCoin', const Color(0xFFFFC600), fg, card)),
          const SizedBox(width: 12),
          Expanded(child: _infoTile(Icons.sell_rounded, 'Mise', room.stake == 0 ? 'Gratuit' : '${room.stake} GCoin', accent, fg, card)),
          const SizedBox(width: 12),
          Expanded(child: _infoTile(Icons.group_rounded, 'Joueurs', '${room.joinedCount}/${room.maxPlayers}', const Color(0xFF0086C9), fg, card)),
        ]),
        const SizedBox(height: 18),
        Text('Joueurs', style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        for (final p in room.players)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: room.winnerIds.contains(p.userId) ? Border.all(color: const Color(0xFFFFC600), width: 1.4) : null,
            ),
            child: Row(children: [
              gzAvatar(p.name, p.avatarUrl, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.userId == me ? '${p.name} (vous)' : p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
                  if (p.score != null) Text('${p.score} pts', style: TextStyle(color: fg.withValues(alpha: .55), fontSize: 12)),
                ]),
              ),
              if (room.winnerIds.contains(p.userId)) const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.emoji_events_rounded, color: Color(0xFFFFC600), size: 20)),
              if (room.hostId == p.userId) Padding(padding: const EdgeInsets.only(right: 6), child: Icon(Icons.star_rounded, color: accent, size: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusColor(p.status).withValues(alpha: .15), borderRadius: BorderRadius.circular(20)),
                child: Text(_statusLabel(p, room), style: TextStyle(color: _statusColor(p.status), fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        const SizedBox(height: 14),
        if (room.isFinished || room.isCancelled)
          _resultBanner(room, fg, card)
        else if (invitedMe) ...[
          Row(children: [
            Expanded(child: _btn('Refuser', Icons.close_rounded, null, fg, outlined: true, onTap: () => _act(() => _c.declineRoom(_code), closeAfter: true))),
            const SizedBox(width: 12),
            Expanded(child: _btn('Accepter', Icons.check_rounded, accent, Colors.white, onTap: () => _act(() => _c.joinRoom(_code)))),
          ]),
          if (room.stake > 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Accepter engage une mise de ${room.stake} GCoin au lancement.', textAlign: TextAlign.center, style: TextStyle(color: fg.withValues(alpha: .5), fontSize: 12))),
        ] else if (room.isWaiting && joinedMe) ...[
          if (isHost) ...[
            _btn('Lancer la partie', Icons.play_arrow_rounded, canStart ? accent : Colors.grey, Colors.white, onTap: canStart ? () => _act(() => _c.startRoom(_code)) : null),
            if (!canStart) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Il faut au moins ${room.minPlayers} joueurs prêts.', textAlign: TextAlign.center, style: TextStyle(color: fg.withValues(alpha: .5), fontSize: 12))),
            const SizedBox(height: 10),
            if (room.players.length < room.maxPlayers) _btn('Inviter d\'autres joueurs', Icons.person_add_alt_1_rounded, null, fg, outlined: true, onTap: () => _invite(room)),
            const SizedBox(height: 10),
          ] else
            Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('En attente du lancement par l\'hôte…', textAlign: TextAlign.center, style: TextStyle(color: fg.withValues(alpha: .6)))),
          _btn(isHost ? 'Annuler la salle' : 'Quitter', Icons.logout_rounded, null, Colors.redAccent, outlined: true, onTap: () => _confirmLeave(room)),
        ] else if (room.isPlaying)
          _btn('Rejoindre la partie', Icons.sports_esports_rounded, accent, Colors.white, onTap: joinedMe ? () => _openGame(room) : null),
      ],
    );
  }

  Widget _resultBanner(GzRoom room, Color fg, Color card) {
    final o = room.outcomeFor(_c.myId);
    final text = room.isCancelled ? 'Salle annulée — mises remboursées.' : (o == 'win' ? 'Vous avez gagné ! +${room.gainedFor(_c.myId)} GCoin' : (o == 'draw' ? 'Égalité — mises remboursées.' : 'Vous avez perdu cette partie.'));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Icon(o == 'win' && !room.isCancelled ? Icons.emoji_events_rounded : Icons.flag_rounded, color: const Color(0xFFFFC600)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w800))),
      ]),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, Color color, Color fg, Color card) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 14)),
      Text(label, style: TextStyle(color: fg.withValues(alpha: .5), fontSize: 11)),
    ]),
  );

  Widget _btn(String label, IconData icon, Color? bg, Color fgc, {required VoidCallback? onTap, bool outlined = false}) {
    final child = _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon);
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: _busy ? null : onTap,
              style: OutlinedButton.styleFrom(foregroundColor: fgc, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: child,
              label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            )
          : ElevatedButton.icon(
              onPressed: _busy ? null : onTap,
              style: ElevatedButton.styleFrom(backgroundColor: bg, foregroundColor: fgc, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: child,
              label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
    );
  }
}
