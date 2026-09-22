import 'package:get/get.dart';

import '../controllers/blowmusic_controller.dart';

class BlowMusicBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BlowMusicController>(() => BlowMusicController());
  }
}
