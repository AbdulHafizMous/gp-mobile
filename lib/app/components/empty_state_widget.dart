// lib/app/components/empty_state_widget.dart
//
// État vide générique (aucune donnée) — évite les écrans blancs/noirs
// silencieux. Se centre correctement même utilisé comme unique enfant
// d'un ListView (nécessaire pour RefreshIndicator) grâce à minHeight.

import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color? color;
  final double minHeight;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    this.color,
    this.minHeight = 340,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white54 : Colors.black45;
    return SizedBox(
      width: double.infinity,
      height: minHeight,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: color?.withOpacity(0.6) ?? textColor),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
