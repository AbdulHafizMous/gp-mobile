// Portefeuille Youwiiin : 2 soldes (GCoin + Argent réel), dépôt gratuit, retrait (frais fixes + minimum), historique.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Response;
import 'package:grand_public_v2/app/components/moneroo_webview_payment_page.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/api_error_helper.dart';
import '../controllers/youwiiin_controller.dart';
import '../widgets/youwiiin_style.dart';

class YouwiiinWalletView extends StatefulWidget {
  /// true : affiché dans l'onglet Wallet de Youwiiin (l'en-tête du module reste affiché, pas de 2e AppBar).
  final bool embedded;
  const YouwiiinWalletView({super.key, this.embedded = false});

  @override
  State<YouwiiinWalletView> createState() => _YouwiiinWalletViewState();
}

class _YouwiiinWalletViewState extends State<YouwiiinWalletView> {
  final _c = gzController;
  Map<String, dynamic> _settings = {};
  List<Map<String, dynamic>> _tx = [];
  List<Map<String, dynamic>> _wd = [];
  bool _loading = true;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  Future<void> _load() async {
    try {
      final w = await RequestService().get('/gamez/wallet');
      final d = w.data['data'];
      _c.gcoinBalance.value = _i(d['gcoin']);
      _c.cashBalance.value = _i(d['cash']);
      _settings = Map<String, dynamic>.from(d['settings'] ?? {});
      final t = await RequestService().get('/gamez/wallet/transactions', queryParameters: {if (_filter.isNotEmpty) 'type': _filter});
      _tx = List<Map<String, dynamic>>.from((t.data['data']['items'] as List).map((e) => Map<String, dynamic>.from(e)));
      final wd = await RequestService().get('/gamez/wallet/withdrawals');
      _wd = List<Map<String, dynamic>>.from((wd.data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _f(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ');

  // ── Dépôt ───────────────────────────────────────────────────────────
  Future<void> _deposit() async {
    final min = _i(_settings['deposit_min']);
    final ctrl = TextEditingController(text: '1000');
    final amount = await _askAmount(
      title: 'Recharger (gratuit)',
      hint: 'Aucun frais de dépôt. Minimum $min F.',
      ctrl: ctrl,
      presets: const [500, 1000, 2000, 5000, 10000],
      confirm: 'Payer',
    );
    // Ne PAS disposer tout de suite : la feuille se ferme encore (animation) et lit le controller -> « used after dispose ».
    Future.delayed(const Duration(milliseconds: 600), ctrl.dispose);
    if (amount == null) return;
    try {
      final r = await RequestService().post('/gamez/wallet/deposit', data: {'amount': amount});
      final d = r.data['data'];
      if (!mounted) return;
      final pid = await openMonerooWebviewPayment(context, checkoutUrl: d['checkout_url'], returnUrlPrefix: d['return_url_prefix']);
      if (pid == null) return;
      final v = await RequestService().post('/gamez/wallet/deposit/verify', data: {'payment_id': d['payment_id'] ?? pid});
      final ok = v.data['data']?['ok'] == true;
      Get.snackbar(ok ? 'Dépôt confirmé ✅' : 'Paiement non confirmé', ok ? '+$amount F sur ton solde argent réel.' : 'Si tu as été débité, le solde sera crédité sous peu.');
      await _load();
    } on DioException catch (e) {
      Get.snackbar('Dépôt impossible', ApiErrorHelper.messageFor(e));
    }
  }

  // ── Retrait ─────────────────────────────────────────────────────────
  Future<void> _withdraw() async {
    final min = _i(_settings['withdraw_min']);
    final pct = _i(_settings['withdraw_fee_pct']);
    if (_c.cashBalance.value < min) {
      Get.snackbar('Retrait indisponible', 'Il faut au moins $min F d\'argent réel pour retirer.');
      return;
    }
    final amountCtrl = TextEditingController(text: '$min');
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String provider = 'mtn';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final st = YwStyle.of(ctx);
          final amount = int.tryParse(amountCtrl.text) ?? 0;
          final fee = (amount * pct / 100).ceil();
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(color: st.sheet, borderRadius: const BorderRadius.vertical(top: Radius.circular(YwStyle.rSheet))),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Retirer de l\'argent', style: TextStyle(color: st.fg, fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('Frais fixes de $pct % · minimum $min F · versement par Mobile Money après validation.', style: TextStyle(color: st.sub, fontSize: 12.5)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setS(() {}),
                    decoration: InputDecoration(labelText: 'Montant à retirer (F)', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: st.faint, borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      _row(st, 'Frais ($pct %)', '- ${_f(fee)} F'),
                      _row(st, 'Tu recevras', '${_f((amount - fee).clamp(0, 1 << 31))} F', bold: true),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, children: [
                    for (final p in const [('mtn', 'MTN'), ('moov', 'Moov'), ('celtiis', 'Celtiis')])
                      YwChoiceChip(label: p.$2, selected: provider == p.$1, onTap: () => setS(() => provider = p.$1)),
                  ]),
                  const SizedBox(height: 12),
                  TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Numéro Mobile Money', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                  const SizedBox(height: 10),
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Nom du compte (optionnel)', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                  const SizedBox(height: 16),
                  YwButton(
                    label: 'Demander le retrait',
                    icon: Icons.south_west_rounded,
                    onTap: () async {
                      try {
                        await RequestService().post('/gamez/wallet/withdraw', data: {
                          'amount': amount,
                          'phone': phoneCtrl.text.trim(),
                          'provider': provider,
                          if (nameCtrl.text.trim().isNotEmpty) 'account_name': nameCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        Get.snackbar('Demande envoyée ✅', 'Elle sera traitée sous peu. Tu seras notifié.');
                        _load();
                      } on DioException catch (e) {
                        Get.snackbar('Retrait impossible', ApiErrorHelper.messageFor(e));
                      }
                    },
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      amountCtrl.dispose();
      phoneCtrl.dispose();
      nameCtrl.dispose();
    });
  }

  Widget _row(YwStyle st, String a, String b, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Expanded(child: Text(a, style: TextStyle(color: st.sub))),
      Text(b, style: TextStyle(color: st.fg, fontWeight: bold ? FontWeight.w900 : FontWeight.w600)),
    ]),
  );

  Future<int?> _askAmount({required String title, required String hint, required TextEditingController ctrl, required List<int> presets, required String confirm}) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final st = YwStyle.of(ctx);
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(color: st.sheet, borderRadius: const BorderRadius.vertical(top: Radius.circular(YwStyle.rSheet))),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: st.fg, fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 4),
              Text(hint, style: TextStyle(color: st.sub, fontSize: 12.5)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final p in presets) YwChoiceChip(label: '${_f(p)} F', selected: ctrl.text == '$p', onTap: () => ctrl.text = '$p')]),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: 'Montant (F)', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
              ),
              const SizedBox(height: 16),
              YwButton(label: confirm, icon: Icons.lock_rounded, onTap: () => Navigator.pop(ctx, int.tryParse(ctrl.text))),
            ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = YwStyle.of(context);
    return Scaffold(
      backgroundColor: st.bg,
      appBar: widget.embedded ? null : AppBar(backgroundColor: st.bg, elevation: 0, foregroundColor: st.fg, iconTheme: IconThemeData(color: st.fg), title: const Text('Wallet', style: TextStyle(fontWeight: FontWeight.w900))),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: st.accent))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Obx(() => Row(children: [
                      Expanded(child: _balanceCard(st, 'Argent réel', '${_f(_c.cashBalance.value)} F', Icons.payments_rounded, const [Color(0xFF16A34A), Color(0xFF059669)])),
                      const SizedBox(width: 12),
                      Expanded(child: _balanceCard(st, 'GCoin', _f(_c.gcoinBalance.value), Icons.monetization_on_rounded, const [Color(0xFFF59E0B), Color(0xFFEA580C)])),
                    ])),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: YwButton(label: 'Recharger', icon: Icons.add_rounded, onTap: _deposit)),
                  const SizedBox(width: 10),
                  Expanded(child: YwButton(label: 'Retirer', icon: Icons.south_west_rounded, outlined: true, onTap: _withdraw)),
                ]),
                const SizedBox(height: 10),
                Text(
                  'Recharge gratuite. L\'argent réel ne sert qu\'aux mises entre joueurs (jamais contre l\'IA), aux tournois payants et aux jeux premium. Retrait : ${_settings['withdraw_fee_pct']} % de frais, minimum ${_f(_i(_settings['withdraw_min']))} F.',
                  style: TextStyle(color: st.sub, fontSize: 12, height: 1.4),
                ),
                if (_wd.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Mes retraits', style: TextStyle(color: st.fg, fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 8),
                  for (final w in _wd.take(5))
                    Builder(builder: (_) {
                      final s = '${w['status']}';
                      final col = s == 'paid' ? YwStyle.ok : s == 'rejected' ? YwStyle.danger : YwStyle.warn;
                      final lbl = s == 'paid' ? 'Payé' : s == 'rejected' ? 'Refusé · remboursé' : 'En cours de traitement';
                      final ref = '${w['payment_reference'] ?? ''}';
                      final note = '${w['admin_note'] ?? ''}';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: col.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(s == 'paid' ? Icons.check_circle_rounded : s == 'rejected' ? Icons.cancel_rounded : Icons.hourglass_top_rounded, color: col, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${_f(_i(w['net']))} F vers ${w['phone']}', style: TextStyle(color: st.fg, fontWeight: FontWeight.w800, fontSize: 13)),
                              Text(lbl, style: TextStyle(color: col, fontWeight: FontWeight.w700, fontSize: 12)),
                              if (s == 'paid' && ref.isNotEmpty) Text('Référence : $ref${'${w['paid_via'] ?? ''}'.isNotEmpty ? ' (${w['paid_via']})' : ''}', style: TextStyle(color: st.sub, fontSize: 12)),
                              if (s == 'rejected' && note.isNotEmpty) Text('Motif : $note', style: TextStyle(color: st.sub, fontSize: 12)),
                            ]),
                          ),
                        ]),
                      );
                    }),
                ],
                const SizedBox(height: 18),
                Row(children: [
                  Text('Historique', style: TextStyle(color: st.fg, fontWeight: FontWeight.w900, fontSize: 16)),
                  const Spacer(),
                  for (final f in const [('', 'Tout'), ('in', 'Entrées'), ('out', 'Sorties')]) ...[
                    YwChoiceChip(label: f.$2, selected: _filter == f.$1, onTap: () {
                      _filter = f.$1;
                      _load();
                    }),
                    const SizedBox(width: 6),
                  ],
                ]),
                const SizedBox(height: 8),
                if (_tx.isEmpty)
                  Padding(padding: const EdgeInsets.all(28), child: Center(child: Text('Aucune opération pour le moment.', style: TextStyle(color: st.sub))))
                else
                  for (final t in _tx)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: (_i(t['amount']) >= 0 ? YwStyle.ok : YwStyle.danger).withValues(alpha: .12),
                        child: Icon(_i(t['amount']) >= 0 ? Icons.south_east_rounded : Icons.north_east_rounded, color: _i(t['amount']) >= 0 ? YwStyle.ok : YwStyle.danger, size: 20),
                      ),
                      title: Text('${t['label']}', style: TextStyle(color: st.fg, fontWeight: FontWeight.w700)),
                      subtitle: Text('${(t['created_at'] as String).substring(0, 16).replaceFirst('T', ' ')}${t['status'] == 'pending' ? ' · en attente' : ''}', style: TextStyle(color: st.sub, fontSize: 12)),
                      trailing: Text('${_i(t['amount']) >= 0 ? '+' : ''}${_f(_i(t['amount']))} F', style: TextStyle(color: _i(t['amount']) >= 0 ? YwStyle.ok : YwStyle.danger, fontWeight: FontWeight.w900)),
                    ),
              ]),
            ),
    );
  }

  Widget _balanceCard(YwStyle st, String label, String value, IconData icon, List<Color> colors) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: Colors.white70, size: 22),
      const SizedBox(height: 14),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))),
    ]),
  );
}
