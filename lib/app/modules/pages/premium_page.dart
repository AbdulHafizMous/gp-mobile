import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/sub_card.dart';
import 'package:grand_public_v2/app/data/models/subscription.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  List<Subscription> subscriptions = [];

  final controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
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
            child: const Text(
              "Accédez à des fonctionnalités exclusives en vous abonnant ! Choisissez le plan qui vous contient et provitez d'un accès illimité à nos contenus videos exclusifs.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          FutureBuilder(
            future: controller.fetchSubscriptions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Erreur lors du chargementp des abonnements'),
                );
              }
              if (snapshot.hasData) {
                subscriptions = snapshot.data as List<Subscription>;
                return Container(
                  height: 450,
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
                      return SubCard(subscription: subscriptions[index]);
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
            child: const Text(
              "Rejoignez Grand Public et vivez l'expérience sans limite",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
