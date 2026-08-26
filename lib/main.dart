import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
// import 'package:grand_public_v2/app/services/notification_service.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/services/iap_debug_logger.dart';
import 'package:grand_public_v2/firebase_options.dart';

import 'app/routes/app_pages.dart';

import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/modules/profile/controllers/profile_controller.dart';

// ── Background handler (doit être top-level, pas dans une classe) ────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message: ${message.messageId}');
  debugPrint('Titre: ${message.notification?.title}');
}

/// Initialise RevenueCat (StoreKit) — nécessaire uniquement sur iOS pour
/// rester conforme à la Guideline 3.1.1 d'Apple (contenu payant = IAP).
Future<void> _initRevenueCat() async {
  IapDebugLogger.log('_initRevenueCat: démarrage');
  try {
    await Purchases.setLogLevel(LogLevel.debug);
    IapDebugLogger.log('Purchases.setLogLevel(debug) OK');

    final keyPreview = REVENUECAT_IOS_API_KEY.length > 12
        ? '${REVENUECAT_IOS_API_KEY.substring(0, 8)}...${REVENUECAT_IOS_API_KEY.substring(REVENUECAT_IOS_API_KEY.length - 4)}'
        : REVENUECAT_IOS_API_KEY;
    IapDebugLogger.log('Clé API utilisée : $keyPreview');
    if (REVENUECAT_IOS_API_KEY.isEmpty ||
        REVENUECAT_IOS_API_KEY.contains('REPLACE_WITH')) {
      IapDebugLogger.log(
        '⚠️ ALERTE : REVENUECAT_IOS_API_KEY est vide ou est encore le placeholder !',
      );
    }

    final configuration = PurchasesConfiguration(REVENUECAT_IOS_API_KEY);
    final userId = GetStorage().read<String>('user_id');
    if (userId != null && userId.isNotEmpty) {
      configuration.appUserID = userId;
      IapDebugLogger.log('appUserID configuré : $userId');
    } else {
      IapDebugLogger.log('appUserID non défini (utilisateur anonyme RevenueCat)');
    }

    await Purchases.configure(configuration);
    IapDebugLogger.log('✅ Purchases.configure() terminé sans erreur');

    final isConfigured = await Purchases.isConfigured;
    IapDebugLogger.log('Purchases.isConfigured = $isConfigured');
  } catch (e, st) {
    IapDebugLogger.log('❌ ERREUR _initRevenueCat : $e');
    debugPrint('_initRevenueCat error: $e\n$st');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Google Sign-In (initialise avec le Web Client ID)
  await GoogleSignIn.instance.initialize(
    serverClientId:
        '530288780124-v2m5pomu1iih003inicssigo0eqhrlup.apps.googleusercontent.com',
  );

  // 4. GetStorage
  await GetStorage.init();

  // 4bis. RevenueCat (Apple IAP — Guideline 3.1.1). iOS uniquement :
  // Android/le reste continuent d'utiliser Kkiapay / le paiement web.
  IapDebugLogger.log(
    'Platform check : kIsWeb=$kIsWeb, Platform.isIOS=${kIsWeb ? "n/a" : Platform.isIOS}',
  );
  if (!kIsWeb && Platform.isIOS) {
    await _initRevenueCat();
  } else {
    IapDebugLogger.log('RevenueCat NON initialisé (pas iOS) — normal sur Android.');
  }

  // 5. Notifications (Done in Main Page Ctrl)
  // await NotificationService.init();

  // Tests Notification (envoi via le backend uniquement — voir note
  // sécurité dans fcm_service.dart)
  // await FCMService.sendFCMNotifFromBack(
  //   fcmToken: 'TOKEN_DESTINATAIRE',
  //   title: 'Nouvelle commande',
  //   body: 'Votre commande #123 est confirmée',
  //   data: {'route': '/orders/123'},
  // );

  // // Envoyer à l'utilisateur connecté
  // await FCMService.sendToCurrentUser(
  //   title: 'Bienvenue !',
  //   body: 'Connexion réussie',
  // );

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final theme = GPTheme.light();
  final darktheme = GPTheme.dark();
  final controller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        title: "Grand Public Bénin",
        theme: controller.isDark.value ? darktheme : theme,
        // darkTheme: darktheme,
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        onUnknownRoute: (settings) {
          return GetPageRoute(
            page: () => Scaffold(
              body: Center(
                child: Text('No route defined for ${settings.name}'),
              ),
            ),
          );
        },
      ),
    );
  }
}
