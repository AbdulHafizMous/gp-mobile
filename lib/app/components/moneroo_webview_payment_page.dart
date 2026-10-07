// lib/app/components/moneroo_webview_payment_page.dart
//
// Remplace le widget natif `Moneroo()` du SDK moneroo_flutter_sdk, qui
// plante à la fin du paiement (bug de parsing JSON connu dans
// MonerooPaymentInfos.fromJson — voir payment_infos.g.dart du package).
//
// Ici, tout se passe simplement : le backend initialise le paiement (clé
// secrète, jamais exposée) et renvoie une `checkout_url` ; on l'ouvre dans
// une WebView et on surveille les redirections vers `returnUrlPrefix` pour
// en extraire `payment_id` nous-mêmes — sans dépendre du SDK Moneroo côté
// client, donc sans son bug.

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MonerooWebviewPaymentPage extends StatefulWidget {
  final String checkoutUrl;
  final String returnUrlPrefix;

  const MonerooWebviewPaymentPage({
    super.key,
    required this.checkoutUrl,
    required this.returnUrlPrefix,
  });

  @override
  State<MonerooWebviewPaymentPage> createState() =>
      _MonerooWebviewPaymentPageState();
}

class _MonerooWebviewPaymentPageState extends State<MonerooWebviewPaymentPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.startsWith(widget.returnUrlPrefix)) {
              _handleUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _handleUrl(String url) {
    if (_finished || !url.startsWith(widget.returnUrlPrefix)) return;
    _finished = true;

    final uri = Uri.tryParse(url);
    // Moneroo ajoute `paymentId` + `paymentStatus` à la return_url (on
    // accepte aussi les variantes snake_case par sécurité).
    final q = uri?.queryParameters ?? const <String, String>{};
    final paymentId = q['paymentId'] ?? q['payment_id'] ?? q['id'];
    final status = (q['paymentStatus'] ?? q['payment_status'] ?? q['status'])
        ?.toLowerCase();

    Navigator.of(context).pop({
      'payment_id': paymentId,
      'cancelled':
          status == 'cancelled' || status == 'failed' || paymentId == null,
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paiement sécurisé'),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(null),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

/// Ouvre le paiement et renvoie le `payment_id` une fois confirmé (ou
/// `null` si l'utilisateur a fermé/annulé).
Future<String?> openMonerooWebviewPayment(
  BuildContext context, {
  required String checkoutUrl,
  required String returnUrlPrefix,
}) async {
  final result = await Navigator.of(context).push<Map<String, dynamic>>(
    MaterialPageRoute(
      builder: (_) => MonerooWebviewPaymentPage(
        checkoutUrl: checkoutUrl,
        returnUrlPrefix: returnUrlPrefix,
      ),
      fullscreenDialog: true,
    ),
  );

  if (result == null || result['cancelled'] == true) return null;
  return result['payment_id']?.toString();
}
