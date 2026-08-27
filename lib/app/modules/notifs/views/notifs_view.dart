import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/pages/notification_page.dart';

import '../controllers/notifs_controller.dart';

class NotifsView extends GetView<NotifsPageController> {
  const NotifsView({super.key, this.typeFilter, this.title});

  final List<String>? typeFilter;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationPage(typeFilter: typeFilter, title: title),
    );
  }
}