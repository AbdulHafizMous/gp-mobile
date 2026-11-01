// lib/app/modules/social/views/social_view.dart

import 'package:grand_public_v2/app/components/expandable_menu_fab.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/modules/social/views/social_games_hub_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/shop/controllers/shop_controller.dart';
import 'package:grand_public_v2/app/modules/shop/views/shop_view.dart';
import 'package:grand_public_v2/app/modules/social/controllers/chat_controller.dart';
import 'package:grand_public_v2/app/modules/social/controllers/dating_controller.dart';
import 'package:grand_public_v2/app/modules/social/views/chat_list_view.dart';
import 'package:grand_public_v2/app/modules/social/views/dating_view.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS (mêmes conventions que Chat / Bizz)
// ─────────────────────────────────────────────────────────────────────────────
extension _Tx on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

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
    Get.isRegistered<ShopController>()
        ? Get.find<ShopController>()
        : Get.put(ShopController());

    const titles = ['Tchat', 'Crush', 'Bizz', 'Jeux'];
    const subtitles = ['Vos conversations', 'Rencontres & matchs', 'Boutique & bons plans', 'Youwiiin : défis & classements'];
    const icons = [Icons.forum_rounded, Icons.local_fire_department_rounded, Icons.handshake_rounded, Icons.sports_esports_rounded];

    return Obx(() {
      final tab = chatCtrl.socialTab.value.clamp(0, 3);
      final unread = chatCtrl.privateConversations.fold<int>(0, (a, c) => a + c.unreadCount);
      return Stack(children: [
        Column(children: [
          // En-tête compact : où je suis dans Social (le changement de sous-section se fait avec le menu flottant).
          Container(
            width: double.infinity,
            color: !context.isDark ? GPTheme.socialColor : Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(children: [
              Icon(icons[tab], color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(child: Text(titles[tab], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17))),
              const SizedBox(width: 8),
              Flexible(child: Text(subtitles[tab], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12))),
            ]),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: tab == 0
                  ? const ChatListView(key: ValueKey('chat'))
                  : tab == 1
                      ? const DatingView(key: ValueKey('dating'))
                      : tab == 2
                          ? const ShopView(key: ValueKey('shop'))
                          : const SocialGamesHubView(key: ValueKey('games')),
            ),
          ),
        ]),
        Positioned.fill(
          child: ExpandableMenuFab(
            color: GPTheme.socialColor,
            selected: tab,
            onSelect: (i) => chatCtrl.socialTab.value = i,
            items: [
              FabMenuItem(icon: icons[0], label: titles[0], badge: unread),
              FabMenuItem(icon: icons[1], label: titles[1]),
              FabMenuItem(icon: icons[2], label: titles[2]),
              if (isYouwiiinActivated) FabMenuItem(icon: icons[3], label: titles[3]),
            ],
          ),
        ),
      ]);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP TAB BAR
// ─────────────────────────────────────────────────────────────────────────────
class SocialTopTabBar extends StatelessWidget {
  final int activeTab;
  final void Function(int) onTap;

  const SocialTopTabBar({super.key, required this.activeTab, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: !context.isDark ? GPTheme.socialColor : Colors.transparent,
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _TopTab(
              label: 'Tchat',
              icon: Icons.forum_outlined,
              active: activeTab == 0,
              onTap: () => onTap(0),
            ),
          ),
          Expanded(
            child: _TopTab(
              label: 'Crush',
              icon: Icons.local_fire_department_outlined,
              active: activeTab == 1,
              onTap: () => onTap(1),
            ),
          ),
          Expanded(
            child: _TopTab(
              label: 'Bizz',
              icon: Icons.handshake_outlined,
              active: activeTab == 2,
              onTap: () => onTap(2),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? GPTheme.socialColor : Colors.white70,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: active ? GPTheme.socialColor : Colors.white70,
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
