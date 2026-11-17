import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/components/moneroo_webview_payment_page.dart';
import 'package:grand_public_v2/app/services/live_access_service.dart';

/// Barrière d'accès d'un direct payant + présence (heartbeat) :
///  - direct gratuit ou accès déjà acquis → affiche [builder] et signale sa présence toutes les 20 s ;
///  - direct payant sans accès → carte « Débloquer » (paiement Moneroo en WebView) ;
///  - le prix peut changer EN PLEIN DIRECT : un refus (402) au heartbeat re-verrouille le direct.
class LiveGate extends StatefulWidget {
  final String kind; // media_live | channel
  final int id;
  final bool isPaid;
  final bool hasAccess;
  final int price;
  final String title;
  final Color accent;
  final bool dark;
  /// Construit le lecteur ; reçoit le flux (déverrouillé) renvoyé par le serveur, s'il y en a un.
  final Widget Function(BuildContext context, String? streamUrl, String? youtubeId) builder;

  const LiveGate({
    super.key,
    required this.kind,
    required this.id,
    required this.isPaid,
    required this.hasAccess,
    required this.price,
    required this.title,
    required this.builder,
    this.accent = const Color(0xFFE53935),
    this.dark = false,
  });

  @override
  State<LiveGate> createState() => _LiveGateState();
}

class _LiveGateState extends State<LiveGate> {
  late bool _paid = widget.isPaid;
  late bool _access = widget.hasAccess;
  late int _price = widget.price;
  String? _stream;
  String? _youtube;
  bool _busy = false;
  String? _error;
  Timer? _hb;

  bool get _locked => _paid && !_access;

  @override
  void initState() {
    super.initState();
    _refresh();
    _hb = Timer.periodic(const Duration(seconds: 20), (_) => _beat());
    _beat();
  }

  @override
  void dispose() {
    _hb?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final s = await LiveAccessService.state(widget.kind, widget.id);
    if (s != null && mounted) {
      setState(() {
        _paid = s.isPaid;
        _access = s.hasAccess;
        _price = s.price;
        _stream = s.streamUrl ?? _stream;
        _youtube = s.youtubeId ?? _youtube;
      });
    }
  }

  Future<void> _beat() async {
    if (_locked) {
      await _refresh(); // un direct repassé en gratuit se débloque tout seul
      return;
    }
    final ok = await LiveAccessService.heartbeat(widget.kind, widget.id);
    if (!ok) await _refresh(); // prix modifié / direct devenu payant : on re-vérifie
  }

  Future<void> _pay() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final init = await LiveAccessService.pay(widget.kind, widget.id);
      if (init == null) {
        _error = "Impossible d'initialiser le paiement.";
      } else if (init['already'] == true) {
        await _refresh();
      } else if (mounted) {
        final pid = await openMonerooWebviewPayment(
          context,
          checkoutUrl: init['checkout_url'].toString(),
          returnUrlPrefix: init['return_url_prefix'].toString(),
        );
        if (pid != null) {
          final s = await LiveAccessService.confirm(widget.kind, widget.id, pid);
          if (s != null) {
            _paid = s.isPaid;
            _access = s.hasAccess;
            _price = s.price;
            _stream = s.streamUrl ?? _stream;
            _youtube = s.youtubeId ?? _youtube;
          } else {
            _error = "Paiement non confirmé pour l'instant. Réessayez dans un instant.";
          }
        }
      }
    } catch (_) {
      _error = 'Une erreur est survenue.';
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.builder(context, _stream, _youtube);
    final fg = widget.dark ? Colors.white : Colors.black87;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.dark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.accent.withValues(alpha: 0.5)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lock_rounded, size: 40, color: widget.accent),
        const SizedBox(height: 10),
        Text('Direct payant', style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 4),
        Text(widget.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg.withValues(alpha: 0.7))),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: _busy ? null : _pay,
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Débloquer pour $_price F', style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
        const SizedBox(height: 8),
        Text('Paiement Mobile Money sécurisé. Accès à ce direct, au prix actuel.', textAlign: TextAlign.center, style: TextStyle(color: fg.withValues(alpha: 0.5), fontSize: 11)),
      ]),
    );
  }
}
