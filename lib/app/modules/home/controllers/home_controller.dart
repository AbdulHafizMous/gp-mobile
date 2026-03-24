import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/comment.dart';
import 'package:grand_public_v2/app/data/models/notification.dart';
import 'package:grand_public_v2/app/data/models/subscription.dart';
import 'package:grand_public_v2/app/data/models/user.dart';
import 'package:grand_public_v2/app/data/models/video.dart';
import 'package:grand_public_v2/app/modules/pages/about.dart';
import 'package:grand_public_v2/app/modules/pages/link_list.dart';
import 'package:grand_public_v2/app/modules/pages/link_page.dart';
import 'package:grand_public_v2/app/modules/pages/live_page.dart';
import 'package:grand_public_v2/app/modules/pages/base_home.dart';
import 'package:grand_public_v2/app/modules/pages/most_liked.dart';
import 'package:grand_public_v2/app/modules/pages/notification_page.dart';
import 'package:grand_public_v2/app/modules/pages/premium_page.dart';
import 'package:grand_public_v2/app/modules/pages/profil_page.dart';
import 'package:grand_public_v2/app/modules/pages/search_page.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class HomeController extends GetxController {
  final currentIndex = 0.obs;
  final currentVidId = "".obs;
  final currentPageName = "".obs;
  final currentId = 0.obs;

  final video = Video.empty().obs;

  TextEditingController commentEditingController = TextEditingController();

  final activeUser = User.empty().obs;

  List<CustomNotification> notifications = [];

  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  final List drawerPage = [
    const BaseHome(),
    const LivePage(),
    const NotificationPage(),
    Container(
      color: Colors.white,
      child: const Center(
        child: Text(
          'Bientôt disponible',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
    ),
    const LinkList(title: "PORTRAIT", category: "portrait"),
    const LinkList(title: "EVENTS", category: "events"),
    const LinkList(title: "OPINION", category: "opinion"),
    const LinkList(title: "INSOLITE", category: "insolite"),
    const MostLiked(),
    const Center(
      child: Text(
        "Bientôt disponible",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    ),
    const LinkPage(),
    const PremiumPage(),
    const AboutPage(),
    const SerachPage(),
    const ProfilPage(),
    // Placeholder entry instead of constructing VidDetail without a Video.
    const SizedBox(),
  ];

  Future<Video> getVideoById(int id) async {
    try {
      final response = await RequestService().get('/videos/$id');
      return Video.fromJson(response.data["data"]);
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
    return Video.empty();
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
              CustomNotification(
                description: event.data["description"],
                title: event.data["title"],
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

  Future<List<Video>> searchVideo(String search) async {
    try {
      final response = await RequestService().get(
        '/videos/search?searchTerm=$search',
      );
      return (response.data["data"] as List)
          .map((e) => Video.fromJson(e))
          .toList();
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
    return [];
  }

    Future<User> getUser() async {
    try {
      // For Test Purposes
      dynamic jsonVal;
      if (useMock) {
        jsonVal = {
          "id": 1,
          "first_name": "Hafiz",
          "last_name": "MOUSTAPHA",
          "email": "hafizmoustapha64@gmail.com",
          "google_id": null,
          "facebook_id": null,
          "terms_accepted": 1,
          "created_at": "2026-03-16T10:30:00.000000Z",
          "updated_at": "2026-03-16T10:30:00.000000Z",
          "email_verified_at": null,
          "has_active_subscriptions": false,
        };
      } else {
        final response = await RequestService().get('/auth/me');
        jsonVal = response.data;
      }

      debugPrint("Fetched User from Home Page --- response : $jsonVal");
      final data = jsonVal['data']['user'];
      activeUser.value = User.fromJson(data);
      GetStorage().write('username', data['name']);
      GetStorage().write('email', data['email']);

      // Normalize has_active_subscriptions to a Dart bool
      // final rawHas = jsonVal["has_active_subscriptions"];
      // bool normalizedHas = false;
      // if (rawHas is bool) {
      //   normalizedHas = rawHas;
      // } else if (rawHas is num) {
      //   normalizedHas = rawHas != 0;
      // } else if (rawHas is String) {
      //   final lower = rawHas.toLowerCase();
      //   normalizedHas = (lower == '1' || lower == 'true' || lower == 'yes');
      // }
      // GetStorage().write("has_active_subscriptions", normalizedHas);
      // debugPrint(
      //   'Stored has_active_subscriptions in HomeController: $normalizedHas (raw: $rawHas)',
      // );

      return User.fromJson(jsonVal);
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

  Future<List<Comment>> getVideoComment(int id) async {
    try {
      final response = await RequestService().get('/videos/$id/comments');
      return (response.data["data"] as List)
          .map((e) => Comment.fromJson(e))
          .toList();
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
    return [];
  }

  Future<void> postComment(int vidId, int? parendId, String content) async {
    try {
      await RequestService().post(
        '/comments/create',
        data: {
          "video_id": vidId,
          "parent_comment_id": parendId,
          "content": content,
        },
      );
      await ToastHelper.showToast(
        'Commentaire envoyé et attente de validation',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
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
  }

  Future<void> likeComment(int comId) async {
    try {
      await RequestService().get('comments/$comId/like');
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
  }

  Future<void> dislikeComment(int comId) async {
    try {
      await RequestService().get('comments/$comId/dislike');
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
  }

  Future<Video> fetchVideoById(int id) async => getVideoById(id);

  Future<List<Video>> fetchLatestVideoByCat(String cat) async {
    try {
      final response = await RequestService().get('/$cat/videos/latests');
      return (response.data["data"] as List)
          .map((e) => Video.fromJson(e))
          .toList();
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
    return [];
  }

  // Fetch videos for a given category (paginated response expected).
  // Example response shape contains `data`, `links` and `meta`.
  Future<List<Video>> fetchVideoByCat(String cat, {int page = 1}) async {
    try {
      final response = await RequestService().get('/$cat/videos?page=$page');
      final data = response.data;
      final items = (data["data"] as List?) ?? [];

      // Optionally you could store `links` and `meta` in controller fields
      // for pagination UI. For now we just return the list of videos.
      return items.map((e) => Video.fromJson(e)).toList();
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
    return [];
  }

  Future<List<Video>> fetchMostLiked() async {
    try {
      final response = await RequestService().get('/videos/most_liked');
      return (response.data["data"] as List)
          .map((e) => Video.fromJson(e))
          .toList();
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
    return [];
  }

  Future<List<Video>> fetchLatestVideos() async {
    try {
      final response = await RequestService().get('/videos/latests');
      return (response.data["data"] as List)
          .map((e) => Video.fromJson(e))
          .toList();
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
    return [];
  }

  Future<List<Subscription>> fetchSubscriptions() async {
    try {
      final response = await RequestService().get('/subscriptions');
      return (response.data["data"] as List)
          .map((e) => Subscription.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  Future<List<CustomNotification>> fetchNotifications() async {
    try {
      final response = await RequestService().get('/notifications');
      notifications = (response.data["data"] as List)
          .map((e) => CustomNotification.fromJson(e))
          .toList();
      debugPrint(notifications.length.toString());
      return notifications;
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  @override
  void onInit() {
    super.onInit();
    initPusherClient();
    getUser().then((user) {
      activeUser.value = user;
    });
  }

  void changeCurrentIndex(int index) {
    currentIndex.value = index;
  }

  void clear() {
    GetStorage().remove('isLogged');
  }
}
