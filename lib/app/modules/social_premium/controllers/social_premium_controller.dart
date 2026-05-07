// lib/app/modules/social_premium/controllers/social_premium_controller.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kkiapay_flutter_sdk/kkiapay_flutter_sdk.dart';
import 'package:uuid/uuid.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/subscription.dart';
import 'package:grand_public_v2/app/data/models/user.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class SocialPremiumController extends GetxController {
  // ── État ───────────────────────────────────────────────────────────────────
  final subscriptions = <Subscription>[].obs;
  final isLoadingSubscriptions = false.obs;
  final isSubscribing = false.obs;
  final selectedPlan = Rxn<Subscription>();

  // ── Historique des abonnements ─────────────────────────────────────────────
  final subscriptionHistory = <ActiveSubscription>[].obs;
  final isLoadingHistory = false.obs;

  final _uuid = const Uuid();
  final _storage = GetStorage();

  // ══════════════════════════════════════════════════════════════════════════
  //  FETCH PLANS DISPONIBLES
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Subscription>> fetchSubscriptions() async {
    isLoadingSubscriptions.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 300));
        subscriptions.value = _mockPlans();
        return subscriptions;
      }

      final response = await RequestService().get('/subscription-plans');
      if (response.statusCode == 200) {
        final data =
            response.data['data']['subscription_plans'] as List<dynamic>;
        subscriptions.value = data
            .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return subscriptions;
    } on DioException catch (e) {
      _handleDioError(e);
      return [];
    } catch (e) {
      debugPrint('fetchSubscriptions error: $e');
      ToastHelper.showToast(
        'Impossible de charger les abonnements.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return [];
    } finally {
      isLoadingSubscriptions.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FETCH HISTORIQUE DES ABONNEMENTS — GET /api/my-subscriptions
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<ActiveSubscription>> fetchMySubscriptions() async {
    isLoadingHistory.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 600));
        subscriptionHistory.value = _mockHistory();
        return subscriptionHistory;
      }

      final response = await RequestService().get('/my-subscriptions');
      if (response.statusCode == 200) {
        final data = response.data['data']['subscriptions'] as List<dynamic>;
        subscriptionHistory.value = data
            .map((e) => ActiveSubscription.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return subscriptionHistory;
    } on DioException catch (e) {
      _handleDioError(e);
      return [];
    } catch (e) {
      debugPrint('fetchMySubscriptions error: $e');
      ToastHelper.showToast(
        'Impossible de charger l\'historique.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return [];
    } finally {
      isLoadingHistory.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  POINT D'ENTRÉE KKIAPAY
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> handleSubscribeWithKkiapay({
    required BuildContext context,
    required Subscription plan,
  }) async {
    final hasActive = activeUser.value.hasActiveSubscription;

    if (hasActive) {
      final confirmed = await _showChangePlanDialog(context, plan);
      if (confirmed != true) return;
    }

    selectedPlan.value = plan;

    final kkiapay = KKiaPay(
      callback: (dynamic response, BuildContext ctx) async {
        debugPrint('kkiapay callback: $response');
        final status = response['status']?.toString() ?? '';
        try {
          switch (status) {
            case 'PAYMENT_CANCELLED':
              try {
                Get.back();
              } catch (_) {}
              break;
            case 'PAYMENT_SUCCESS':
              try {
                Get.back();
              } catch (_) {}
              final transactionId = response['transactionId']?.toString() ?? '';
              final amount = response['requestData']?['amount'];
              await _doSubscribe(
                context: context,
                plan: plan,
                transactionId: transactionId,
                metadata: {'amount': amount, 'kkiapay_response': response},
              );
              break;
            default:
              debugPrint('KKiaPay EVENT: $status');
          }
        } catch (e) {
          debugPrint('KKiaPay callback error: $e');
        }
      },
      amount: plan.price.toInt(),
      apikey: FEEX_API_KEY,
      sandbox: true,
      data: jsonEncode({'trans_key': _uuid.v4(), 'subscription_id': plan.id}),
      phone: _storage.read('phone') ?? '',
      name: _storage.read('username') ?? '',
      reason: plan.name,
      email: _storage.read('email') ?? '',
      countries: const ['BJ'],
    );

    Get.to(() => kkiapay);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  APPEL API BACKEND
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _doSubscribe({
    required BuildContext context,
    required Subscription plan,
    required String transactionId,
    Map<String, dynamic>? metadata,
  }) async {
    isSubscribing.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(seconds: 1));
        final mockSub = ActiveSubscription(
          id: DateTime.now().millisecondsSinceEpoch,
          paymentRef: transactionId,
          startsAt: DateTime.now(),
          endsAt: DateTime.now().add(Duration(days: plan.durationMonths * 30)),
          isActive: true,
          plan: SubscriptionPlan(
            id: plan.id,
            name: plan.name,
            description: plan.shortDescription,
            price: plan.price,
            durationMonths: plan.durationMonths,
          ),
        );
        // Désactiver l'ancien abonnement dans l'historique mock
        final updatedHistory = subscriptionHistory
            .map(
              (s) => s.isActive
                  ? ActiveSubscription(
                      id: s.id,
                      paymentRef: s.paymentRef,
                      startsAt: s.startsAt,
                      endsAt: s.endsAt,
                      cancelledAt: DateTime.now(),
                      isActive: false,
                      plan: s.plan,
                    )
                  : s,
            )
            .toList();
        subscriptionHistory.value = [mockSub, ...updatedHistory];
        activeUser.value = activeUser.value.copyWith(
          activeSubscription: mockSub,
        );
        if (context.mounted) _showPaymentSuccessDialog(context, plan);
        return;
      }

      final response = await RequestService().post(
        '/subscribe',
        data: {
          'subscription_plan_id': plan.id,
          'payment_ref': transactionId,
          'payment_data': ?metadata,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _refreshActiveUser();
        // Rafraîchir aussi l'historique
        await fetchMySubscriptions();
        if (context.mounted) _showPaymentSuccessDialog(context, plan);
      } else {
        final message =
            response.data['message']?.toString() ?? 'Une erreur est survenue.';
        if (context.mounted) _showPaymentFailedDialog(context, message);
      }
    } on DioException catch (e) {
      final reason =
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Erreur réseau';
      if (context.mounted) _showPaymentFailedDialog(context, reason);
    } catch (e) {
      if (context.mounted) {
        _showPaymentFailedDialog(
          context,
          'Une erreur inattendue est survenue.',
        );
      }
    } finally {
      isSubscribing.value = false;
      selectedPlan.value = null;
    }
  }

  Future<void> _refreshActiveUser() async {
    try {
      final response = await RequestService().get('/auth/me');
      if (response.statusCode == 200) {
        activeUser.value = User.fromJson(
          response.data['data']['user'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('_refreshActiveUser error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DIALOGUES
  // ══════════════════════════════════════════════════════════════════════════

  Future<bool?> _showChangePlanDialog(
    BuildContext context,
    Subscription newPlan,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: GPTheme.primaryColor),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Changer d\'abonnement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attention !',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre abonnement actuel sera immédiatement désactivé si vous continuez. '
              'Vous passerez au plan "${newPlan.name}" (${newPlan.price.toStringAsFixed(0)} FCFA).',
            ),
            const SizedBox(height: 8),
            const Text(
              'Voulez-vous continuer ?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GPTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  void _showPaymentSuccessDialog(BuildContext context, Subscription plan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.green.shade600,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Paiement réussi !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vous êtes maintenant abonné au plan "${plan.name}". '
              'Profitez de tous nos contenus exclusifs !',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Super, merci !'),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentFailedDialog(BuildContext context, String reason) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cancel_rounded,
                color: Colors.red.shade600,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Paiement échoué',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Réessayer plus tard'),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HELPERS & MOCKS
  // ══════════════════════════════════════════════════════════════════════════

  void _handleDioError(DioException e) {
    final msg = e.response != null
        ? 'Erreur ${e.response?.statusCode}'
        : e.message ?? 'Erreur réseau';
    debugPrint('DioError: $msg');
    ToastHelper.showToast(
      msg,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  List<Subscription> _mockPlans() {
    return [
      const Subscription(
        id: 1,
        name: '1 MOIS',
        shortDescription:
            'Accès illimité à tous nos services pendant 30 jours.',
        duration: '30 jours',
        price: 1000,
        durationMonths: 1,
      ),
      const Subscription(
        id: 2,
        name: '3 MOIS',
        shortDescription:
            'Économisez 10% et profitez de 90 jours d\'accès complet.',
        duration: '90 jours',
        price: 2700,
        durationMonths: 3,
      ),
      const Subscription(
        id: 3,
        name: '12 MOIS',
        shortDescription:
            'Économisez 25% et bénéficiez d\'une année complète d\'exclusivité.',
        duration: '365 jours',
        price: 9000,
        durationMonths: 12,
      ),
    ];
  }

  /// Mock historique — simule plusieurs abonnements passés et un actif
  List<ActiveSubscription> _mockHistory() {
    final now = DateTime.now();
    return [
      // Abonnement actif — 3 MOIS
      ActiveSubscription(
        id: 5,
        paymentRef: 'PAY-REF-2026-005',
        startsAt: now.subtract(const Duration(days: 15)),
        endsAt: now.add(const Duration(days: 75)),
        isActive: true,
        plan: const SubscriptionPlan(
          id: 2,
          name: '3 MOIS',
          description: 'Accès illimité pendant 3 mois',
          price: 2700,
          durationMonths: 3,
        ),
      ),
      // Abonnement terminé — changement de plan (cancelled)
      ActiveSubscription(
        id: 4,
        paymentRef: 'PAY-REF-2026-004',
        startsAt: now.subtract(const Duration(days: 45)),
        endsAt: now.subtract(const Duration(days: 15)),
        cancelledAt: now.subtract(const Duration(days: 15)),
        isActive: false,
        plan: const SubscriptionPlan(
          id: 1,
          name: '1 MOIS',
          description: 'Accès illimité pendant 1 mois',
          price: 1000,
          durationMonths: 1,
        ),
      ),
      // Abonnement expiré naturellement — 12 MOIS
      ActiveSubscription(
        id: 3,
        paymentRef: 'PAY-REF-2025-003',
        startsAt: DateTime(2025, 1, 1),
        endsAt: DateTime(2026, 1, 1),
        isActive: false,
        plan: const SubscriptionPlan(
          id: 3,
          name: '12 MOIS',
          description: 'Une année complète d\'exclusivité',
          price: 9000,
          durationMonths: 12,
        ),
      ),
      // Abonnement expiré — 3 MOIS
      ActiveSubscription(
        id: 2,
        paymentRef: 'PAY-REF-2024-002',
        startsAt: DateTime(2024, 9, 1),
        endsAt: DateTime(2024, 12, 1),
        isActive: false,
        plan: const SubscriptionPlan(
          id: 2,
          name: '3 MOIS',
          description: 'Accès illimité pendant 3 mois',
          price: 2700,
          durationMonths: 3,
        ),
      ),
      // Premier abonnement — 1 MOIS
      ActiveSubscription(
        id: 1,
        paymentRef: 'PAY-REF-2024-001',
        startsAt: DateTime(2024, 8, 1),
        endsAt: DateTime(2024, 9, 1),
        isActive: false,
        plan: const SubscriptionPlan(
          id: 1,
          name: '1 MOIS',
          description: 'Accès illimité pendant 1 mois',
          price: 1000,
          durationMonths: 1,
        ),
      ),
    ];
  }
}
