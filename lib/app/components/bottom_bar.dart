import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller_old.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class BottomBarWi extends StatefulWidget {
  const BottomBarWi({super.key});

  @override
  State<BottomBarWi> createState() => _BottomBarWiState();
}

class _BottomBarWiState extends State<BottomBarWi> {
  final controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Ensure currentIndex is inside the bounds of the BottomNavigationBar items
      final idx = controller.currentIndex.value;
      final safeIndex = (idx < 0 || idx >= 4) ? 0 : idx;
      return BottomNavigationBar(
        backgroundColor: GPTheme.primaryColor,
        showSelectedLabels: false,
        currentIndex: safeIndex,
        onTap: (val) {
          Get.toNamed('/home');
          controller.changeCurrentIndex(val);
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: "",
            activeIcon: CircleAvatar(
              backgroundColor: GPTheme.primaryColor,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.home, color: Colors.white),
              ),
            ),
            backgroundColor: GPTheme.primaryColor,
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/icons/tv.png',
              color: Colors.white,
              height: 25,
              width: 25,
            ),
            label: "",
            backgroundColor: GPTheme.primaryColor,
            activeIcon: CircleAvatar(
              backgroundColor: GPTheme.primaryColor,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Image.asset(
                  'assets/icons/tv.png',
                  color: Colors.white,
                  height: 25,
                  width: 25,
                ),
              ),
            ),
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.notifications, color: Colors.white),
                  ),
                  Positioned(
                    right: 0,
                    child: Badge(
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                      label: Text(controller.notifications.length.toString()),
                    ),
                  ),
                ],
              ),
            ),
            label: "",
            backgroundColor: GPTheme.primaryColor,
            activeIcon: CircleAvatar(
              backgroundColor: GPTheme.primaryColor,
              child: SizedBox(
                height: 100,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/icons/mygp.png',
              color: Colors.white,
              height: 30,
              width: 30,
            ),
            label: "",
            backgroundColor: GPTheme.primaryColor,
            activeIcon: CircleAvatar(
              backgroundColor: GPTheme.primaryColor,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Image.asset(
                  'assets/icons/mygp.png',
                  color: Colors.white,
                  height: 30,
                  width: 30,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
