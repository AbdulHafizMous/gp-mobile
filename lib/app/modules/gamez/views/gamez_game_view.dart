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
  // On retire le mot-clé 'late' et on utilise un contrôleur nullable ou initialisé direct
  late final WebViewController _webCtrl;
  String? _sessionToken;
  bool _loading = true;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupController();
    _initSession();
  }

  void _setupController() {
    final ctrl = Get.find<GameZController>();

    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'GameZBridge',
        onMessageReceived: (message) {
          try {
            final payload = jsonDecode(message.message) as Map<String, dynamic>;
            if (payload['type'] == 'score' && _sessionToken != null) {
              final score = payload['score'];
              if (score is int) {
                ctrl.submitScore(_sessionToken!, score).then((gained) {
                  if (gained > 0 && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🪙 +$gained GCoin gagnés !'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                });
              }
            }
          } catch (_) {}
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      );
  }

  Future<void> _initSession() async {
    final ctrl = Get.find<GameZController>();
    final session = await ctrl.startSession(widget.game);
    _sessionToken = session?['session_token'];
    final url = session?['entry_url'] ?? widget.game.entryUrl;

    if (url.isNotEmpty) {
      await _webCtrl.loadRequest(Uri.parse(url));
    }

    if (mounted) {
      setState(() {
        _isControllerInitialized = true;
      });
    }
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
          // On n'affiche la WebView que si le contrôleur a fini de charger l'URL de session
          if (_isControllerInitialized)
            WebViewWidget(controller: _webCtrl),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}