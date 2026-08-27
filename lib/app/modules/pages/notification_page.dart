import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/notification.dart';
import 'package:grand_public_v2/app/modules/notifs/controllers/notifs_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key, this.typeFilter, this.title});

  /// Si fourni, n'affiche que les notifs dont `type` est dans cette liste
  /// (ex: notifs Club → ['promotion', 'promotion_reminder', 'promo']).
  final List<String>? typeFilter;

  /// Titre affiché dans l'en-tête (par défaut "Notifications").
  final String? title;

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
                  title ?? 'Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                // Badge non lus
                Obx(() {
                  final count = _filtered(ctrl).where((n) => !n.isRead).length;
                  return count > 0
                    ? Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: GPTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    : const SizedBox.shrink();
                }),
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

              final list = _filtered(ctrl);

              if (list.isEmpty) {
                return _emptyState(context);
              }
      
              return RefreshIndicator(
                onRefresh: () => ctrl.fetchNotifications(refresh: true),
                color: GPTheme.primaryColor,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: list.length +
                      (typeFilter == null && ctrl.hasMore.value ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 4),
                  itemBuilder: (ctx, i) {
                    if (i == list.length) {
                      // Loader de pagination (uniquement liste non filtrée)
                      ctrl.fetchNotifications();
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                            child: CircularProgressIndicator()),
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

  List<AppNotification> _filtered(NotifsPageController ctrl) {
    if (typeFilter == null) return ctrl.notifications;
    return ctrl.notifications
        .where((n) => typeFilter!.contains(n.type))
        .toList();
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
            typeFilter == null ? 'Vous êtes à jour !' : 'Rien de nouveau ici pour le moment.',
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
      'media'                                       => Icons.play_circle_outline_rounded,
      'promo' || 'promotion' || 'promotion_reminder' => Icons.local_offer_outlined,
      'partner'                                      => Icons.storefront_outlined,
      'campaign'                                      => Icons.campaign_outlined,
      'dating_match'                                  => Icons.favorite_rounded,
      'subscription'                                  => Icons.workspace_premium_rounded,
      _                                                => Icons.notifications_outlined,
    };
  }

  Color _typeColor(String type, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (type) {
      'media'                                       => Colors.blue,
      'promo' || 'promotion' || 'promotion_reminder' =>
        isDark ? GPTheme.clubColor : GPTheme.clubOnColor,
      'partner'                                      =>
        isDark ? GPTheme.clubColor : GPTheme.clubOnColor,
      'campaign'                                      => Colors.purple,
      'dating_match'                                  => Colors.pinkAccent,
      'subscription'                                  => Colors.amber.shade700,
      _                                                => GPTheme.primaryColor,
    };
  }
}