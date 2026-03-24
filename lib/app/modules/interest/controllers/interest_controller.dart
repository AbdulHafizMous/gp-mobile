import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

class Interest {
  final int id;
  final String name;
  bool isSelected;

  Interest({required this.id, required this.name, this.isSelected = false});
}

class InterestController extends GetxController {
  final interests = <Interest>[].obs;
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
        await Future.delayed(const Duration(milliseconds: 500));

        interests.value = [
          Interest(id: 1, name: "Sport"),
          Interest(id: 2, name: "Mode"),
          Interest(id: 3, name: "Dance"),
          Interest(id: 4, name: "Lecture"),
          Interest(id: 5, name: "Sorties"),
          Interest(id: 6, name: "Voyage"),
          Interest(id: 7, name: "Shopping"),
          Interest(id: 8, name: "Dessin"),
          Interest(id: 9, name: "Cuisine"),
          Interest(id: 10, name: "Réseaux sociaux"),
          Interest(id: 11, name: "Musique"),
          Interest(id: 12, name: "Cinéma"),
          Interest(id: 13, name: "Tech"),
          Interest(id: 14, name: "Gaming"),
          Interest(id: 15, name: "Fitness"),
        ];
        return;
      }

      //
      // API
      final response = await RequestService().get('/interest-centers');

      if (response.statusCode == 200) {
        debugPrint("Data : ${response.data}");
        final data = response.data['data']['interest_centers'];

        interests.value = List<Interest>.from(
          data.map((item) => Interest(id: item['id'], name: item['name'])),
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
  void toggleInterest(Interest interest) {
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
