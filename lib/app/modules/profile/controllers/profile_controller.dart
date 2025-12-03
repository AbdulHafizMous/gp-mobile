import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ProfileController extends GetxController {
  //TODO: Implement ProfileController

  final isDark = false.obs;
  final count = 0.obs;
  @override
  void onInit() {
    isDark.value = GetStorage().read("isDark") ?? false;
    super.onInit();
  }



  void increment() => count.value++;
}
