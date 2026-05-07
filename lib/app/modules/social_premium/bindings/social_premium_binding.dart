import 'package:get/get.dart';

import '../controllers/social_premium_controller.dart';

class SocialPremiumBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SocialPremiumController>(
      () => SocialPremiumController(),
    );
  }
}
