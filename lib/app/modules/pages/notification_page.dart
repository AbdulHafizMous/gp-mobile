import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/notification.dart';
import 'package:grand_public_v2/app/modules/notifs/controllers/notifs_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(NotifsPageController());

    return Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                // Badge non lus
                Obx(() => ctrl.unreadCount.value > 0
                    ? Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: GPTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${ctrl.unreadCount.value}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    : const SizedBox.shrink()),
                // Tout marquer comme lu
                Obx(() => ctrl.unreadCount.value > 0
                    ? TextButton(
                        onPressed: ctrl.markAllAsRead,
                        child: Text(
                          'Tout lire',
                          style: TextStyle(
                              color: GPTheme.primaryColor, fontSize: 12),
                        ),
                      )
                    : const SizedBox.shrink()),
              ],
            ),
          ),
      
          // ── Liste ─────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value && ctrl.notifications.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                      color: GPTheme.primaryColor),
                );
              }
      
              if (ctrl.notifications.isEmpty) {
                return _emptyState(context);
              }
      
              return RefreshIndicator(
                onRefresh: () => ctrl.fetchNotifications(refresh: true),
                color: GPTheme.primaryColor,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: ctrl.notifications.length +
                      (ctrl.hasMore.value ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 4),
                  itemBuilder: (ctx, i) {
                    if (i == ctrl.notifications.length) {
                      // Loader de pagination
                      ctrl.fetchNotifications();
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                            child: CircularProgressIndicator()),
                      );
                    }
                    return _NotifTile(
                      notif: ctrl.notifications[i],
                      onTap: () =>
                          ctrl.onTapNotification(ctrl.notifications[i]),
                      onDelete: () =>
                          ctrl.deleteNotification(ctrl.notifications[i]),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Aucune notification',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            'Vous êtes à jour !',
            style:
                TextStyle(fontSize: 13, color: Colors.grey.shade400),
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
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 22),
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
                : GPTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notif.isRead
                  ? Colors.grey.shade200
                  : GPTheme.primaryColor.withOpacity(0.2),
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
                  color: _typeColor(notif.type).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _typeIcon(notif.type),
                  color: _typeColor(notif.type),
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
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: GPTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notif.body,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          notif.createdAt,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400),
                        ),
                        if (notif.route != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 10, color: Colors.grey.shade400),
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
      'media'    => Icons.play_circle_outline_rounded,
      'promo'    => Icons.local_offer_outlined,
      'campaign' => Icons.campaign_outlined,
      _          => Icons.notifications_outlined,
    };
  }

  Color _typeColor(String type) {
    return switch (type) {
      'media'    => Colors.blue,
      'promo'    => Colors.orange,
      'campaign' => Colors.purple,
      _          => GPTheme.primaryColor,
    };
  }
}