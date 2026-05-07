import 'package:get/get.dart';

import '../controllers/social_about_controller.dart';

class SocialAboutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SocialAboutController>(
      () => SocialAboutController(),
    );
  }
}
