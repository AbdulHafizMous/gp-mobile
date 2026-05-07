import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class AppBarWi extends StatefulWidget {
  const AppBarWi({super.key});

  @override
  State<AppBarWi> createState() => _AppBarWiState();
}

class _AppBarWiState extends State<AppBarWi> {
  final controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: InkWell(
        onTap: () => Get.offAllNamed('/home'),
        child: Image.asset(
          LOGO,
          width: 50,
          height: 50,
        ),
      ),
      centerTitle: true,
      backgroundColor: GPTheme.primaryColor,
      toolbarHeight: 100,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => Get.toNamed('/search'),
        ),
        IconButton(
          onPressed: () => Get.toNamed('/profile'),
          icon: const Icon(Icons.person, color: Colors.white),
        ),
      ],
    );
  }
}
