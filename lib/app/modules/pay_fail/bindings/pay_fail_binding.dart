import 'package:get/get.dart';

import '../controllers/pay_fail_controller.dart';

class PayFailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PayFailController>(
      () => PayFailController(),
    );
  }
}
