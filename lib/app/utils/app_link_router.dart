import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/space_model.dart';
import 'package:grand_public_v2/app/modules/club/views/club_view.dart';
import 'package:grand_public_v2/app/modules/club/views/partner_detail_view.dart';
import 'package:grand_public_v2/app/modules/pages/vid_detail.dart';
import 'package:grand_public_v2/app/modules/shop/views/shop_detail_view.dart';
import 'package:grand_public_v2/app/modules/social/controllers/chat_controller.dart';
import 'package:grand_public_v2/app/modules/social/views/chat_list_view.dart';
import 'package:grand_public_v2/app/modules/social/views/chat_room_view.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

/// Point d'entrée UNIQUE pour toute navigation déclenchée depuis l'extérieur
/// de l'app : tap sur une notification push, lien partagé ouvert (deep
/// link universel `https://grandpublic.bj/m/{type}/{id}` ou schéma custom
/// `grandpublic://{type}/{id}`).
///
/// Centraliser cette logique évite la divergence qu'on avait avant (routes
/// GetX nommées avec paramètres qui n'existaient pas réellement).
class AppLinkRouter {
  /// [type] : media | promotion | club | partner | listing | channel |
  ///          chat_private | chat_channel
  static Future<void> route(String type, {String? id, Map<String, dynamic>? extra}) async {
    try {
      switch (type) {
        case 'media':
          if (id == null) return;
          final res = await RequestService().get('/videos/$id');
          if (res.statusCode == 200) {
            final video = SpaceVideo.fromJson(res.data['data']);
            Get.to(() => VidDetail(video: video));
          }
          break;

        case 'promotion':
        case 'club':
        case 'promotion_reminder':
          // Pas (encore) de vue de détail d'offre indépendante accessible
          // par id seul côté navigation externe → on ouvre le Club, qui
          // affiche la liste des offres (l'utilisateur peut ouvrir la
          // sienne). Le detail exact reste accessible en un tap de plus.
          Get.to(() => const ClubView());
          break;

        case 'partner':
          if (id == null) return;
          Get.to(() => PartnerDetailView(partnerId: int.parse(id)));
          break;

        case 'listing':
          if (id == null) return;
          Get.to(() => ShopDetailView(listingId: int.parse(id)));
          break;

        case 'channel':
        case 'chat_channel':
          Get.to(() => const ChatListView());
          break;

        case 'chat_private':
          final chatCtrl = Get.isRegistered<ChatController>()
              ? Get.find<ChatController>()
              : Get.put(ChatController());
          final convId = extra?['conversation_id'] ?? id;
          if (convId == null) {
            Get.to(() => const ChatListView());
            return;
          }
          await chatCtrl.loadPrivateConversations();
          final conv = chatCtrl.privateConversations
              .firstWhereOrNull((c) => c.id.toString() == convId.toString());
          if (conv != null) {
            await chatCtrl.openPrivateConversation(conv);
            Get.to(() => ChatRoomView(privateConv: conv));
          } else {
            Get.to(() => const ChatListView());
          }
          break;

        default:
          debugPrint('AppLinkRouter: type inconnu "$type"');
      }
    } catch (e) {
      debugPrint('AppLinkRouter error: $e');
    }
  }

  /// Parse une URL de partage `https://grandpublic.bj/m/{type}/{id}` ou un
  /// lien custom `grandpublic://{type}/{id}` et route en conséquence.
  static Future<void> routeFromUri(Uri uri) async {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    // https://grandpublic.bj/m/media/12  → segments = ['m', 'media', '12']
    // grandpublic://media/12             → segments = ['media', '12']
    final parts = segments.first == 'm' ? segments.skip(1).toList() : segments;
    if (parts.isEmpty) return;
    final type = parts[0];
    final id = parts.length > 1 ? parts[1] : null;
    await route(type, id: id);
  }

  /// Route à partir des données `data` d'un `RemoteMessage` FCM (ou d'un
  /// payload de notification locale).
  static Future<void> routeFromNotificationData(Map<String, dynamic> data) async {
    final type = data['type']?.toString();
    if (type == null) return;
    final id = data['media_id'] ?? data['promotion_id'] ?? data['partner_id'] ??
        data['listing_id'] ?? data['channel_id'] ?? data['conversation_id'];
    await route(type, id: id?.toString(), extra: data);
  }
}
