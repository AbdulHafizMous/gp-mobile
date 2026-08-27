// lib/app/modules/home/bindings/home_binding.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/club/views/club_view.dart';
import 'package:grand_public_v2/app/modules/club/views/partner_scanner_view.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';
import 'package:grand_public_v2/app/modules/notifs/views/notifs_view.dart';
import 'package:grand_public_v2/app/modules/profile/controllers/profile_controller.dart';
import 'package:grand_public_v2/app/modules/profile/views/profile_view.dart';
import 'package:grand_public_v2/app/modules/shop/views/shop_my_listings_view.dart';
import 'package:grand_public_v2/app/modules/shop/views/shop_view.dart';
import 'package:grand_public_v2/app/modules/social/controllers/chat_controller.dart';
import 'package:grand_public_v2/app/modules/social/controllers/dating_controller.dart';
import 'package:grand_public_v2/app/modules/social/views/social_view.dart';
import 'package:grand_public_v2/app/modules/social_about/views/social_about_view.dart';
import 'package:grand_public_v2/app/modules/social_link/views/social_link_view.dart';
import 'package:grand_public_v2/app/modules/social_premium/views/social_premium_view.dart';
import 'package:grand_public_v2/app/modules/space/views/spaces_list_view.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // ── Controllers ────────────────────────────────────────────────────────
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<ChatController>(() => ChatController());
    Get.lazyPut<DatingController>(() => DatingController());

    // ── Page registry ──────────────────────────────────────────────────────
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<HomeController>()) return;
      final ctrl = Get.find<HomeController>();

      // ── Profil ─────────────────────────────────────────────────────────
      ctrl.registerPage('/profile', (_) => const ProfileView());

      // ── Espaces ────────────────────────────────────────────────────────
      ctrl.registerPage('/home/spaces', (_) => const SpacesListView());

      // ── Club ────────────────────────────────────────────────────────────
      ctrl.registerPage('/home/club', (_) => const ClubView());
      ctrl.registerPage(
        '/home/club/validations',
        (_) => const PartnerScannerView(),
      );

      // ── Notifications ──────────────────────────────────────────────────
      ctrl.registerPage('/notifs', (_) => const NotifsView());

      // ── Social : Chat (ouvre SocialView sur l'onglet Chat) ─────────────
      ctrl.registerPage('/social/chat', (_) {
        // S'assure que le tab Chat est actif
        if (Get.isRegistered<ChatController>()) {
          Get.find<ChatController>().socialTab.value = 0;
        }
        return const SocialView();
      });

      // ── Social : Dating (ouvre SocialView sur l'onglet Dating) ─────────
      ctrl.registerPage('/social/dating', (_) {
        if (Get.isRegistered<ChatController>()) {
          Get.find<ChatController>().socialTab.value = 1;
        }
        return const SocialView();
      });

      // ── Social : Dating (ouvre SocialView sur l'onglet Dating) ─────────
      ctrl.registerPage('/social/shop', (_) {
        if (Get.isRegistered<ChatController>()) {
          Get.find<ChatController>().socialTab.value = 2;
        }
        return const ShopView();
      });


      // ── Social : Modération ────────────────────────────────────────────
      // ctrl.registerPage('/social/moderation', (_) => const ModerationView());

      // ── Pages fixes du drawer ──────────────────────────────────────────
      ctrl.registerPage('/social-premium', (_) => const SocialPremiumView());
      ctrl.registerPage('/social-link', (_) => const SocialLinkView());
      ctrl.registerPage('/social-about', (_) => const SocialAboutView());

      // -- Shop : Mes annonces (ouvre ShopView sur l'onglet Mes annonces) ─────
      // ctrl.registerPage('/social/shop', (_) => const ShopView());
      ctrl.registerPage('/social/shop/my-listings', (_) => const ShopMyListingsView());
    });
  }
}