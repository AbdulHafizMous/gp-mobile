import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/data/mocks/spaces_mock.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/notification_service.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/notification.dart';
import 'package:grand_public_v2/app/data/models/user.dart';
import 'package:grand_public_v2/app/data/models/space_model.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class MainPageController extends GetxController {
  final spaces = <SpaceModel>[].obs;
  final isSpacesLoading = true.obs;

  List<AppNotification> notifications = [];

  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  // ─── Load spaces ─────────────────────────────────────────────────────────────
  Future<void> loadSpaces() async {
    isSpacesLoading.value = true;
    try {
      if (useMock) {
        spaces.value = kMockSpaces.map(SpaceModel.fromJson).toList();
      } else {
        final r = await RequestService().get('/spaces');
        final list = (r.data['data']['spaces'] as List<dynamic>? ?? [])
            .map((j) => SpaceModel.fromJson(j as Map<String, dynamic>))
            .toList();
        spaces.value = list;
      }
    } catch (e) {
      debugPrint('Error loading spaces: $e');
    } finally {
      isSpacesLoading.value = false;
    }
  }

  // ─── Existing methods (unchanged) ────────────────────────────────────────────

  Future<void> initialLoad() async {
    await NotificationService.init();
    debugPrint("Fetching User");
    activeUser.value = await getUser();
    await loadSpaces();
    _checkClubReminder();
  }

  /// Rappel Club (activable/désactivable dans Club > Paramètres) : à chaque
  /// ouverture/reprise de l'app, vérifie côté serveur s'il existe des offres
  /// éligibles non signalées récemment, et déclenche une notif locale.
  /// Le serveur gère lui-même le respect du toggle et le throttling (1x/24h).
  Future<void> _checkClubReminder() async {
    try {
      if (useMock || activeUser.value.id == 0) return;
      final res = await RequestService().get('/club/reminder-check');
      final data = res.data['data'];
      if (data != null && data['should_notify'] == true) {
        await NotificationService.showLocalNotification(
          title: data['title'] ?? 'Des offres vous attendent au Club 🎁',
          body: data['body'] ?? '',
          route: '/home/club',
        );
      }
    } catch (e) {
      debugPrint('checkClubReminder error: $e');
    }
  }

  Future<void> initPusherClient() async {
    if (kIsWeb) {
      debugPrint('Pusher not initialized on web');
      return;
    }
    try {
      await pusher.init(
        apiKey: PUSHER_API_KEY,
        cluster: PUSHER_API_CLUSTER,
        logToConsole: true,
        onConnectionStateChange: (state, _) =>
            debugPrint('Connection state changed: $state'),
        onError: (error, code, data) => debugPrint('Pusher error: $error'),
        onSubscriptionSucceeded: (channel, _) =>
            debugPrint('Subscription succeeded: $channel'),
        onEvent: (PusherEvent event) {
          debugPrint(event.data);
          try {
            notifications.add(
              AppNotification(
                id: DateTime.now().millisecondsSinceEpoch,
                isRead: false,
                body: event.data["description"],
                title: event.data["title"],
                createdAt: DateTime.now().toIso8601String(),
                type: "general"
              ),
            );
          } catch (e) {
            debugPrint('Malformed pusher event: $e');
          }
        },
      );
      await pusher.subscribe(channelName: 'new-notification');
      await pusher.connect();
    } catch (e) {
      debugPrint("ERROR: $e");
    }
  }

  Future<User> getUser() async {
    try {
      dynamic jsonVal;
      if (useMock) {
        jsonVal = {
          "id": 1,
          "name": "Hafiz MOUSTAPHA",
          "username": null,
          "phone": "+2290161648007",
          "avatar_url": null,
          "birthday": null,
          "city": null,
          "gender": null,
          "description": null,
          "looking_for_gender": null,
          "fcm_token": null,
          "firebase_id": null,
          "role": "user",
          "email": "hafizmoustapha64@gmail.com",
          "country_code": "BJ",
          "is_otp_verified": true,
          "is_active": true,
          "needs_completion": false,
          "email_verified_at": null,
          "created_at": "2026-03-16T10:30:00.000000Z",
          "updated_at": "2026-03-16T10:30:00.000000Z",
        };
      } else {
        final response = await RequestService().get('/auth/me');
        jsonVal = response.data;
      }

      final data = jsonVal['data']['user'];
      User user = User.fromJson(data);
      activeUser.value = user;
      GetStorage().write('username', data['name']);
      GetStorage().write('email', data['email']);
      return user;
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint(
          'Error: ${e.response?.statusCode} ${e.response?.statusMessage}',
        );
        await ToastHelper.showToast(
          'Server error: ${e.response?.statusCode} ${e.response?.statusMessage}',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        debugPrint('Error: ${e.message}');
        await ToastHelper.showToast(
          'Error: ${e.message}',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return User.empty();
  }

  @override
  void onInit() {
    super.onInit();
    initPusherClient();
    initialLoad();
  }

  void clear() {
    GetStorage().remove('isLogged');
  }
}
