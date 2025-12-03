import 'package:get/get.dart';

import '../controllers/interest_controller.dart';

class InterestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InterestController>(
      () => InterestController(),
    );
  }
}
