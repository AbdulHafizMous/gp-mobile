// lib/app/modules/gamez/views/gamez_game_view.dart
//
// Lecteur de jeu HTML5 en WebView (PRD §7-9, §27) : le SDK JS embarqué dans
// la page du jeu appelle `GameZBridge.postMessage(jsonEncode({...}))` pour
// remonter les scores ; on écoute via un JavaScriptChannel nommé "GameZBridge".

import 'dart:convert';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ctrl = Get.find<GameZController>();
    final session = await ctrl.startSession(widget.game);
    _sessionToken = session?['session_token'];
    final url = session?['entry_url'] ?? widget.game.entryUrl;

    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'GameZBridge',
        onMessageReceived: (message) {
          try {
            final payload = jsonDecode(message.message) as Map<String, dynamic>;
            if (payload['type'] == 'score' && _sessionToken != null) {
              final score = payload['score'];
              if (score is int) ctrl.submitScore(_sessionToken!, score);
            }
          } catch (_) {}
        },
      )
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) => setState(() => _loading = false)))
      ..loadRequest(Uri.parse(url));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: GPTheme.clubColor,
        title: Text(widget.game.name, style: const TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          if (_sessionToken != null || widget.game.entryUrl.isNotEmpty) WebViewWidget(controller: _webCtrl),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
