// lib/app/components/module_page_shell.dart
//
// Dans Grandpublic, Profil et Notifications s'affichent DANS le Scaffold de
// l'accueil (barre du haut, retour…). Dans Blowmusic / GameZ ces pages sont
// ouvertes seules : on les enrobe donc d'un Scaffold + AppBar avec retour.
// Contient aussi la cloche de notifications (accès rapide) des AppBar module.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/notifs/controllers/notifs_controller.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';

/// Vrai quand la page est ouverte depuis Blowmusic ou GameZ.
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
/// modules. `category` = « blowmusic » ou « gamez ».
class ModuleBellAction extends StatelessWidget {
  final String category;
  final Color color;
  const ModuleBellAction({
    super.key,
    required this.category,
    required this.color,
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
        tooltip: 'Notifications',
        onPressed: () {
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
