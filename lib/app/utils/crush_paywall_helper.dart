// lib/app/utils/crush_paywall_helper.dart
//
// Bottom sheet listant les packs de messages Crush disponibles. N'est
// jamais appelé si CrushQuotaService.isEnabled est false — voir
// CrushQuotaBanner et ChatController (blocage à l'envoi, code 402).

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/message_credit_pack_model.dart';
import 'package:grand_public_v2/app/modules/social/controllers/crush_purchase_controller.dart';
import 'package:grand_public_v2/app/services/crush_quota_service.dart';

Future<void> showCrushPacksSheet(BuildContext context) async {
  final quotaService = CrushQuotaService.to;
  await quotaService.loadPacks();

  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _CrushPacksSheetContent(),
  );
}

class _CrushPacksSheetContent extends StatelessWidget {
  const _CrushPacksSheetContent();

  @override
  Widget build(BuildContext context) {
    final quotaService = CrushQuotaService.to;
    final purchaseCtrl = Get.put(CrushPurchaseController());

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 32),
          const SizedBox(height: 10),
          const Text(
            'Vous avez atteint votre quota de messages gratuits',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Obx(() {
            final q = quotaService.status.value;
            return Text(
              q.bonusCredits > 0
                  ? 'Il vous reste ${q.bonusCredits} messages bonus.'
                  : 'Rechargez pour continuer à écrire dès maintenant.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            );
          }),
          const SizedBox(height: 18),
          Obx(() {
            if (quotaService.isLoadingPacks.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final packs = quotaService.packs;
            if (packs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Aucun pack disponible pour le moment.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              );
            }
            return Column(
              children: packs
                  // Sur iOS, un pack sans apple_product_id ne peut légalement
                  // pas être vendu (Apple Guideline 3.1.1) : on le masque.
                  // Sur les autres plateformes, tous les packs restent
                  // vendables via Moneroo.
                  .where((p) => (!kIsWeb && Platform.isIOS)
                      ? p.isPurchasableOnCurrentPlatform
                      : true)
                  .map(
                    (pack) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PackTile(pack: pack, ctrl: purchaseCtrl),
                    ),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _PackTile extends StatelessWidget {
  final MessageCreditPack pack;
  final CrushPurchaseController ctrl;
  const _PackTile({required this.pack, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pack.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(
                    '${pack.credits} messages',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: ctrl.isPurchasing.value
                  ? null
                  : () => ctrl.purchasePack(context: context, pack: pack),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              child: ctrl.isPurchasing.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      '${pack.price.toInt()} FCFA',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
