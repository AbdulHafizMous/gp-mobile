import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/notification.dart';
import 'package:grand_public_v2/app/modules/notifs/controllers/notifs_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/section_helper.dart';

extension _Tx on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get inputBg => isDark ? Colors.white10 : Colors.grey.shade100;
  Color get primary =>
      Theme.of(this).textTheme.bodyLarge?.color ??
      (isDark ? Colors.white : Colors.black);
  Color get subtle => Theme.of(this).hintColor;
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(NotifsPageController());

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Text(
                'Notifications',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Badge non lus (sur la catégorie affichée)
              Obx(() {
                final count = ctrl.visibleNotifications
                    .where((n) => !n.isRead)
                    .length;
                return count > 0
                    ? Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: SectionHelper.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: SectionHelper.index == 2
                                ? Colors.black
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              }),
              // Tri
              _SortButton(ctrl: ctrl),
              // Tout marquer comme lu
              Obx(
                () => ctrl.unreadCount.value > 0
                    ? TextButton(
                        onPressed: ctrl.markAllAsRead,
                        child: Text(
                          'Tout lire',
                          style: TextStyle(
                            color: SectionHelper.color,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        // ── Filtres par catégorie ─────────────────────────────────────
        _CategoryChips(ctrl: ctrl),
        const SizedBox(height: 4),

        // ── Liste ─────────────────────────────────────────────────────
        Expanded(
          child: Obx(() {
            if (ctrl.isLoading.value && ctrl.notifications.isEmpty) {
              return Center(
                child: CircularProgressIndicator(color: SectionHelper.color),
              );
            }

            final list = ctrl.visibleNotifications;

            if (list.isEmpty) {
              return _emptyState(context, ctrl);
            }

            return RefreshIndicator(
              onRefresh: () => ctrl.fetchNotifications(refresh: true),
              color: SectionHelper.color,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount:
                    list.length +
                    (ctrl.selectedCategory.value == 'all' && ctrl.hasMore.value
                        ? 1
                        : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (ctx, i) {
                  if (i == list.length) {
                    // Loader de pagination (uniquement sur "Toutes")
                    ctrl.fetchNotifications();
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _NotifTile(
                    notif: list[i],
                    onTap: () => ctrl.onTapNotification(list[i]),
                    onDelete: () => ctrl.deleteNotification(list[i]),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context, NotifsPageController ctrl) {
    final filtered = ctrl.selectedCategory.value != 'all';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            filtered
                ? 'Rien dans cette catégorie pour le moment.'
                : 'Vous êtes à jour !',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ── Chips de catégorie (même style que le filtre de Bizz) ──────────────────
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.ctrl});
  final NotifsPageController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = ctrl.selectedCategory.value;
      return SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: kNotifCategories.length,
          itemBuilder: (ctx, i) {
            final cat = kNotifCategories[i];
            final isSelected = selected == cat.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(cat.label),
                selected: isSelected,
                onSelected: (_) => ctrl.selectedCategory.value = cat.id,
                backgroundColor: context.inputBg,
                showCheckmark: false,
                selectedColor: SectionHelper.color,
                labelStyle: TextStyle(
                  color: isSelected
                      ? (SectionHelper.index == 2 ? Colors.black : Colors.white)
                      : context.primary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
                side: BorderSide.none,
              ),
            );
          },
        ),
      );
    });
  }
}

// ── Bouton de tri ───────────────────────────────────────────────────────────
class _SortButton extends StatelessWidget {
  const _SortButton({required this.ctrl});
  final NotifsPageController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopupMenuButton<bool>(
        tooltip: 'Trier',
        icon: Icon(Icons.sort_rounded, color: context.subtle, size: 20),
        initialValue: ctrl.sortMostRecentFirst.value,
        onSelected: (v) => ctrl.sortMostRecentFirst.value = v,
        itemBuilder: (ctx) => [
          CheckedPopupMenuItem(
            value: true,
            checked: ctrl.sortMostRecentFirst.value,
            child: const Text('Plus récentes'),
          ),
          CheckedPopupMenuItem(
            value: false,
            checked: !ctrl.sortMostRecentFirst.value,
            child: const Text('Non lues d\'abord'),
          ),
        ],
      ),
    );
  }
}

// ── Tile ────────────────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.notif,
    required this.onTap,
    required this.onDelete,
  });

  final AppNotification notif;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('notif_${notif.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.isRead
                ? Theme.of(context).cardColor
                : (context.isDark
                      ? const Color(0xFF1A1A1A)
                      : SectionHelper.color.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notif.isRead
                  ? (context.isDark ? Colors.white12 : Colors.grey.shade200)
                  : SectionHelper.color.withOpacity(
                      context.isDark ? 0.35 : 0.2,
                    ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône type
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _typeColor(notif.type, context).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _typeIcon(notif.type),
                  color: _typeColor(notif.type, context),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: notif.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              fontSize: 14,
                              color: context.primary,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: SectionHelper.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notif.body,
                      style: TextStyle(fontSize: 13, color: context.subtle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          notif.createdAt,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.subtle.withOpacity(0.8),
                          ),
                        ),
                        if (notif.route != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: context.subtle.withOpacity(0.8),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'media' => Icons.play_circle_outline_rounded,
      'promo' ||
      'promotion' ||
      'promotion_reminder' => Icons.local_offer_outlined,
      'partner' => Icons.storefront_outlined,
      'campaign' => Icons.campaign_outlined,
      'dating_match' => Icons.favorite_rounded,
      'subscription' => Icons.workspace_premium_rounded,
      'chat_channel' => Icons.tag_rounded,
      'chat_private' => Icons.mail_outline_rounded,
      _ => Icons.notifications_outlined,
    };
  }

  Color _typeColor(String type, BuildContext context) {
    final isDark = context.isDark;
    return switch (type) {
      'media' => Colors.blue,
      'promo' ||
      'promotion' ||
      'promotion_reminder' => isDark ? GPTheme.clubColor : GPTheme.clubOnColor,
      'partner' => isDark ? GPTheme.clubColor : GPTheme.clubOnColor,
      'campaign' => Colors.purple,
      'dating_match' => Colors.pinkAccent,
      'subscription' => Colors.amber.shade700,
      'chat_channel' || 'chat_private' => GPTheme.socialColor,
      _ => SectionHelper.color,
    };
  }
}
