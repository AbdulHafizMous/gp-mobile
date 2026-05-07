import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/notification.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class NotifcationTile extends StatelessWidget {
  const NotifcationTile({super.key, required this.notif});

  final CustomNotification notif;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.asset(LOGO_PIXEL, height: 50),
      title: Text(
        notif.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(notif.description),
      trailing: Icon(Icons.circle, color: GPTheme.primaryColor),
    );
  }
}
