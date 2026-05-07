import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/models/notification.dart';
import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/modules/profile/views/profile_view.dart';
import 'package:grand_public_v2/app/modules/social_link/views/social_link_view.dart';
import 'package:grand_public_v2/app/modules/social_premium/views/social_premium_view.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

class HomeController extends GetxController {
  final activeSectionIndex = 0.obs;
  final currentRoute = '/home'.obs;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Widget dynamique qui sera affiché dans le body du HomeView
  Widget get currentPage {
    switch (currentRoute.value) {
      case '/profile':
        return const ProfileView();
      case '/premium':
        return const SocialPremiumView();
      case '/link':
        return const SocialLinkView();
      default:
        return ProfileView(); //_buildDefaultSection(activeSectionIndex.value);
    }
  }

  void navigateTo(String route) {
    currentRoute.value = route;
    // Optionnel : fermer le drawer si ouvert
    if (scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Get.back();
    }
  }

  void goToSection(int index) {
    activeSectionIndex.value = index;
    currentRoute.value =
        '/section_$index'; // Reset la route vers une section du bottom bar
  }

  // Trying

  final activeSectionIndexOld = 0.obs;
  final notifications = <CustomNotification>[].obs;

  final box = GetStorage();

  // ─────────────────────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────────────────────
  void goToSectionOld(int index, {bool showToast = false}) {
    debugPrint("Going to Index : $index");

    if (index == activeSectionIndex.value) return;

    activeSectionIndex.value = index;

    if (showToast) {
      _notifyDrawerUpdate(index);
    }
  }

  void _notifyDrawerUpdate(int index) {
    ToastHelper.showToast(
      'Menu mis à jour !',
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
  }

  // ─────────────────────────────────────────────────────────
  // INIT (IMPORTANT)
  // ─────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();

    //  Lire section demandée depuis MainPage
    final pendingIndex = box.read('_pendingSection');

    if (pendingIndex != null) {
      debugPrint("Pending section detected: $pendingIndex");

      goToSectionOld(pendingIndex, showToast: true);

      // Nettoyage (très important)
      box.remove('_pendingSection');
    }
  }

  // ─────────────────────────────────────────────────────────
  // STATIC NAVIGATION (optionnel)
  // ─────────────────────────────────────────────────────────
  static void navigateToSection(int sectionIndex) {
    final ctrl = Get.find<HomeController>();
    ctrl.goToSectionOld(sectionIndex, showToast: true);
    Get.offAllNamed('/home');
  }

  // ─────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────
  void logout() {
    GetStorage().remove('token');
    GetStorage().remove('isLogged');
    Get.offAllNamed('/login');
  }
}
