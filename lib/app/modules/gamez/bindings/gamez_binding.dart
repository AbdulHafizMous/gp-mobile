import 'package:get/get.dart';
import '../controllers/gamez_controller.dart';

class GameZBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GameZController>(() => GameZController());
  }
}
