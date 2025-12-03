import 'package:get/get.dart';

import '../controllers/social_link_controller.dart';

class SocialLinkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SocialLinkController>(
      () => SocialLinkController(),
    );
  }
}
