import 'package:get/get.dart';

import '../controllers/update_required_controller.dart';

class UpdateRequiredBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UpdateRequiredController>(
      () => UpdateRequiredController(),
    );
  }
}
