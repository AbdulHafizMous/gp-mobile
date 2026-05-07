import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/constants/index.dart';

import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          LOGO,
          width: 200,
          height: controller.count.value.toDouble(),
        ),
      ),
    );
  }
}
