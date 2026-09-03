import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/user.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:video_player/video_player.dart';

// For Test
const bool useMock = false;
// Versionning
const String kAppVersion = '1.2.0';
// User
final activeUser = User.empty().obs;
//

const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.maxafrica.gpbenin';
const String kAppStoreUrl = 'https://apps.apple.com/app/com.maxafrica.gpbenin';

class GPTextStyle extends TextStyle {
  const GPTextStyle({
    super.inherit,
    super.color,
    super.backgroundColor,
    super.fontSize,
    super.fontWeight,
    super.fontStyle,
    super.letterSpacing,
    super.wordSpacing,
    super.textBaseline,
    super.height,
    super.leadingDistribution,
    super.locale,
    super.foreground,
    super.background,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.debugLabel,
    super.fontFamilyFallback,
    super.package,
    super.overflow,
  }) : super(
         fontFamily: "gotham_book",
       );

  static GPTextStyle title({Color? color}) =>
      GPTextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color);

  static GPTextStyle body({Color? color}) =>
      GPTextStyle(fontSize: 14, color: color);
}

// Phone Formatter

class SimplePhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(' ', '');

    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i + 1) % 2 == 0 && i != digits.length - 1) {
        buffer.write(' ');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}


// Apple Auth


  /// Génère une chaîne aléatoire cryptographiquement sûre pour le nonce Apple.
  String vgenerateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Retourne le SHA-256 (hex) d'une chaîne, exigé par Firebase pour vérifier le nonce Apple.
  String vsha256ofString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }


// ─────────────────────────────────────────────────────────────────────────────
// FULLSCREEN IMAGE VIEWER
// ─────────────────────────────────────────────────────────────────────────────
class FullscreenImageViewer extends StatelessWidget {
  final String url;
  const FullscreenImageViewer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: url.startsWith('/')
              ? Image.file(File(url), fit: BoxFit.contain)
              : Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, prog) => prog == null
                      ? child
                      : const CircularProgressIndicator(color: Colors.white),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FULLSCREEN VIDEO PLAYER
// ─────────────────────────────────────────────────────────────────────────────
class FullscreenVideoPlayer extends StatefulWidget {
  final String url;
  const FullscreenVideoPlayer({super.key, required this.url});

  @override
  State<FullscreenVideoPlayer> createState() => FullscreenVideoPlayerState();
}

class FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  late VideoPlayerController _vpc;
  bool _init = false;

  @override
  void initState() {
    super.initState();
    _vpc = widget.url.startsWith('/')
        ? VideoPlayerController.file(File(widget.url))
        : VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _vpc.initialize().then((_) {
      if (mounted) {
        setState(() => _init = true);
        _vpc.play();
      }
    });
  }

  @override
  void dispose() {
    _vpc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: _init
            ? GestureDetector(
                onTap: () => _vpc.value.isPlaying ? _vpc.pause() : _vpc.play(),
                child: AspectRatio(
                  aspectRatio: _vpc.value.aspectRatio,
                  child: VideoPlayer(_vpc),
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
      bottomNavigationBar: _init
          ? VideoProgressIndicator(
              _vpc,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: GPTheme.primaryColor,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white10,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            )
          : null,
    );
  }
}
