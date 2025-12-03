import 'package:get/get.dart';

import '../controllers/payement_controller.dart';

class PayementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PayementController>(
      () => PayementController(),
    );
  }
}
