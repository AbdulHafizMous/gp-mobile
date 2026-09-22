// lib/app/modules/social/controllers/crush_purchase_controller.dart
//
// Gère l'achat d'un pack de messages Crush, à l'identique du pattern déjà
// utilisé pour les abonnements (social_premium_controller.dart) et le
// pay-per-view vidéo (videos_controller.dart) :
//   - iOS  → RevenueCat / StoreKit (obligatoire, Apple Guideline 3.1.1)
//   - autres plateformes → Moneroo natif
//
// Toute cette logique est un no-op silencieux si CrushQuotaService.isEnabled
// est false : ce contrôleur n'est de toute façon jamais sollicité dans ce
// cas (voir CrushQuotaBanner / CrushPacksSheet, qui ne s'affichent pas).

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/message_credit_pack_model.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/crush_quota_service.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/api_error_helper.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:moneroo_flutter_sdk/moneroo_flutter_sdk.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class CrushPurchaseController extends GetxController {
  final isPurchasing = false.obs;

  Future<void> purchasePack({
    required BuildContext context,
    required MessageCreditPack pack,
  }) {
    if (!kIsWeb && Platform.isIOS) {
      return _purchaseWithRevenueCat(context: context, pack: pack);
    }
    return _purchaseWithMoneroo(context: context, pack: pack);
  }

  // ══════════════════════════════════════════════════════════════════════
  //  RevenueCat (Apple StoreKit) — iOS uniquement
  // ══════════════════════════════════════════════════════════════════════
  Future<void> _purchaseWithRevenueCat({
    required BuildContext context,
    required MessageCreditPack pack,
  }) async {
    if (!pack.isPurchasableOnCurrentPlatform) {
      ToastHelper.showToast(
        "Ce pack n'est pas encore disponible sur l'App Store.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    isPurchasing.value = true;
    try {
      final products = await Purchases.getProducts([pack.appleProductId!]);
      if (products.isEmpty) {
        ToastHelper.showToast(
          'Pack introuvable sur l\'App Store.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      final result = await Purchases.purchase(
        PurchaseParams.storeProduct(products.first),
      );
      final transactionId = result.storeTransaction.transactionIdentifier;

      await _confirmPurchaseBackend(
        pack: pack,
        transactionId: transactionId,
        gateway: 'apple_storekit_revenuecat',
      );
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        ToastHelper.showToast(
          e.message ?? 'Le paiement Apple a échoué. Réessayez.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('RevenueCat crush pack purchase error: $e');
      ToastHelper.showToast(
        'Une erreur inattendue est survenue.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      isPurchasing.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Moneroo natif (Android / autres plateformes)
  // ══════════════════════════════════════════════════════════════════════
  Future<void> _purchaseWithMoneroo({
    required BuildContext context,
    required MessageCreditPack pack,
  }) async {
    Get.to(
      () => Moneroo(
        amount: pack.price.toInt(),
        apiKey: MONEROO_API_KEY,
        currency: MonerooCurrency.XOF,
        customer: MonerooCustomer(
          email: activeUser.value.email,
          firstName: activeUser.value.firstName,
          lastName: activeUser.value.lastName,
        ),
        description: pack.name,
        onPaymentCompleted: (infos, ctx) async {
          try {
            if (infos.status == MonerooStatus.success) {
              try {
                Navigator.of(ctx).pop();
              } catch (_) {}
              await _confirmPurchaseBackend(
                pack: pack,
                transactionId: infos.id.toString(),
                gateway: 'moneroo',
              );
            } else if (infos.status == MonerooStatus.cancelled) {
              try {
                Navigator.of(ctx).pop();
              } catch (_) {}
            } else {
              debugPrint('Moneroo crush pack EVENT: ${infos.status}');
            }
          } catch (e) {
            debugPrint('Moneroo crush pack callback error: $e');
          }
        },
        onError: (error, context) {
          debugPrint('Moneroo CRUSH PACK ERROR: $error');
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Confirmation backend (commune aux deux gateways)
  // ══════════════════════════════════════════════════════════════════════
  Future<void> _confirmPurchaseBackend({
    required MessageCreditPack pack,
    required String transactionId,
    required String gateway,
  }) async {
    try {
      final res = await RequestService().post(
        '/crush/packs/${pack.id}/confirm',
        data: {'payment_id': transactionId, 'gateway': gateway},
      );
      final quotaJson = res.data?['data'];
      if (quotaJson != null) {
        await CrushQuotaService.to.onPackPurchaseConfirmed(quotaJson);
      }
      ToastHelper.showToast(
        '${pack.credits} messages ajoutés à votre solde !',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } on DioException catch (e) {
      ApiErrorHelper.showError(e);
    }
  }
}
