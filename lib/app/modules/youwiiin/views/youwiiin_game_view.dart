// lib/app/modules/youwiiin/views/youwiiin_game_view.dart
//
// Vue de jeu Youwiiin (WebView). Gère :
//  - le mode solo (session + score + GCoin) ;
//  - le multijoueur : `score_duel` (session solo + POST rooms/{code}/result)
//    et `realtime` (pont mp_* : Flutter relaie l'API et poll les événements) ;
//  - sons / haptique (couche yw.js injectée si absente) et bandeau de gain ;
//  - écran de fin natif animé (victoire / défaite / égalité).

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../controllers/youwiiin_controller.dart';
import '../widgets/youwiiin_confetti.dart';

class YouwiiinGameView extends StatefulWidget {
  final GzGame game;

  /// Non null = partie multijoueur dans cette salle (status `playing`).
  final GzRoom? room;
  const YouwiiinGameView({super.key, required this.game, this.room});

  @override
  State<YouwiiinGameView> createState() => _YouwiiinGameViewState();
}

class _YouwiiinGameViewState extends State<YouwiiinGameView> {
  late final WebViewController _webCtrl;
  late final YouwiiinController _ctrl = Get.find<YouwiiinController>();

  String? _sessionToken;
  bool _loading = true;
  bool _ready = false;
  bool _disposed = false;
  String _origin = '';

  // Son
  bool _muted = false;

  // Bandeau animé (gain / record)
  bool _bannerVisible = false;
  String _bannerTitle = '';
  String _bannerSub = '';
  IconData _bannerIcon = Icons.emoji_events_rounded;
  Timer? _bannerTimer;

  // Multijoueur
  GzRoom? _room;
  int _lastEventId = 0;
  Timer? _poll;
  bool _pollBusy = false;
  // ignore: unused_field
  bool _bridgeReady = false; // mp_ready reçu
  bool _ended = false;
  GzRoom? _endRoom;
  String _lastRoomSig = '';
  Future<void> _sendChain = Future.value(); // garde l'ordre des envois API

  bool get _isMp => widget.room != null;
  bool get _realtime => _isMp && !(widget.room!.isScoreDuel);
  bool get _scoreDuel => _isMp && widget.room!.isScoreDuel;
  String get _code => widget.room!.code;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _lastRoomSig = widget.room == null ? '' : jsonEncode(widget.room!.raw);
    // Pas de zone grise autour du jeu : plein écran immersif, portrait.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _setupController();
    _initSession();
  }

  // ───────────────────────── WebView + pont JS ─────────────────────────
  void _setupController() {
    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F0E13))
      ..addJavaScriptChannel(
        'GameZBridge',
        onMessageReceived: (m) => _onBridge(m.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            if (!_disposed && mounted) setState(() => _loading = false);
            await _injectYw();
            _syncMuted();
          },
        ),
      );
  }

  /// Exécute du JS sans jamais lever d'exception.
  Future<void> _js(String code) async {
    if (_disposed) return;
    try {
      await _webCtrl.runJavaScript(code);
    } catch (_) {}
  }

  /// Injecte le loader de yw.js (sons, effets, couche multijoueur) si la page
  /// ne l'a pas déjà chargé. Origin déduit de l'URL d'entrée.
  Future<void> _injectYw() async {
    if (_origin.isEmpty) return;
    await _js(
      "(function(){try{if(window.YW)return;var s=document.createElement('script');"
      "s.src='$_origin/games/_shared/yw.js';(document.head||document.documentElement).appendChild(s);}catch(e){}})();",
    );
  }

  Future<void> _sfx(String name) =>
      _js("try{window.YW&&YW.sfx&&YW.sfx.play('$name')}catch(e){}");

  Future<void> _native(Map<String, dynamic> obj) =>
      _js('try{window.YW&&YW._native(${jsonEncode(obj)})}catch(e){}');

  Future<void> _syncMuted() async {
    try {
      final r = await _webCtrl.runJavaScriptReturningResult(
        '(window.YW&&YW.sfx&&YW.sfx.muted)?"1":"0"',
      );
      final m = r.toString().replaceAll('"', '') == '1';
      if (mounted && !_disposed && m != _muted) setState(() => _muted = m);
    } catch (_) {}
  }

  Future<void> _toggleSound() async {
    HapticFeedback.selectionClick();
    await _js('try{window.YW&&YW.sfx&&YW.sfx.toggle()}catch(e){}');
    await _syncMuted();
  }

  Future<void> _onBridge(String raw) async {
    try {
      final p = jsonDecode(raw);
      if (p is! Map) return;
      switch (p['type']) {
        case 'score':
          await _onScore(Map<String, dynamic>.from(p));
          break;
        case 'mp_ready':
          if (_isMp) _onMpReady();
          break;
        case 'mp_send':
          if (_isMp) _onMpSend(p);
          break;
        case 'mp_result':
          if (_isMp) _onMpResult(p);
          break;
        case 'mp_leave':
          if (_isMp) _leave();
          break;
      }
    } catch (_) {}
  }

  // ───────────────────────── Solo / score ─────────────────────────
  Future<void> _onScore(Map<String, dynamic> p) async {
    final score = (p['score'] as num?)?.toInt() ?? 0;

    // score_duel : le score de la partie est aussi posté sur la salle.
    if (_scoreDuel && !_ended) {
      _queue(() async {
        final r = await _ctrl.postRoomResult(_code, score: score);
        if (!r.ok && !_disposed)
          ToastHelper.showToast(r.error ?? 'Score non envoyé.');
      });
    }

    if (_sessionToken == null) return;
    final r = await _ctrl.submitScore(
      _sessionToken!,
      score,
      duration: (p['duration'] as num?)?.toInt(),
      level: p['level']?.toString(),
      metadata: p['metadata'] is Map
          ? Map<String, dynamic>.from(p['metadata'])
          : null,
    );
    if (r == null || !mounted || _disposed) return;
    final gained = (r['gcoin_awarded'] as num?)?.toInt() ?? 0;
    final best = r['is_new_best'] == true;
    // Son : succès si record ou GCoin, sinon game over (+ pièce si gain).
    _sfx(gained > 0 || best ? 'success' : 'gameOver');
    if (gained > 0)
      Future.delayed(const Duration(milliseconds: 350), () => _sfx('coin'));
    if (gained > 0 || best) {
      HapticFeedback.mediumImpact();
      _showBanner(
        icon: gained > 0 ? Icons.toll_rounded : Icons.emoji_events_rounded,
        title: gained > 0 ? '+$gained GCoin gagnés' : 'Nouveau record !',
        sub: gained > 0 && best
            ? 'Nouveau record personnel'
            : (gained > 0 ? '' : 'Score : $score'),
      );
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _showBanner({
    required IconData icon,
    required String title,
    String sub = '',
  }) {
    _bannerTimer?.cancel();
    setState(() {
      _bannerIcon = icon;
      _bannerTitle = title;
      _bannerSub = sub;
      _bannerVisible = true;
    });
    _bannerTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted && !_disposed) setState(() => _bannerVisible = false);
    });
  }

  // ───────────────────────── Multijoueur ─────────────────────────
  /// Sérialise les appels API sortants (ordre des coups préservé).
  void _queue(Future<void> Function() job) {
    _sendChain = _sendChain.then((_) async {
      if (_disposed) return;
      try {
        await job();
      } catch (_) {}
    });
  }

  void _onMpReady() {
    _bridgeReady = true;
    final r = _room ?? widget.room!;
    final me = _ctrl.myId;
    _native({
      'kind': 'init',
      'me': {'id': me, 'name': _ctrl.activeName},
      'room': r.raw,
      'seed': r.seed,
    });
    _startPolling();
  }

  void _onMpSend(Map p) {
    final evt = p['evt']?.toString() ?? 'move';
    final payload = p['payload'] is Map
        ? Map<String, dynamic>.from(p['payload'])
        : <String, dynamic>{};
    _queue(() async {
      final r = await _ctrl.postRoomEvent(_code, evt, payload);
      if (!r.ok && !_disposed)
        ToastHelper.showToast('Coup non envoyé : ${r.error}');
    });
  }

  void _onMpResult(Map p) {
    final w = p['winner_user_id'];
    final winner = w == null ? null : (w as num).toInt();
    final draw = p['draw'] == true;
    final score = p['score'] is num ? (p['score'] as num).toInt() : null;
    _queue(() async {
      final r = await _ctrl.postRoomResult(
        _code,
        score: score,
        winnerUserId: winner,
        draw: draw,
      );
      if (!r.ok && !_disposed)
        ToastHelper.showToast(r.error ?? 'Résultat non envoyé.');
    });
  }

  void _startPolling() {
    if (_poll != null || !_isMp) return;
    _poll = Timer.periodic(const Duration(milliseconds: 1200), (_) => _tick());
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _tick() async {
    if (_pollBusy || _disposed || _ended) return;
    _pollBusy = true;
    try {
      final res = await _ctrl.fetchRoomEvents(_code, _lastEventId);
      if (_disposed || !res.ok)
        return; // erreur réseau : on retente au tick suivant
      final d = res.data!;
      for (final e in d.events) {
        final id = gzInt(e['id']);
        if (id > _lastEventId) _lastEventId = id;
        if (_realtime) {
          _native({
            'kind': 'event',
            'event': {
              'id': id,
              'user_id': gzInt(e['user_id']),
              'type': e['type'],
              'payload': e['payload'],
            },
          });
        }
      }
      if (d.room != null) _onRoom(d.room!);
    } finally {
      _pollBusy = false;
    }
  }

  void _onRoom(GzRoom r) {
    final sig = jsonEncode(r.raw);
    if (sig != _lastRoomSig) {
      _lastRoomSig = sig;
      if (mounted) setState(() => _room = r);
      if (_realtime) _native({'kind': 'room', 'room': r.raw});
    }
    if (r.isOver && !_ended) _finish(r);
  }

  void _finish(GzRoom r) {
    _ended = true;
    _stopPolling();
    final me = _ctrl.myId;
    final outcome = r.outcomeFor(me);
    final gained = r.gainedFor(me);
    _native({
      'kind': 'end',
      'room': r.raw,
      'outcome': outcome,
      'gained': gained,
    });
    _sfx(outcome == 'win' ? 'win' : (outcome == 'lose' ? 'lose' : 'success'));
    HapticFeedback.heavyImpact();
    _ctrl.loadMe(); // solde à jour (gain / remboursement)
    if (mounted) setState(() => _endRoom = r);
  }

  // ───────────────────────── Session ─────────────────────────
  Future<void> _initSession() async {
    String url;
    if (_realtime) {
      // Pas de session solo : le jeu parle seulement mp_*.
      url = widget.room!.playUrl;
    } else {
      final session = await _ctrl.startSession(widget.game);
      if (session == null) {
        if (mounted) {
          Get.back();
          Get.snackbar(
            'Jeu indisponible',
            'Ce jeu est en pause ou inaccessible pour le moment.',
          );
        }
        return;
      }
      _sessionToken = session['session_token'];
      url = _scoreDuel
          ? widget.room!.playUrl
          : (session['entry_url'] ?? widget.game.entryUrl);
    }
    if (url.isEmpty) url = widget.game.entryUrl;
    if (_disposed) return;
    try {
      _origin = Uri.parse(url).origin;
    } catch (_) {}
    if (url.isNotEmpty) await _webCtrl.loadRequest(Uri.parse(url));
    if (_scoreDuel)
      _startPolling(); // suivre l'état de la salle (fin de partie)
    if (mounted) setState(() => _ready = true);
  }

  // ───────────────────────── Sortie ─────────────────────────
  Future<bool> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter la partie ?'),
        content: const Text(
          'Vous abandonnez la partie multijoueur : c\'est un forfait et votre mise est perdue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Rester'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Quitter',
              style: TextStyle(
                color: GPTheme.primaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _leave() async {
    if (_endRoom != null || (_isMp && _ended)) {
      if (mounted) Get.back(result: true);
      return;
    }
    if (_isMp) {
      if (!await _confirmLeave() || !mounted) return;
      _stopPolling();
      final r = await _ctrl.leaveRoom(_code);
      if (!r.ok)
        ToastHelper.showToast(r.error ?? 'Impossible de quitter la salle.');
      _ctrl.loadMe();
      if (mounted) Get.back(result: true);
      return;
    }
    // Solo : demande au jeu d'envoyer le score de la partie en cours.
    try {
      await _webCtrl.runJavaScript('window.GZ && GZ.flush && GZ.flush()');
      await Future.delayed(const Duration(milliseconds: 350));
    } catch (_) {}
    if (mounted) Get.back();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling(); // le polling d'événements s'arrête avec la vue
    _bannerTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ───────────────────────── UI ─────────────────────────
  Widget _banner() {
    final accent = GPTheme.primaryColor;
    return Positioned(
      top: 8,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          offset: _bannerVisible ? Offset.zero : const Offset(0, -1.6),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _bannerVisible ? 1 : 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF26232F),
                    Color.lerp(const Color(0xFF26232F), accent, .35)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withValues(alpha: .6)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: .35),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: .25),
                    ),
                    child: Icon(_bannerIcon, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _bannerTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        if (_bannerSub.isNotEmpty)
                          Text(
                            _bannerSub,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Pastille « score envoyé, en attente des autres » (score_duel).
  Widget? _waitingChip() {
    final r = _room;
    if (!_scoreDuel || r == null || _ended) return null;
    final me = r.player(_ctrl.myId);
    if (me == null || !me.reported) return null;
    final joined = r.players.where((p) => p.status == 'joined').toList();
    final done = joined.where((p) => p.reported).length;
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xE6000000),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Score envoyé · en attente des autres ($done/${joined.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _room;
    final end = _endRoom;
    final chip = _waitingChip();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0E13),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                          onPressed: _leave,
                        ),
                        Expanded(
                          child: Text(
                            widget.game.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (r != null && r.pot > 0)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFFC600,
                              ).withValues(alpha: .16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.toll_rounded,
                                  size: 14,
                                  color: Color(0xFFFFC600),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Pot ${r.pot}',
                                  style: const TextStyle(
                                    color: Color(0xFFFFC600),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        IconButton(
                          tooltip: _muted ? 'Activer le son' : 'Couper le son',
                          icon: Icon(
                            _muted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            color: Colors.white70,
                            size: 22,
                          ),
                          onPressed: _toggleSound,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        if (_ready) WebViewWidget(controller: _webCtrl),
                        if (_loading)
                          const Center(child: CircularProgressIndicator()),
                        if (chip != null) chip,
                        _banner(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (end != null)
              Positioned.fill(
                child: YouwiiinEndOverlay(
                  outcome: end.outcomeFor(_ctrl.myId),
                  gained: end.gainedFor(_ctrl.myId),
                  gameName: end.gameName,
                  cancelled: end.isCancelled,
                  ranking: [
                    for (final p
                        in ([...end.players.where((p) => p.status == 'joined')]
                          ..sort(
                            (a, b) => (b.score ?? -1).compareTo(a.score ?? -1),
                          )))
                      (
                        name: p.name,
                        score: p.score,
                        winner: end.winnerIds.contains(p.userId),
                      ),
                  ],
                  onClose: () => Get.back(result: true),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
