import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/models/comment.dart';
import 'package:grand_public_v2/app/data/models/notification.dart';
import 'package:grand_public_v2/app/data/models/subscription.dart';
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


  void changeCurrentIndex(int index) {
    currentIndex.value = index;
  }

  void clear() {
    GetStorage().remove('isLogged');
  }
}
