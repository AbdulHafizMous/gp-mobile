import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/pages/notification_page.dart';

import 'package:grand_public_v2/app/components/module_page_shell.dart';
import '../controllers/notifs_controller.dart';

class NotifsView extends GetView<NotifsPageController> {
  const NotifsView({super.key});
  @override
  Widget build(BuildContext context) {
    if (isInModuleShell) {
      return const ModulePageShell(title: 'Notifications', child: NotificationPage());
    }
    return const Scaffold(body: NotificationPage());
  }
}