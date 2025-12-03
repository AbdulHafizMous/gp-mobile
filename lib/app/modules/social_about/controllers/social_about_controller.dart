import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class SocialAboutController extends GetxController {

  final controller = ScrollController();
  final count = 0.obs;
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("scrolling to top");
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(seconds: 10),
        curve: Curves.linear,
      );
    });
  }



  void increment() => count.value++;
}
