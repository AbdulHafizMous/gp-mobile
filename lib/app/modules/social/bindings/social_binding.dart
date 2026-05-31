import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../controllers/dating_controller.dart';

class SocialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(
      () => ChatController(),
    );
    Get.lazyPut<DatingController>(
      () => DatingController(),
    );
  }
}
