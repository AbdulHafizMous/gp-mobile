import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: GPTheme.primaryColor,
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
                  child: const Icon(Icons.notifications),
                ),
                Positioned(
                  right: 0,
                  child: Badge(
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                    label: Text(6.toString()),
                  ),
                ),
              ],
            ),
          ),
          label: "",
          backgroundColor: GPTheme.primaryColor,
          activeIcon: CircleAvatar(
            backgroundColor: GPTheme.primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.notifications),
                  ),
                  Positioned(
                    right: 0,
                    child: Badge(
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                      label: Text(6.toString()),
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
  }
}
