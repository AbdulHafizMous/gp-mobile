import 'package:get/get.dart';

class InterestController extends GetxController {
  //TODO: Implement InterestController

  final count = 0.obs;



  void goHome() {
    Get.offAllNamed('/home');
  }

  void increment() => count.value++;
}
