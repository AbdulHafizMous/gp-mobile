// lib/app/modules/social/views/social_view.dart

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
    final chatCtrl = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : Get.put(ChatController());
    Get.isRegistered<DatingController>()
        ? Get.find<DatingController>()
        : Get.put(DatingController());

    return Obx(
      () => Column(
        children: [
          _SocialTopTabBar(
            activeTab: chatCtrl.socialTab.value,
            onTap: (i) => chatCtrl.socialTab.value = i,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: chatCtrl.socialTab.value == 0
                  ? const ChatListView(key: ValueKey('chat'))
                  : const DatingView(key: ValueKey('dating')),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP TAB BAR
// ─────────────────────────────────────────────────────────────────────────────
class _SocialTopTabBar extends StatelessWidget {
  final int activeTab;
  final void Function(int) onTap;

  const _SocialTopTabBar({required this.activeTab, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: GPTheme.primaryColor,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _TopTab(
              label: 'Chat',
              icon: Icons.chat_bubble_rounded,
              active: activeTab == 0,
              onTap: () => onTap(0),
            ),
          ),
          Expanded(
            child: _TopTab(
              label: 'Dating',
              icon: Icons.favorite_rounded,
              active: activeTab == 1,
              onTap: () => onTap(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TopTab({
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
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? GPTheme.primaryColor : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? GPTheme.primaryColor : Colors.white70,
                fontWeight: active ? FontWeight.w800 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
