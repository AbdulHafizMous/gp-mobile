// lib/app/modules/pages/premium_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/sub_card.dart';
import 'package:grand_public_v2/app/data/models/subscription.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/social_premium/controllers/social_premium_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  List<Subscription> subscriptions = [];

  final controller = Get.put(SocialPremiumController());

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            'PREMIUM',
            style: TextStyle(
              fontSize: 30,
              color: GPTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: Text(
              "Accédez à des fonctionnalités exclusives en vous abonnant ! Choisissez le plan qui vous convient et profitez d'un accès illimité à nos contenus vidéos exclusifs.",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // ── Bannière abonnement actif (s'affiche uniquement si abonné) ─
          Obx(() {
            final user = activeUser.value;
            if (!user.hasActiveSubscription) {
              return const SizedBox.shrink();
            }
            final sub = user.activeSubscription!;
            return Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    GPTheme.primaryColor.withOpacity(0.12),
                    GPTheme.primaryColor.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: GPTheme.primaryColor.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: GPTheme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan actif - ${sub.plan?.name ?? 'Premium'}',
                          style: TextStyle(
                            color: GPTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Expire le ${sub.formattedExpiry}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ACTIF',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // ── Liste des plans (design original intact) ───────────────────
          FutureBuilder<List<Subscription>>(
            future: controller.fetchSubscriptions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Erreur lors du chargement des abonnements'),
                );
              }
              if (snapshot.hasData) {
                subscriptions = snapshot.data!;
                debugPrint(
                  "Act Use : ${activeUser.value.toJson()} ---  ${activeUser.value.activeSubscription?.plan?.name}  --- ok",
                );
                return Container(
                  height: 415,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  width: MediaQuery.of(context).size.width,
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 20),
                    itemCount: subscriptions.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      // Obx pour réagir aux changements du user (plan actif)
                      return Obx(() {
                        final activePlanId =
                            activeUser.value.activeSubscription?.plan?.id;
                        final hasActive =
                            activeUser.value.hasActiveSubscription;
                        debugPrint(
                          "Subs ${subscriptions[index].name} : --- $activePlanId --- $hasActive --- ${subscriptions[index].toString()}",
                        );

                        return SubCard(
                          subscription: subscriptions[index],
                          isActivePlan: activePlanId == subscriptions[index].id,
                          hasActiveSubscription: hasActive,
                        );
                      });
                    },
                  ),
                );
              }
              return const Center(child: Text('Aucun abonnement disponible'));
            },
          ),

          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: Text(
              "Rejoignez Grand Public et vivez l'expérience sans limite",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
