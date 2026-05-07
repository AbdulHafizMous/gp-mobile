import 'package:get/get.dart';

import '../controllers/pay_suc_controller.dart';

class PaySucBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaySucController>(
      () => PaySucController(),
    );
  }
}
