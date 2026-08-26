// lib/app/modules/diagnostics/iap_diagnostics_view.dart
//
// Écran de diagnostic RevenueCat/StoreKit. Ouvre-le sur un vrai iPhone
// (même emprunté) pour voir exactement ce qui bloque, sans avoir besoin
// d'un Mac ou de la console Xcode. Tout est affiché à l'écran et copiable.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/subscription.dart';
import 'package:grand_public_v2/app/modules/social_premium/controllers/social_premium_controller.dart';
import 'package:grand_public_v2/app/services/iap_debug_logger.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class IapDiagnosticsView extends StatefulWidget {
  const IapDiagnosticsView({super.key});

  @override
  State<IapDiagnosticsView> createState() => _IapDiagnosticsViewState();
}

class _IapDiagnosticsViewState extends State<IapDiagnosticsView> {
  final _customIdController = TextEditingController();
  bool _isTesting = false;
  List<Subscription> _plans = [];

  @override
  void dispose() {
    _customIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = !kIsWeb && Platform.isIOS;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Paiement (IAP)'),
        backgroundColor: GPTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copier tous les logs',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: IapDebugLogger.allAsText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logs copiés dans le presse-papiers')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Effacer les logs',
            onPressed: () => IapDebugLogger.clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: isIOS ? Colors.green.shade50 : Colors.orange.shade50,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plateforme : ${kIsWeb ? "Web" : Platform.operatingSystem}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (!isIOS)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "⚠️ RevenueCat/StoreKit n'est initialisé que sur iOS. "
                      "Sur cet appareil, les tests ci-dessous ne feront rien "
                      "de réel — ouvre cet écran sur un iPhone pour un vrai diagnostic.",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : _checkConfiguration,
                  icon: const Icon(Icons.settings_ethernet, size: 18),
                  label: const Text('Vérifier la config'),
                ),
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testFetchPlans,
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: const Text('Tester les 3 plans Premium'),
                ),
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testCustomerInfo,
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('Voir CustomerInfo'),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customIdController,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Product ID à tester manuellement',
                      hintText: 'ex: com.maxafrica.gpbenin.ppv500',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isTesting ? null : _testCustomProductId,
                  child: const Text('Tester'),
                ),
              ],
            ),
          ),

          if (_isTesting) const LinearProgressIndicator(minHeight: 2),

          const Divider(height: 24),

          Expanded(
            child: Obx(() {
              if (IapDebugLogger.logs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      "Aucun log pour l'instant. Lance un test ci-dessus, "
                      "ou relance l'app pour voir les logs d'initialisation.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: IapDebugLogger.logs.length,
                itemBuilder: (ctx, i) {
                  final line = IapDebugLogger.logs[i];
                  final isError = line.contains('❌');
                  final isSuccess = line.contains('✅');
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: SelectableText(
                      line,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        color: isError
                            ? Colors.red.shade700
                            : isSuccess
                                ? Colors.green.shade700
                                : Colors.black87,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _checkConfiguration() async {
    setState(() => _isTesting = true);
    IapDebugLogger.log('── Vérification config ──────────────────');
    IapDebugLogger.log('REVENUECAT_IOS_API_KEY défini : '
        '${REVENUECAT_IOS_API_KEY.isNotEmpty && !REVENUECAT_IOS_API_KEY.contains("REPLACE_WITH")}');
    try {
      final isConfigured = await Purchases.isConfigured;
      IapDebugLogger.log('Purchases.isConfigured = $isConfigured');
      if (!isConfigured) {
        IapDebugLogger.log(
          '❌ RevenueCat n\'est pas configuré. Sur iOS, ça ne devrait '
          'jamais arriver — vérifie main.dart / _initRevenueCat().',
        );
      }
    } catch (e) {
      IapDebugLogger.log('❌ Erreur en vérifiant isConfigured : $e');
    }
    setState(() => _isTesting = false);
  }

  Future<void> _testFetchPlans() async {
    setState(() => _isTesting = true);
    IapDebugLogger.log('── Test des 3 plans Premium ─────────────');
    try {
      final ctrl = Get.isRegistered<SocialPremiumController>()
          ? Get.find<SocialPremiumController>()
          : Get.put(SocialPremiumController());
      _plans = await ctrl.fetchSubscriptions();
      IapDebugLogger.log('${_plans.length} plan(s) récupéré(s) depuis le backend.');

      for (final plan in _plans) {
        final id = plan.appleProductId;
        IapDebugLogger.log('Plan "${plan.name}" → apple_product_id = "$id"');
        if (id == null || id.isEmpty) {
          IapDebugLogger.log('  ❌ Champ apple_product_id vide côté admin pour ce plan.');
          continue;
        }
        await _testProductId(id);
      }
    } catch (e) {
      IapDebugLogger.log('❌ Erreur fetchSubscriptions : $e');
    }
    setState(() => _isTesting = false);
  }

  Future<void> _testCustomProductId() async {
    final id = _customIdController.text.trim();
    if (id.isEmpty) return;
    setState(() => _isTesting = true);
    IapDebugLogger.log('── Test manuel : "$id" ───────────────────');
    await _testProductId(id);
    setState(() => _isTesting = false);
  }

  Future<void> _testProductId(String id) async {
    try {
      final products = await Purchases.getProducts([id]);
      if (products.isEmpty) {
        IapDebugLogger.log('  ❌ "$id" → 0 produit retourné par StoreKit.');
      } else {
        for (final p in products) {
          IapDebugLogger.log(
            '  ✅ "$id" → ${p.identifier} | ${p.title} | ${p.priceString}',
          );
        }
      }
    } catch (e) {
      IapDebugLogger.log('  ❌ Exception sur "$id" : $e');
    }
  }

  Future<void> _testCustomerInfo() async {
    setState(() => _isTesting = true);
    IapDebugLogger.log('── CustomerInfo ──────────────────────────');
    try {
      final info = await Purchases.getCustomerInfo();
      IapDebugLogger.log('originalAppUserId = ${info.originalAppUserId}');
      IapDebugLogger.log(
        'entitlements actifs = ${info.entitlements.active.keys.toList()}',
      );
      IapDebugLogger.log(
        'abonnements actifs = ${info.activeSubscriptions.toList()}',
      );
    } catch (e) {
      IapDebugLogger.log('❌ Erreur getCustomerInfo : $e');
    }
    setState(() => _isTesting = false);
  }
}
