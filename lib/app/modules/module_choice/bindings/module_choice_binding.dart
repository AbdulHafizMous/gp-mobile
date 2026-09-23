import 'package:get/get.dart';
import '../controllers/module_choice_controller.dart';

class ModuleChoiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ModuleChoiceController>(() => ModuleChoiceController());
  }
}
