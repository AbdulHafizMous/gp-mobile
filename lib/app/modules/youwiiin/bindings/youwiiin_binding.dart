import 'package:get/get.dart';
import '../controllers/youwiiin_controller.dart';

class YouwiiinBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<YouwiiinController>(() => YouwiiinController());
  }
}
