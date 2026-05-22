// lib/app/modules/club/bindings/club_binding.dart

import 'package:get/get.dart';
import '../controllers/club_controller.dart';

class ClubBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClubController>(() => ClubController());
  }
}