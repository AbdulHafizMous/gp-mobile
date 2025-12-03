import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';

class SplashController extends GetxController {
  final count = 200.obs;

  final controller = Get.put(HomeController());

  @override
  Future<void> onReady() async {
    super.onReady();
    final isLogged = await GetStorage().read('isLogged');
    final token = await GetStorage().read('token');
    // Log type and value to help debugging persistent storage issues
    // print(
    //     'Splash: isLogged -> ${isLogged.runtimeType} : $isLogged, token: $token');

    if (isLogged == true && token != null) {
      Future.delayed(const Duration(seconds: 2), () {
        controller.getUser().then((user) {
          Get.offAllNamed('/home');
        });
      });
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        Get.offAllNamed('/onboarding');
      });
    }
  }

  void increment() => count.value++;
}
