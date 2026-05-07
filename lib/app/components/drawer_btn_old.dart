import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class DrawerBtn extends StatelessWidget {
  const DrawerBtn({
    super.key,
    this.title = "",
    this.icon = 'assets/images/profile.png',
    this.flutterIcon,
    this.callback,
  });

  final String title, icon;
  final IconData? flutterIcon;
  final dynamic callback;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => callback() ?? Navigator.pop(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            flutterIcon != null
                ? Icon(flutterIcon, size: 20, color: GPTheme.primaryColor)
                : Image.asset(icon, width: 20, height: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: GPTheme.primaryColor,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: GPTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}
