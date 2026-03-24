import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:grand_public_v2/app/services/notification_service.dart';
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

  // 5. Notifications
  await NotificationService.init();


  // Tests Notification

  // Depuis le front (dev uniquement)
  // await FCMService.sendFCMNotifFromFront(
  //   fcmToken: 'TOKEN_DESTINATAIRE',
  //   title: 'Nouvelle commande',
  //   body: 'Votre commande #123 est confirmée',
  //   data: {'route': '/orders/123', 'order_id': '123'},
  // );

  // // Depuis le back (recommandé en prod)
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
  //   useBackend: true,
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
        title: "Grand Public",
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
