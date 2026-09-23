import 'package:get/get.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';

class ModuleChoiceController extends GetxController {
  Future<void> choose(AppMode mode) async {
    await AppModeService.setMode(mode);
    Get.offAllNamed(AppModeService.homeRoute);
  }
}
