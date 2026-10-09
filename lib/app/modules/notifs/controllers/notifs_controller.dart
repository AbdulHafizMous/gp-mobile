import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/notification.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/app_link_router.dart';

// ── Catégories de filtre (mappées sur les `type` réellement émis par le
// backend — voir NotificationService / Jobs côté Laravel) ──────────────────
class NotifCategory {
  final String id;
  final String label;
  final List<String> types; // vide = "Toutes"
  const NotifCategory(this.id, this.label, this.types);
}

const List<NotifCategory> kNotifCategories = [
  NotifCategory('all', 'Toutes', []),
  NotifCategory('club', 'Club', [
    'promo',
    'promotion',
    'promotion_reminder',
    'partner',
  ]),
  NotifCategory('social', 'Social', [
    'chat_channel',
    'chat_private',
    'dating_match',
  ]),
  NotifCategory('media', 'Media', ['media']),
  NotifCategory('account', 'Compte', ['subscription', 'campaign']),
  NotifCategory('blowmusic', 'Blowmusic', [
    'bm_track',
    'bm_live',
    'bm_playlist',
  ]),
  // Les types gz_* gardent leur préfixe (compat backend / apps installées).
  NotifCategory('youwiiin', 'Youwiiin', [
    'gz_game',
    'gz_reward',
    'gz_record',
    'gz_invite',
    'gz_room_started',
    'gz_room_result',
  ]),
];

class NotifsPageController extends GetxController {
  final notifications = <AppNotification>[].obs;
  final isLoading = false.obs;
  final unreadCount = 0.obs;
  final hasMore = false.obs;

  // ── Filtre + tri (pilotés depuis la page elle-même, ou pré-sélectionnés
  // avant navigation — ex: le bouton "Notifs" du Club) ───────────────────
  final selectedCategory = 'all'.obs;
  final sortMostRecentFirst = true.obs; // false = non-lues d'abord

  List<AppNotification> get visibleNotifications {
    // « gamez » = ancien identifiant de la catégorie Youwiiin (toujours accepté).
    final catId = selectedCategory.value == 'gamez'
        ? 'youwiiin'
        : selectedCategory.value;
    final cat = kNotifCategories.firstWhere(
      (c) => c.id == catId,
      orElse: () => kNotifCategories.first,
    );
    var list = cat.types.isEmpty
        ? notifications.toList()
        : notifications
              .where(
                (n) =>
                    cat.types.contains(n.type) ||
                    // Le module renvoyé par le backend peut valoir
                    // « gamez » (ancien) ou « youwiiin ».
                    (cat.id == 'youwiiin' &&
                        (n.module == 'youwiiin' || n.module == 'gamez')),
              )
              .toList();

    if (!sortMostRecentFirst.value) {
      list.sort((a, b) {
        if (a.isRead == b.isRead) return 0;
        return a.isRead ? 1 : -1; // non-lues d'abord
      });
    }
    // Par défaut la liste arrive déjà triée du plus récent au plus ancien
    // (ordre backend), donc "Plus récentes" ne nécessite pas de re-tri.
    return list;
  }

  int _currentPage = 1;

  /// Depuis Blowmusic / Youwiiin, la page s'ouvre directement sur la catégorie
  /// du module (le Club continue de pré-sélectionner « club » lui-même).
  void preselectModuleCategory() {
    switch (AppModeService.current) {
      case AppMode.blowMusic:
        selectedCategory.value = 'blowmusic';
        break;
      case AppMode.youwiiin:
        selectedCategory.value = 'youwiiin';
        break;
      case AppMode.grandPublic:
        if (selectedCategory.value == 'blowmusic' ||
            selectedCategory.value == 'youwiiin' ||
            selectedCategory.value == 'gamez') {
          selectedCategory.value = 'all';
        }
    }
  }

  @override
  void onInit() {
    super.onInit();
    preselectModuleCategory();
    fetchNotifications();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FETCH
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      notifications.clear();
    }

    debugPrint('Fetching notifications - page $_currentPage');

    isLoading.value = true;

    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 600));
        final mock = List.generate(
          20,
          (i) => AppNotification(
            id: i + 1,
            title: i % 3 == 0
                ? '🎬 Nouveau contenu'
                : i % 3 == 1
                ? '🔔 Notification'
                : '🎁 Offre spéciale',
            body: 'Description de la notification numéro ${i + 1}.',
            type: i % 3 == 0
                ? 'media'
                : i % 3 == 1
                ? 'general'
                : 'promo',
            route: i % 3 == 0 ? '/videos/${i + 1}' : null,
            isRead: i % 4 == 0,
            createdAt: 'Il y a ${i + 1}h',
          ),
        );
        notifications.value = mock;
        unreadCount.value = mock.where((n) => !n.isRead).length;
        return;
      }

      final response = await RequestService().get(
        '/notifications',
        queryParameters: {'page': _currentPage, 'per_page': 20},
      );

      debugPrint(
        'Notifications response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List raw = data['notifications'] as List;
        final list = raw.map((e) => AppNotification.fromJson(e)).toList();

        if (refresh) {
          notifications.value = list;
        } else {
          notifications.addAll(list);
        }

        unreadCount.value = data['unread_count'] as int? ?? 0;
        hasMore.value = data['pagination']['has_more_pages'] as bool? ?? false;
        _currentPage++;
      }
    } on DioException catch (e) {
      debugPrint('fetchNotifications DioError: ${e.message}');
    } catch (e) {
      debugPrint('fetchNotifications error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MARQUER COMME LU
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> markAsRead(AppNotification notif) async {
    if (notif.isRead) return;

    // Optimistic update
    final idx = notifications.indexWhere((n) => n.id == notif.id);
    if (idx != -1) {
      notifications[idx] = notif.copyWith(
        isRead: true,
        readAt: DateTime.now().toIso8601String(),
      );
      unreadCount.value = (unreadCount.value - 1).clamp(0, 9999);
    }

    if (useMock) return;

    try {
      await RequestService().post('/notifications/${notif.id}/read');
    } catch (e) {
      // Rollback
      if (idx != -1) notifications[idx] = notif;
      unreadCount.value++;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MARQUER TOUT LU
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> markAllAsRead() async {
    // Optimistic update
    notifications.value = notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    unreadCount.value = 0;

    if (useMock) return;

    try {
      await RequestService().post('/notifications/read-all');
    } catch (e) {
      debugPrint('markAllAsRead error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SUPPRIMER
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> deleteNotification(AppNotification notif) async {
    final wasUnread = !notif.isRead;
    notifications.removeWhere((n) => n.id == notif.id);
    if (wasUnread) unreadCount.value = (unreadCount.value - 1).clamp(0, 9999);

    if (useMock) return;

    try {
      await RequestService().delete('/notifications/${notif.id}');
    } catch (e) {
      debugPrint('deleteNotification error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NAVIGATION — tap sur une notification
  // ══════════════════════════════════════════════════════════════════════════
  void onTapNotification(AppNotification notif) {
    markAsRead(notif);

    // Notifications Youwiiin (invitation, salle lancée, résultat…) : le
    // routeur central sait ouvrir le lobby de la bonne salle.
    if (notif.type.startsWith('gz_')) {
      final code = (notif.data?['code'] ?? notif.data?['room_code'])
          ?.toString();
      final r = notif.route ?? '';
      final fromRoute = RegExp(r'/room/([^/?#]+)').firstMatch(r)?.group(1);
      final roomCode = code ?? fromRoute;
      if (roomCode != null && roomCode.isNotEmpty) {
        AppLinkRouter.route(notif.type, id: roomCode, extra: notif.data);
        return;
      }
    }

    final route = notif.route;
    if (route == null || route.isEmpty) return;

    // Les routes internes au shell Home (Espaces/Social/Club, drawer fixe...)
    // sont gérées par la pile interne de HomeController, PAS par le routeur
    // nommé de GetX — sinon on pousse une 2e HomeView par-dessus l'existante
    // (même GlobalKey de Scaffold utilisé deux fois → crash). Voir aussi
    // AppLinkRouter, qui centralise déjà cette règle pour les deep links.
    // Notifications de module : on bascule dans le module puis on ouvre le bon onglet.
    if (route.startsWith('/blowmusic') || route.startsWith('/gamez') ||
        route.startsWith('/youwiiin')) {
      final isBlow = route.startsWith('/blowmusic');
      // Ancienne route /gamez/... → /youwiiin/...
      final target = route.startsWith('/gamez')
          ? route.replaceFirst('/gamez', '/youwiiin')
          : route;
      AppModeService.setMode(isBlow ? AppMode.blowMusic : AppMode.youwiiin).then((
        _,
      ) {
        Get.offAllNamed(target, arguments: notif.data);
      });
      return;
    }

    if (route.startsWith('/home') || route.startsWith('/social')) {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().navigateTo(route, params: notif.data ?? {});
        return;
      }
    }

    Get.toNamed(route, arguments: notif.data);
  }
}
