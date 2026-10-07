import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../controllers/gamez_controller.dart';

class GameZGameView extends StatefulWidget {
  final GzGame game;
  const GameZGameView({super.key, required this.game});

  @override
  State<GameZGameView> createState() => _GameZGameViewState();
}

class _GameZGameViewState extends State<GameZGameView> {
  late final WebViewController _webCtrl;
  String? _sessionToken;
  bool _loading = true;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // Pas de zone grise autour du jeu : plein écran immersif, portrait.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _setupController();
    _initSession();
  }

  void _setupController() {
    final ctrl = Get.find<GameZController>();
    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F0E13))
      ..addJavaScriptChannel('GameZBridge', onMessageReceived: (message) async {
        try {
          final p = jsonDecode(message.message) as Map<String, dynamic>;
          if (p['type'] != 'score' || _sessionToken == null) return;
          final score = (p['score'] as num?)?.toInt() ?? 0;
          final r = await ctrl.submitScore(
            _sessionToken!,
            score,
            duration: (p['duration'] as num?)?.toInt(),
            level: p['level']?.toString(),
            metadata: p['metadata'] is Map ? Map<String, dynamic>.from(p['metadata']) : null,
          );
          if (r == null || !mounted) return;
          final gained = (r['gcoin_awarded'] as num?)?.toInt() ?? 0;
          final best = r['is_new_best'] == true;
          if (gained > 0 || best) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1F1D27),
              content: Row(children: [
                Icon(gained > 0 ? Icons.toll_rounded : Icons.emoji_events_rounded, color: GPTheme.clubColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    [if (gained > 0) '+$gained GCoin gagnés', if (best) 'Nouveau record personnel'].join(' · '),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
            ));
          }
        } catch (_) {}
      })
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) {
        if (mounted) setState(() => _loading = false);
      }));
  }

  Future<void> _initSession() async {
    final ctrl = Get.find<GameZController>();
    final session = await ctrl.startSession(widget.game);
    if (session == null) {
      if (mounted) {
        Get.back();
        Get.snackbar('Jeu indisponible', 'Ce jeu est en pause ou inaccessible pour le moment.');
      }
      return;
    }
    _sessionToken = session['session_token'];
    final url = session['entry_url'] ?? widget.game.entryUrl;
    if (url.isNotEmpty) await _webCtrl.loadRequest(Uri.parse(url));
    if (mounted) setState(() => _ready = true);
  }

  /// Avant de quitter : demande au jeu d'envoyer le score de la partie en cours.
  Future<void> _leave() async {
    try {
      await _webCtrl.runJavaScript('window.GZ && GZ.flush && GZ.flush()');
      await Future.delayed(const Duration(milliseconds: 350));
    } catch (_) {}
    if (mounted) Get.back();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0E13),
        body: SafeArea(
          child: Column(children: [
            SizedBox(
              height: 40,
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18), onPressed: _leave),
                Expanded(
                  child: Text(widget.game.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ]),
            ),
            Expanded(
              child: Stack(children: [
                if (_ready) WebViewWidget(controller: _webCtrl),
                if (_loading) const Center(child: CircularProgressIndicator()),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
