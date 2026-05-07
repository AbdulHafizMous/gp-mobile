import 'package:get/get.dart';

import '../controllers/soon_controller.dart';

class SoonBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SoonController>(
      () => SoonController(),
    );
  }
}
