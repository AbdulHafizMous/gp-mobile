import 'package:get/get.dart';

import '../controllers/insolite_controller.dart';

class InsoliteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InsoliteController>(
      () => InsoliteController(),
    );
  }
}
