import 'package:flutter/material.dart';

class AdminMenuGroup {
  final String title;
  final List<AdminMenuItem> items;

  AdminMenuGroup({required this.title, required this.items});
}

class AdminMenuItem {
  final String title;
  final String description;
  final String route;
  final IconData icon;

  AdminMenuItem({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
  });
}
