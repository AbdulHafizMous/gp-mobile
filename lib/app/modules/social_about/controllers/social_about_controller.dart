import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class SocialAboutController extends GetxController {
  final scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // On attend un peu pour que l'utilisateur voit le début avant le scroll auto
      Future.delayed(const Duration(seconds: 1), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(seconds: 15),
            curve: Curves.linear,
          );
        }
      });
    });
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}