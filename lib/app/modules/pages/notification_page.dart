import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/notifcation_tile.dart';
import 'package:grand_public_v2/app/data/models/notification.dart';
import 'package:grand_public_v2/app/modules/notifs/controllers/notifs_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final controller = Get.put(NotifsPageController());

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 20),
        Text(
          "NOTIFICATIONS",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: GPTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        FutureBuilder(
          future: controller.fetchNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: GPTheme.primaryColor),
              );
            } else if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            } else if (snapshot.hasData) {
              return ListView.separated(
                padding: const EdgeInsets.all(15),
                separatorBuilder: (context, index) =>
                    Divider(color: GPTheme.primaryColor),
                shrinkWrap: true,
                itemCount: controller.notifications.length,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return NotifcationTile(
                    notif: CustomNotification(
                      description: controller.notifications[index].description,
                      title: controller.notifications[index].title,
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
