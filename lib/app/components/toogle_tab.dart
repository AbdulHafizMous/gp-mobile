import 'package:flutter/material.dart';

import 'package:grand_public_v2/app/themes/app_theme.dart';

// ─────────────────────────────────────────────
// Toggle Tab (helper widget)
// ─────────────────────────────────────────────
class ToggleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;

  const ToggleTab({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          color: isActive ? GPTheme.primaryColor : Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? GPTheme.primaryColor : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}
