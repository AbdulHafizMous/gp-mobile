// Bottom sheet de la chaîne : choisir un plan et s'abonner (Moneroo), ou
// gérer son abonnement (état, expiration, renouvellement, résiliation).
// Ouvert par le bouton ⚙ en haut à droite de la page d'une chaîne.
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
// import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/moneroo_webview_payment_page.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/channel_model.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

class ChannelSubscribeSheet extends StatefulWidget {
  final ChannelModel channel;
  final Future<void> Function() onChanged;
  const ChannelSubscribeSheet({super.key, required this.channel, required this.onChanged});

  static Future<void> show(BuildContext context, ChannelModel channel, Future<void> Function() onChanged) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChannelSubscribeSheet(channel: channel, onChanged: onChanged),
    );
  }

  @override
  State<ChannelSubscribeSheet> createState() => _ChannelSubscribeSheetState();
}

class _ChannelSubscribeSheetState extends State<ChannelSubscribeSheet> {
  int? _busyPlan;
  bool _cancelling = false;

  ChannelModel get ch => widget.channel;

  Future<void> _subscribe(ChannelPlanModel plan) async {
    if (shouldSkipPayments) {
      ToastHelper.showToast(paymentsUnavailableMessage, backgroundColor: Colors.orange, textColor: Colors.white);
      return;
    }
    if (!kIsWeb && Platform.isIOS) {
      ToastHelper.showToast(channelPaymentsIosMessage, backgroundColor: Colors.orange, textColor: Colors.white);
      return;
    }
    setState(() => _busyPlan = plan.id);
    try {
      final res = await RequestService().post('/channels/plans/${plan.id}/pay');
      final d = res.data?['data'];
      final checkout = d?['checkout_url']?.toString();
      final prefix = d?['return_url_prefix']?.toString();
      if (checkout == null || prefix == null || !mounted) return;

      final paymentId = await openMonerooWebviewPayment(context, checkoutUrl: checkout, returnUrlPrefix: prefix);
      if (paymentId == null || !mounted) return;

      await RequestService().post('/channels/plans/${plan.id}/confirm', data: {'payment_id': paymentId});
      await widget.onChanged();
      if (mounted) Navigator.of(context).pop();
      ToastHelper.showToast('Abonnement activé ✅', backgroundColor: Colors.green, textColor: Colors.white);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message']?.toString() : null;
      ToastHelper.showToast(msg ?? 'Le paiement a échoué. Réessayez.', backgroundColor: Colors.red, textColor: Colors.white);
    } finally {
      if (mounted) setState(() => _busyPlan = null);
    }
  }

  Future<void> _cancel() async {
    final sub = ch.subscription;
    if (sub == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Résilier l\'abonnement ?'),
        content: const Text('Vous perdrez immédiatement l\'accès aux contenus premium de cette chaîne.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Garder')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Résilier', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _cancelling = true);
    try {
      await RequestService().post('/channels/subscriptions/${sub.id}/cancel');
      await widget.onChanged();
      if (mounted) Navigator.of(context).pop();
      ToastHelper.showToast('Abonnement résilié.', backgroundColor: Colors.grey.shade800, textColor: Colors.white);
    } catch (_) {
      ToastHelper.showToast('Impossible de résilier. Réessayez.', backgroundColor: Colors.red, textColor: Colors.white);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.white60 : Colors.black54;
    final sub = ch.subscription;
    final active = sub != null && sub.isActive;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: muted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 16),
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: ch.logoUrl != null ? NetworkImage(ch.logoUrl!) : null,
              child: ch.logoUrl == null ? Text(ch.name.isEmpty ? '?' : ch.name[0]) : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(ch.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 16),
          if (active) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.verified_rounded, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Abonné · ${sub.plan?.name ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                      'Actif jusqu\'au ${sub.endsAt?.day.toString().padLeft(2, '0')}/${sub.endsAt?.month.toString().padLeft(2, '0')}/${sub.endsAt?.year} (${sub.daysLeft} j)',
                      style: TextStyle(color: muted, fontSize: 12.5),
                    ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Text('Prolonger mon abonnement', style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
          ] else
            Text('Abonnez-vous pour débloquer tous les contenus premium de cette chaîne et soutenir son créateur.',
                style: TextStyle(color: muted, fontSize: 13.5)),
          const SizedBox(height: 10),
          if (ch.plans.isEmpty) Text('Cette chaîne ne propose pas encore d\'abonnement.', style: TextStyle(color: muted)),
          for (final p in ch.plans)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _busyPlan != null ? null : () => _subscribe(p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), width: 1.4),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        Text(p.durationLabel, style: TextStyle(color: muted, fontSize: 12)),
                      ]),
                    ),
                    _busyPlan == p.id
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(p.priceLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                  ]),
                ),
              ),
            ),
          if (active)
            TextButton(
              onPressed: _cancelling ? null : _cancel,
              child: const Text('Résilier mon abonnement', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 4),
          Text('Paiement sécurisé par Moneroo. Aucun renouvellement automatique.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 11.5)),
        ]),
      ),
    );
  }
}
