import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/notification.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

class NotifsPageController extends GetxController {
  final notifications = <AppNotification>[].obs;
  final isLoading = false.obs;
  final unreadCount = 0.obs;
  final hasMore = false.obs;

  int _currentPage = 1;

  @override
  void onInit() {
    super.onInit();
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

    final route = notif.route;
    if (route == null || route.isEmpty) return;

    // Les routes internes au shell Home (Espaces/Social/Club, drawer fixe...)
    // sont gérées par la pile interne de HomeController, PAS par le routeur
    // nommé de GetX — sinon on pousse une 2e HomeView par-dessus l'existante
    // (même GlobalKey de Scaffold utilisé deux fois → crash). Voir aussi
    // AppLinkRouter, qui centralise déjà cette règle pour les deep links.
    if (route.startsWith('/home') || route.startsWith('/social')) {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().navigateTo(route, params: notif.data ?? {});
        return;
      }
    }

    Get.toNamed(route, arguments: notif.data);
  }
}