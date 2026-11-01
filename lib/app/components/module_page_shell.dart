// lib/app/components/module_page_shell.dart
//
// Dans Grandpublic, Profil et Notifications s'affichent DANS le Scaffold de
// l'accueil (barre du haut, retour…). Dans Blowmusic / Youwiiin ces pages sont
// ouvertes seules : on les enrobe donc d'un Scaffold + AppBar avec retour.
// Contient aussi la cloche de notifications (accès rapide) des AppBar module.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/notifs/controllers/notifs_controller.dart';
import 'package:grand_public_v2/app/modules/pages/notification_page.dart';
import 'package:grand_public_v2/app/modules/profile/controllers/profile_controller.dart';
import 'package:grand_public_v2/app/modules/profile/views/profile_view.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';

/// Page (Notifications / Profil) affichée SOUS le header du module, comme dans
/// Grandpublic : le header (menu, logo, cloche, profil) reste visible.
class ModuleOverlay {
  static final RxnString current = RxnString();

  static void open(String page, {String? notifCategory}) {
    if (page == 'notifs') {
      final ctrl = Get.isRegistered<NotifsPageController>()
          ? Get.find<NotifsPageController>()
          : Get.put(NotifsPageController());
      if (notifCategory != null) ctrl.selectedCategory.value = notifCategory;
      ctrl.fetchNotifications(refresh: true);
    }
    current.value = page;
  }

  static void close() => current.value = null;

  /// Retour : remonte d'abord les sous-pages du profil, puis ferme.
  static void back() {
    if (current.value == 'profile' && Get.isRegistered<ProfileController>()) {
      final c = Get.find<ProfileController>();
      if (c.subPage.value != ProfileSubPage.main) {
        c.goBack();
        return;
      }
    }
    close();
  }

  /// Contenu à afficher sous le header, ou null.
  static Widget? get page => switch (current.value) {
    'notifs' => const NotificationPage(),
    'profile' => const ProfileView(embedded: true),
    _ => null,
  };

  /// Flèche retour à placer en `leading` quand une page est ouverte.
  static Widget backButton(Color color) => IconButton(
    icon: Icon(Icons.arrow_back_rounded, color: color),
    onPressed: back,
  );
}

/// Enrobe le body d'un module : affiche l'overlay s'il est ouvert et gère le
/// retour système.
class ModuleOverlayHost extends StatelessWidget {
  final Widget child;
  const ModuleOverlayHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Obx(() {
    final p = ModuleOverlay.page;
    return PopScope(
      canPop: p == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ModuleOverlay.back();
      },
      child: p ?? child,
    );
  });
}

/// Vrai quand la page est ouverte depuis Blowmusic ou Youwiiin.
bool get isInModuleShell => AppModeService.current != AppMode.grandPublic;

class ModulePageShell extends StatelessWidget {
  final String title;
  final Widget child;
  const ModulePageShell({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final fg = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: child,
    );
  }
}

/// Cloche de notifications avec pastille de non-lus, pour les AppBar des
/// modules. `category` = « blowmusic » ou « youwiiin ».
class ModuleBellAction extends StatelessWidget {
  final String category;
  final Color color;

  /// Rapproche la cloche de l'icône voisine (ex. profil) : moins de marge.
  final bool dense;

  /// true : ouvre sous le header du module (Blowmusic / Youwiiin).
  final bool overlay;
  const ModuleBellAction({
    super.key,
    required this.category,
    required this.color,
    this.dense = false,
    this.overlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final created = !Get.isRegistered<NotifsPageController>();
    final ctrl = created
        ? Get.put(NotifsPageController())
        : Get.find<NotifsPageController>();
    return Obx(() {
      final n = ctrl.unreadCount.value;
      return IconButton(
        visualDensity: dense ? VisualDensity.compact : null,
        padding: dense ? const EdgeInsets.only(left: 6) : null,
        constraints: dense ? const BoxConstraints(minWidth: 36, minHeight: 40) : null,
        tooltip: 'Notifications',
        onPressed: () {
          if (overlay) {
            ModuleOverlay.open('notifs', notifCategory: category);
            return;
          }
          ctrl.selectedCategory.value = category;
          ctrl.fetchNotifications(refresh: true);
          Get.toNamed('/notifs');
        },
        icon: Badge(
          isLabelVisible: n > 0,
          label: Text(n > 99 ? '99+' : '$n'),
          child: Icon(Icons.notifications_none_rounded, color: color),
        ),
      );
    });
  }
}
