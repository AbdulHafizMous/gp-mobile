import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/utils/app_link_router.dart';
import 'package:grand_public_v2/app/utils/share_helper.dart';
import 'package:url_launcher/url_launcher.dart';

final RegExp _urlRegExp = RegExp(
  r'((https?:\/\/)[^\s]+)',
  caseSensitive: false,
);

/// Affiche [text] normalement, sauf les URLs qu'il contient, qui deviennent
/// cliquables : les liens de partage "grandpublic.bj/m/…" ouvrent
/// directement la bonne page dans l'app (via [AppLinkRouter]), les autres
/// liens s'ouvrent dans le navigateur.
///
/// Corrige le bug où les liens partagés dans le chat (média, offre, canal…)
/// s'affichaient comme du texte brut non cliquable pour l'expéditeur ET le
/// destinataire.
class LinkifiedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color linkColor;

  const LinkifiedText({
    super.key,
    required this.text,
    required this.style,
    this.linkColor = Colors.lightBlueAccent,
  });

  @override
  Widget build(BuildContext context) {
    final matches = _urlRegExp.allMatches(text);
    if (matches.isEmpty) {
      return Text(text, style: style);
    }

    final spans = <InlineSpan>[];
    int cursor = 0;

    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: style.copyWith(
            color: linkColor,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => _openLink(url),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(TextSpan(style: style, children: spans));
  }

  Future<void> _openLink(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;

    // Lien de partage GRAND PUBLIC (https://grandpublic.bj/m/{type}/{id})
    // → navigation directe dans l'app plutôt qu'un aller-retour navigateur.
    if (uri.host == Uri.parse(kShareHost).host) {
      await AppLinkRouter.routeFromUri(uri);
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
