import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/audience_fields.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

class CompleteProfileController extends GetxController {
  final audience = AudienceFormState();
  final formKey = GlobalKey<FormState>(); // étape 1 : naissance + genre
  final formKey2 = GlobalKey<FormState>(); // étape 2 : profession
  final step = 0.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final u = activeUser.value;
    audience.prefill(b: u.birthday, g: u.gender, p: u.profession);
  }

  void nextStep() {
    if (formKey.currentState?.validate() ?? false) step.value = 1;
  }

  void previousStep() => step.value = 0;

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      step.value = 0;
      return;
    }
    if (!(formKey2.currentState?.validate() ?? false) || !audience.isValid) {
      step.value = 1;
      return;
    }
    isLoading.value = true;
    try {
      final res = await RequestService().post('/users/complete-profile', data: audience.toPayload());
      if (res.statusCode == 200) {
        activeUser.value = activeUser.value.copyWith(
          birthday: audience.birthday.text,
          gender: audience.gender.value,
          profession: audience.profession.text.trim(),
          needsAudienceProfile: false,
        );
        Get.offAllNamed(AppModeService.postAuthRoute);
      }
    } on DioException catch (e) {
      final errs = e.response?.data is Map ? e.response?.data['errors'] : null;
      final first = errs is Map && errs.isNotEmpty ? (errs.values.first as List).first.toString() : null;
      await ToastHelper.showToast(first ?? "Impossible d'enregistrer. Réessayez.",
          backgroundColor: Colors.red, textColor: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    audience.dispose();
    super.onClose();
  }
}
