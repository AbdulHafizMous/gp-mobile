import 'package:get/get.dart';

import '../controllers/opinion_controller.dart';

class OpinionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OpinionController>(
      () => OpinionController(),
    );
  }
}
