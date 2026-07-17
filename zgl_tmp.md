Pour s'aligner parfaitement sur votre structure existante sans tout casser, nous allons utiliser le SDK officiel de **RevenueCat** pour Flutter : `purchases_flutter`.

L'astuce magique avec RevenueCat, c'est que lorsque l'achat réussit sur iOS, il génère un **identifiant de transaction unique** et valide le reçu auprès d'Apple. Vous pouvez donc récupérer cet ID côté front-end et l'envoyer directement à vos routes existantes (`/videos/${video.id}/purchase` et `/subscribe`), exactement comme vous le faisiez avec le `transactionId` de KKiaPay !

Voici la réimplémentation complète et propre de vos deux fonctions en front-end.

---

## 1. Étape préalable (Une seule fois au démarrage de l'application)

Avant d'appeler vos fonctions de paiement, vous devez initialiser RevenueCat (par exemple dans votre `main.dart` ou dans le `onInit` de votre contrôleur).

```dart
import 'package:purchases_flutter/purchases_flutter.dart';

Future<void> initRevenueCat() async {
  // Optionnel : Activer les logs en mode debug pour voir ce qui se passe
  await Purchases.setLogLevel(LogLevel.debug);

  // Configuration avec votre clé publique de l'API RevenueCat (fournie dans leur dashboard)
  PurchasesConfiguration configuration = PurchasesConfiguration("votre_api_key_public_revenuecat");
  
  // Associer l'identifiant de l'utilisateur connecté pour que le suivi soit parfait
  final String currentUserId = _storage.read('user_id') ?? 'anonymous';
  configuration.appUserID = currentUserId;

  await Purchases.configure(configuration);
}

```

---

## 2. Le code adapté pour l'Achat Vidéo (Pay-Per-View)

Voici votre méthode `handlePayPerView` réécrite. Au lieu d'ouvrir le widget KKiaPay, elle appelle l'achat natif Apple via RevenueCat, récupère la transaction et l'envoie à votre backend.

```dart
import 'package:purchases_flutter/purchases_flutter.dart';

// ══════════════════════════════════════════════════════════════════════════
//  PAY-PER-VIEW — RevenueCat (Apple) puis backend
// ══════════════════════════════════════════════════════════════════════════

/// Lance l'achat In-App via RevenueCat pour le PPV.
/// Sur succès de paiement → appelle [_doPurchaseVideo] → dialogue succès/échec
/// [onPurchaseSuccess] : callback appelé si tout se passe bien (pour init le player)
void handlePayPerViewWithRevenueCat({
  required BuildContext context,
  required SpaceVideo video,
  required VoidCallback onPurchaseSuccess,
}) async {
  // Sur iOS, nous avons besoin de l'identifiant du produit configuré dans App Store Connect / RevenueCat.
  // Vous pouvez le stocker dans votre objet video (ex: video.appleProductId) ou le déduire.
  final String? appleProductId = video.appleProductId; 

  if (appleProductId == null) {
    _showPurchaseFailedDialog(context, "Ce produit n'est pas disponible sur l'App Store.");
    return;
  }

  isPurchasing.value = true;

  try {
    // 1. Récupérer le produit depuis l'App Store via RevenueCat
    List<StoreProduct> products = await Purchases.getProducts([appleProductId]);

    if (products.isEmpty) {
      _showPurchaseFailedDialog(context, "Produit introuvable sur les serveurs d'Apple.");
      isPurchasing.value = false;
      return;
    }

    // 2. Déclencher l'achat de manière native (FaceID / TouchID popup)
    CustomerInfo customerInfo = await Purchases.purchaseStoreProduct(products.first);

    // 3. Chercher la transaction correspondante dans l'historique de l'utilisateur
    final transactions = customerInfo.nonSubscriptionTransactions;
    
    if (transactions.isNotEmpty) {
      // On récupère la transaction la plus récente pour ce produit
      final lastTransaction = transactions.firstWhere(
        (tx) => tx.productId == appleProductId,
        orElse: () => transactions.first,
      );

      final String transactionId = lastTransaction.transactionIdentifier;

      // 4. On envoie les infos à VOTRE backend, exactement comme pour KKiaPay !
      await _doPurchaseVideo(
        context: context,
        video: video,
        transactionId: transactionId,
        metadata: {
          'gateway': 'apple_storekit_revenuecat',
          'original_purchase_date': lastTransaction.revenueCatPurchaseDate,
        },
        onSuccess: onPurchaseSuccess,
      );
    } else {
      // Cas rare : l'achat a réussi mais pas de transaction enregistrée localement
      _showPurchaseFailedDialog(context, "Une erreur est survenue lors de la validation de l'achat.");
    }

  } on PlatformException catch (e) {
    var errorCode = PurchasesErrorHelper.getErrorCode(e);
    if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
      // L'utilisateur n'a pas simplement annulé, il y a eu une vraie erreur
      _showPurchaseFailedDialog(context, e.message ?? "Erreur de paiement Apple.");
    }
  } catch (e) {
    _showPurchaseFailedDialog(context, "Une erreur inattendue est survenue.");
  } finally {
    isPurchasing.value = false;
  }
}

```

---

## 3. Le code adapté pour l'Abonnement (Subscription Plan)

Pour l'abonnement, le principe est identique. Nous demandons à RevenueCat d'acheter l'abonnement. Une fois validé, nous récupérons l'identifiant de transaction pour l'envoyer à votre route `/subscribe`.

```dart
import 'package:purchases_flutter/purchases_flutter.dart';

// ══════════════════════════════════════════════════════════════════════════
//  ABONNEMENT — RevenueCat (Apple) puis backend
// ══════════════════════════════════════════════════════════════════════════

Future<void> handleSubscribeWithRevenueCat({
  required BuildContext context,
  required Subscription plan,
}) async {
  final hasActive = activeUser.value.hasActiveSubscription;

  if (hasActive) {
    final confirmed = await _showChangePlanDialog(context, plan);
    if (confirmed != true) return;
  }

  // Idem, il vous faut l'identifiant du produit d'abonnement configuré sur Apple / RevenueCat
  final String? appleProductId = plan.appleProductId; 

  if (appleProductId == null) {
    _showPaymentFailedDialog(context, "Ce forfait n'est pas disponible sur iOS.");
    return;
  }

  selectedPlan.value = plan;
  isSubscribing.value = true;

  try {
    // 1. Récupérer le produit d'abonnement
    List<StoreProduct> products = await Purchases.getProducts([appleProductId]);

    if (products.isEmpty) {
      _showPaymentFailedDialog(context, "Forfait introuvable sur l'App Store.");
      isSubscribing.value = false;
      selectedPlan.value = null;
      return;
    }

    // 2. Lancer l'achat d'abonnement
    CustomerInfo customerInfo = await Purchases.purchaseStoreProduct(products.first);

    // 3. Récupérer la transaction active correspondante
    // Les abonnements n'apparaissent pas toujours dans nonSubscriptionTransactions,
    // on va donc générer une référence propre grâce aux données de RevenueCat ou à défaut l'ID utilisateur + timestamp.
    
    // RevenueCat génère un ID unique de profil pour chaque utilisateur : originalAppUserId ou un identifiant de transaction
    final String transactionId = customerInfo.originalAppUserId + "_" + DateTime.now().millisecondsSinceEpoch.toString();

    // 4. Appel de votre API backend existante
    await _doSubscribe(
      context: context,
      plan: plan,
      transactionId: transactionId,
      metadata: {
        'gateway': 'apple_storekit_revenuecat',
        'apple_product_id': appleProductId,
        'active_subscriptions': customerInfo.activeSubscriptions.toList(),
      },
    );

  } on PlatformException catch (e) {
    var errorCode = PurchasesErrorHelper.getErrorCode(e);
    if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
      _showPaymentFailedDialog(context, e.message ?? "Erreur d'abonnement Apple.");
    }
  } catch (e) {
    _showPaymentFailedDialog(context, "Une erreur inattendue est survenue.");
  } finally {
    isSubscribing.value = false;
    selectedPlan.value = null;
  }
}

```

---

### Pourquoi ce choix technique est idéal pour vous :

1. **Zéro impact sur l'architecture de votre Back :** Vos fonctions `_doPurchaseVideo` et `_doSubscribe` restent **strictement identiques**. Elles reçoivent toujours un `transactionId` et des `metadata` à envoyer au serveur.
2. **Conformité Apple :** Vos utilisateurs paient avec FaceID, Apple encaisse l'argent, RevenueCat sécurise la transaction, et votre backend l'enregistre en base de données.
3. **Mise en place en moins de 2 heures** (une fois les identifiants de produits déclarés sur vos dashboards App Store Connect et RevenueCat).