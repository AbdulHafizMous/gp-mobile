import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';

class OnboardingController extends GetxController {
  final count = 0.obs;
  @override
  void onInit() {
    super.onInit();
    final isLogged = GetStorage().read('isLogged');
    final token = GetStorage().read('token');
    // Only redirect to home when isLogged is boolean true and token exists
    if (isLogged == true && token != null) {
      Get.offAllNamed(AppModeService.homeRoute); // #Beno10
    }
  }

  void increment() => count.value++;
}
