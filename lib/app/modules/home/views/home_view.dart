// lib/app/modules/home/views/home_view.dart
//
// Coquille de la section Grand Public — allégée : tout le détail (AppBar,
// drawer, bottom bar, transition) a été extrait dans
// lib/app/modules/home/widgets/ pour rester lisible et réutilisable.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/ad_banner_widget.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';
import 'package:grand_public_v2/app/modules/home/widgets/animated_body.dart';
import 'package:grand_public_v2/app/modules/home/widgets/home_app_bar.dart';
import 'package:grand_public_v2/app/modules/home/widgets/home_bottom_bar.dart';
import 'package:grand_public_v2/app/modules/home/widgets/home_drawer.dart';
import 'package:grand_public_v2/app/modules/notifs/controllers/notifs_controller.dart';

class HomeView extends GetView<HomeController> {
  HomeView({super.key});

  final notifsController = Get.put(NotifsPageController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: controller.scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(
          () => HomeAppBar(
            ctrl: controller,
            canPop: controller.canPop,
            currentRoute: controller.currentRoute,
            sectionIndex: controller.activeSectionIndex,
            notificationCount: notifsController.unreadCount.value,
          ),
        ),
      ),
      drawer: Obx(() => HomeDrawer(activeSectionIndex: controller.activeSectionIndex)),
      body: Obx(
        () => Column(
          children: [
            // Bannière pub — visible uniquement à la racine de l'accueil
            // (section 0, pas de sous-page ouverte), pour ne jamais gêner
            // la navigation dans les sous-écrans.
            if (controller.activeSectionIndex == 0 && !controller.canPop)
              const AdBannerWidget(screen: 'home'),
            Expanded(
              child: AnimatedBody(routeKey: controller.currentRoute, child: controller.currentPage),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => SectionsBottomBar(activeIndex: controller.activeSectionIndex, onTap: controller.goToSection),
      ),
    );
  }
}
