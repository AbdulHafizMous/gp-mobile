import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
  
import 'app/routes/app_pages.dart';

import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/modules/profile/controllers/profile_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

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
