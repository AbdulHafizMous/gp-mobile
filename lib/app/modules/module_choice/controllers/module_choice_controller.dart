import 'package:get/get.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';
import 'package:grand_public_v2/app/services/profile_completion_service.dart';

class ModuleChoiceController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // Retour au choix du module : la prochaine entrée re-proposera le sheet
    // de complétion de profil (tant que le profil est incomplet).
    if (Get.isRegistered<ProfileCompletionService>()) {
      ProfileCompletionService.to.resetVisit();
    }
  }

  Future<void> choose(AppMode mode) async {
    await AppModeService.setMode(mode);
    Get.offAllNamed(AppModeService.homeRoute);
  }
}
