// Feuille d'achat d'un jeu premium : achat unique en argent réel ou en GCoin ; la démo se joue avant (voir GzGame.demoLeft).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:grand_public_v2/app/modules/youwiiin/views/youwiiin_wallet_view.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/api_error_helper.dart';
import '../controllers/youwiiin_controller.dart';
import '../views/youwiiin_game_view.dart';
import 'youwiiin_style.dart';

void gzShowPremiumSheet(GzGame g) {
  Get.bottomSheet(
    _PremiumSheet(game: g),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _PremiumSheet extends StatefulWidget {
  final GzGame game;
  const _PremiumSheet({required this.game});

  @override
  State<_PremiumSheet> createState() => _PremiumSheetState();
}

class _PremiumSheetState extends State<_PremiumSheet> {
  final _c = gzController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _c.loadMe();
  }

  Future<void> _buy(String method) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final res = await RequestService().post('/gamez/games/${widget.game.id}/purchase', data: {'method': method});
      final fresh = GzGame.fromJson(Map<String, dynamic>.from(res.data['data']));
      _c.loadMe();
      _c.loadHome();
      if (!mounted) return;
      Navigator.pop(context);
      Get.snackbar('Jeu débloqué 🎉', '${fresh.name} est à toi pour toujours.');
      Get.to(() => YouwiiinGameView(game: fresh), transition: Transition.downToUp);
    } on DioException catch (e) {
      if (mounted) setState(() => _busy = false);
      Get.snackbar('Achat impossible', ApiErrorHelper.messageFor(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = YwStyle.of(context);
    final g = widget.game;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      decoration: BoxDecoration(color: st.sheet, borderRadius: const BorderRadius.vertical(top: Radius.circular(YwStyle.rSheet))),
      child: SafeArea(
        top: false,
        child: Obx(() {
          final cash = _c.cashBalance.value;
          final gc = _c.gcoinBalance.value;
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: st.faint, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: g.accent, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g.name, style: TextStyle(color: st.fg, fontWeight: FontWeight.w900, fontSize: 18)),
                  Text('Jeu premium${g.developerName != null ? ' · par ${g.developerName}' : ''}', style: TextStyle(color: st.sub, fontSize: 12.5)),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Text(
              g.demoTotal > 0
                  ? 'Tu as utilisé tes ${g.demoTotal} partie(s) de démo. Débloque le jeu une fois pour jouer sans limite, pour toujours.'
                  : 'Débloque ce jeu une fois pour jouer sans limite, pour toujours.',
              style: TextStyle(color: st.sub, height: 1.4),
            ),
            const SizedBox(height: 18),
            YwButton(
              label: 'Acheter ${g.price} F',
              icon: Icons.payments_rounded,
              busy: _busy,
              onTap: cash >= g.price ? () => _buy('cash') : null,
            ),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: Text('Solde argent réel : $cash F', style: TextStyle(color: st.sub, fontSize: 12))),
              if (cash < g.price)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Get.to(() => const YouwiiinWalletView());
                  },
                  child: const Text('Recharger (gratuit)'),
                ),
            ]),
            if (g.gcoinPrice != null) ...[
              const SizedBox(height: 6),
              YwButton(
                label: 'Ou ${g.gcoinPrice} GCoin',
                icon: Icons.monetization_on_rounded,
                outlined: true,
                busy: _busy,
                onTap: gc >= g.gcoinPrice! ? () => _buy('gcoin') : null,
              ),
              Padding(padding: const EdgeInsets.only(top: 6), child: Text('Solde GCoin : $gc', style: TextStyle(color: st.sub, fontSize: 12))),
            ],
          ]);
        }),
      ),
    );
  }
}
