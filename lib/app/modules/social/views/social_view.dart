// lib/app/modules/social/views/social_view.dart
//
// Hub principal de la section Social.
// Contient Chat et Dating via un bottom switcher interne.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/social/controllers/chat_controller.dart';
import 'package:grand_public_v2/app/modules/social/controllers/dating_controller.dart';
import 'package:grand_public_v2/app/modules/social/views/chat_list_view.dart';
import 'package:grand_public_v2/app/modules/social/views/dating_view.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class SocialView extends StatelessWidget {
  const SocialView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialise les controllers si pas déjà fait
    final chatCtrl = Get.put(ChatController());
    Get.put(DatingController());

    return Obx(() => Column(
          children: [
            // ── Tab switcher interne ─────────────────────────────────────
            _SocialTabBar(
              activeTab: chatCtrl.socialTab.value,
              onTap: (i) => chatCtrl.socialTab.value = i,
            ),
            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: chatCtrl.socialTab.value == 0
                  ? const ChatListView()
                  : const DatingView(),
            ),
          ],
        ));
  }
}

class _SocialTabBar extends StatelessWidget {
  final int activeTab;
  final void Function(int) onTap;

  const _SocialTabBar({required this.activeTab, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: GPTheme.primaryColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _Tab(
            label: 'Chat',
            icon: Icons.chat_bubble_outline_rounded,
            active: activeTab == 0,
            onTap: () => onTap(0),
          ),
          const SizedBox(width: 8),
          _Tab(
            label: 'Dating',
            icon: Icons.favorite_border_rounded,
            active: activeTab == 1,
            onTap: () => onTap(1),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? GPTheme.primaryColor : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? GPTheme.primaryColor : Colors.white70,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}