import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:grand_public_v2/app/modules/social/controllers/chat_controller.dart';
import 'package:grand_public_v2/app/modules/social/views/chat_room_view.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

/// Domaine public utilisé pour générer des liens de partage cliquables
/// (médias, offres du Club, annonces Bizz, canaux de discussion…).
const String kShareHost = 'https://grandpublic.bj';

/// Utilitaire de partage centralisé pour toute l'app : "Partager via…"
/// (partage système) et "Envoyer à un ami" (message privé in-app).
class ShareHelper {
  static String buildLink(String path) => '$kShareHost$path';

  /// Ouvre la feuille de partage. [path] est le chemin relatif utilisé pour
  /// construire un lien cliquable (ex: '/media/12', '/club/offre/3',
  /// '/bizz/annonce/9', '/canal/5').
  static Future<void> showShareSheet(
    BuildContext context, {
    required String title,
    String? subtitle,
    required String path,
    required String type, // media | offer | listing | channel | partner
  }) async {
    final link = buildLink(path);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareSheet(
        title: title,
        subtitle: subtitle,
        link: link,
        type: type,
      ),
    );
  }
}

class _ShareSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String link;
  final String type;
  const _ShareSheet({
    required this.title,
    this.subtitle,
    required this.link,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('Partager',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 4),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: GPTheme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.ios_share_rounded, color: GPTheme.primaryColor),
            ),
            title: const Text('Partager via…'),
            subtitle: const Text('WhatsApp, Messages, autres apps'),
            onTap: () {
              Navigator.pop(context);
              SharePlus.instance.share(
                ShareParams(text: '$title\n$link'),
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: GPTheme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.send_rounded, color: GPTheme.primaryColor),
            ),
            title: const Text('Envoyer à un ami'),
            subtitle: const Text('Via une conversation Grand Public'),
            onTap: () {
              Navigator.pop(context);
              _pickFriendAndSend(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickFriendAndSend(BuildContext context) async {
    final chatCtrl = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : Get.put(ChatController());

    // Charge l'annuaire des utilisateurs pour le picker.
    List<dynamic> users = [];
    try {
      final res = await RequestService().get('/social/users');
      if (res.statusCode == 200) users = res.data['data'] as List;
    } catch (_) {}

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Choisir un ami',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (_, i) {
                  final u = users[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: u['avatar_url'] != null
                          ? NetworkImage(u['avatar_url'])
                          : null,
                      child: u['avatar_url'] == null
                          ? Text((u['name'] ?? '?')[0].toUpperCase())
                          : null,
                    ),
                    title: Text(u['name'] ?? ''),
                    onTap: () async {
                      Navigator.pop(context);
                      final convId =
                          await chatCtrl.startConversationWithUser(u['id']);
                      if (convId != null) {
                        await chatCtrl.loadPrivateConversations();
                        final conv = chatCtrl.privateConversations
                            .firstWhereOrNull((c) => c.id == convId);
                        if (conv != null) {
                          chatCtrl.messageCtrl.text = '$title\n$link';
                          await chatCtrl.openPrivateConversation(conv);
                          Get.to(() => ChatRoomView(privateConv: conv));
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
