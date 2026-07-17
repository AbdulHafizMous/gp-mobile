// lib/app/modules/social_premium/controllers/social_premium_controller.dart

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/subscription.dart';
import 'package:grand_public_v2/app/data/models/user.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/services/web_account_link_service.dart';
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
  //  ABONNEMENT — redirection vers le site web pour le paiement
  //  (Apple Guideline 3.1.1 : plus de paiement in-app pour du contenu digital)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> handleSubscribeOnWeb({
    required BuildContext context,
    required Subscription plan,
  }) async {
    final hasActive = activeUser.value.hasActiveSubscription;

    if (hasActive) {
      final confirmed = await _showChangePlanDialog(context, plan);
      if (confirmed != true) return;
    } else {
      final confirmed = await _showRedirectToWebDialog(context, plan);
      if (confirmed != true) return;
    }

    selectedPlan.value = plan;
    isSubscribing.value = true;
    try {
      await WebAccountLinkService.openWebAccount(
        intent: 'subscribe',
        planId: plan.id,
      );
    } finally {
      isSubscribing.value = false;
      selectedPlan.value = null;
      // Rafraîchit au mieux l'état (utile si l'utilisateur avait déjà payé
      // récemment sur le site avant de revenir sur cet écran).
      unawaited(_refreshActiveUser());
      unawaited(fetchMySubscriptions());
    }
  }

  Future<bool?> _showRedirectToWebDialog(
    BuildContext context,
    Subscription plan,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.open_in_new_rounded, color: GPTheme.primaryColor),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Paiement sur le site',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Pour souscrire au plan "${plan.name}" (${plan.price.toStringAsFixed(0)} FCFA), '
          'vous allez être redirigé vers notre site pour finaliser le paiement en '
          'toute sécurité. Vous serez automatiquement connecté(e).',
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
              'Votre abonnement actuel sera remplacé si vous continuez. '
              'Vous allez être redirigé(e) vers notre site pour passer au plan '
              '"${newPlan.name}" (${newPlan.price.toStringAsFixed(0)} FCFA).',
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
