import 'package:get/get.dart';

import '../controllers/sucess_page_controller.dart';

class SucessPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SucessPageController>(
      () => SucessPageController(),
    );
  }
}
