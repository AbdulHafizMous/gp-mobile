import 'package:get/get.dart';

import '../controllers/notifs_controller.dart';

class NotifsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotifsPageController>(
      () => NotifsPageController(),
    );
  }
}
