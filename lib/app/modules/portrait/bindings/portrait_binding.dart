import 'package:get/get.dart';

import '../controllers/portrait_controller.dart';

class PortraitBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PortraitController>(
      () => PortraitController(),
    );
  }
}
