import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/mocks/interest_mock.dart';
import 'package:grand_public_v2/app/data/models/profile_interest.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

class InterestController extends GetxController {
  final interests = <ProfileInterest>[].obs;
  final isLoading = false.obs;

  @override
  void onReady() {
    super.onReady();
    fetchInterests();
  }

  // ─────────────────────────────────────────────
  // FETCH INTERESTS
  // ─────────────────────────────────────────────
  Future<void> fetchInterests() async {
    isLoading.value = true;

    try {
      //
      // MOCK
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
        interests.value = List.generate(
          mockInterests.length,
          (i) => ProfileInterest(
            id: i + 1,
            name: mockInterests[i],
            isSelected: i < 3, // 3 sélectionnés par défaut en mock
          ),
        );
        return;
      }

      //
      // API
      final response = await RequestService().get('/interest-centers');

      if (response.statusCode == 200) {
        debugPrint("Data : ${response.data}");
        final data = response.data['data']['interest_centers'];

        interests.value = List<ProfileInterest>.from(
          data.map((item) => ProfileInterest(id: item['id'], name: item['name'])),
        );
      }
    } on DioException catch (e) {
      debugPrint("Error: $e");
      Get.snackbar(
        "Erreur",
        "Impossible de charger les centres d'intérêt",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        icon: Icon(Icons.error_outline, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────
  // SELECT / UNSELECT
  // ─────────────────────────────────────────────
  void toggleInterest(ProfileInterest interest) {
    interest.isSelected = !interest.isSelected;
    interests.refresh();
  }

  // ─────────────────────────────────────────────
  // SUBMIT
  // ─────────────────────────────────────────────
  Future<void> goHome() async {
    final selected = interests.where((e) => e.isSelected).toList();

    if (selected.isEmpty) {
      await ToastHelper.showToast(
        "Veuillez choisir au moins un centre d'intérêt",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      //
      // MOCK
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 500));
        // debugPrint("Git : ${selected.map((e) => e.id).toList()}");
        GetStorage().write('isLogged', true);
        Get.offAllNamed('/main-page');
        return;
      }

      //
      // API
      await RequestService().post(
        '/interest-centers',
        data: {"interest_center_ids": selected.map((e) => e.id).toList()},
      );
      GetStorage().write('isLogged', true);
      Get.offAllNamed('/main-page');
    } catch (e) {
      Get.snackbar(
        'Erreur',
        "Impossible d'enregistrer",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        icon: Icon(Icons.error_outline, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
