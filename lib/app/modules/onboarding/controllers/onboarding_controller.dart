import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class OnboardingController extends GetxController {
  final count = 0.obs;
  @override
  void onInit() {
    super.onInit();
    final isLogged = GetStorage().read('isLogged');
    final token = GetStorage().read('token');
    // Only redirect to home when isLogged is boolean true and token exists
    if (isLogged == true && token != null) {
      Get.offAllNamed('/main-page');
    }
  }

  void increment() => count.value++;
}
