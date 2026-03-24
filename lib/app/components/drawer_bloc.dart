import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/components/drawer_btn.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class DrawerBloc extends StatefulWidget {
  const DrawerBloc({super.key});

  @override
  State<DrawerBloc> createState() => _DrawerBlocState();
}

class _DrawerBlocState extends State<DrawerBloc> {
  final List<Map<String, String>> drawerItems = [
    {
      "icon": "assets/icons/portrait.png",
      "title": "PORTRAIT",
      "callback": "/portrait",
    },
    {
      "icon": "assets/icons/event.png",
      "title": "EVENTS",
      "callback": "/events",
    },
    {
      "icon": "assets/icons/opinion.png",
      "title": "OPINION",
      "callback": "/opinion",
    },
    {
      "icon": "assets/icons/experience.png",
      "title": "INSOLITE",
      "callback": "/insolite",
    },
    {
      "icon": 'assets/icons/kiff.png',
      "title": "ILS ONT KIFFÉ",
      "callback": "/soon",
    },
    {
      "icon": 'assets/icons/blow.png',
      "title": "BLOW MUSIC",
      "callback": "/soon",
    },
    {
      "icon": 'assets/icons/link.png',
      "title": "LIENS",
      "callback": "/social-link",
    },
    {
      "icon": 'assets/icons/premium.png',
      "title": "PREMIUM",
      "callback": "/social-premium",
    },
    {
      "icon": 'assets/icons/info.png',
      "title": "A PROPOS",
      "callback": "/social-about",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: GPTheme.primaryColor,
      width: MediaQuery.of(context).size.width * 0.7,
      child: ListView(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                InkWell(
                  onTap: () => Get.toNamed('/profile'),
                  child: Image.asset(
                    'assets/images/profile.png',
                    width: 100,
                    height: 100,
                  ),
                ),
                InkWell(
                  onTap: () => Get.toNamed('/profile'),
                  child: Text(
                    GetStorage().read("username") ?? "username",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: GPTheme.primaryColor,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Get.toNamed('/profile'),
                  child: Text(
                    GetStorage().read("email") ?? "user email",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: GPTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const SizedBox(height: 30),
          DrawerBtn(
            icon: drawerItems[0]["icon"] ?? "",
            title: drawerItems[0]["title"] ?? "",
            callback: () => Get.toNamed(drawerItems[0]["callback"] ?? ""),
          ),
          const SizedBox(height: 10),
          DrawerBtn(
            icon: drawerItems[1]["icon"] ?? "",
            title: drawerItems[1]["title"] ?? "",
            callback: () => Get.toNamed(drawerItems[1]["callback"] ?? ""),
          ),
          const SizedBox(height: 10),
          DrawerBtn(
            icon: drawerItems[2]["icon"] ?? "",
            title: drawerItems[2]["title"] ?? "",
            callback: () => Get.toNamed(drawerItems[2]["callback"] ?? ""),
          ),
          const SizedBox(height: 10),
          DrawerBtn(
            icon: drawerItems[3]["icon"] ?? "",
            title: drawerItems[3]["title"] ?? "",
            callback: () => Get.toNamed(drawerItems[3]["callback"] ?? ""),
          ),
          const SizedBox(height: 10),
          DrawerBtn(
            icon: drawerItems[4]["icon"] ?? "",
            title: drawerItems[4]["title"] ?? "",
            callback: () => Get.toNamed(drawerItems[4]["callback"] ?? ""),
          ),
          const SizedBox(height: 10),
          DrawerBtn(
            icon: drawerItems[5]["icon"] ?? "",
            title: drawerItems[5]["title"] ?? "",
            callback: () => Get.toNamed(drawerItems[5]["callback"] ?? ""),
          ),
          const SizedBox(height: 10),
          DrawerBtn(
            icon: drawerItems[6]["icon"] ?? "",
            title: drawerItems[6]["title"] ?? "",
            callback: () => Get.toNamed(drawerItems[6]["callback"] ?? ""),
          ),
          const SizedBox(height: 10),
          DrawerBtn(
            icon: drawerItems[7]["icon"] ?? "",
            title: drawerItems[7]["title"] ?? "",
            callback: () => Get.toNamed(drawerItems[7]["callback"] ?? ""),
          ),
          const SizedBox(height: 10),
          DrawerBtn(
            icon: drawerItems[8]["icon"] ?? "",
            title: drawerItems[8]["title"] ?? "",
            callback: () => Get.toNamed(drawerItems[8]["callback"] ?? ""),
          ),
          const SizedBox(height: 30),
          InkWell(
            onTap: () => Get.offAllNamed("/home"),
            child: Image.asset('assets/images/logo_pixel.png', height: 125),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
