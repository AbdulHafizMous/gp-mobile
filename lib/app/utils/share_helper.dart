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

extension _Tx on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? const Color(0xFF0D0D0D) : Colors.white;
  Color get inputBg => isDark ? Colors.white10 : Colors.grey.shade100;
  Color get primary => Theme.of(this).textTheme.bodyLarge!.color!;
  Color get subtle => Theme.of(this).hintColor;
}

/// Utilitaire de partage centralisé pour toute l'app : "Envoyer à un ami"
/// (message privé in-app) et "Partager via…" (partage système).
///
/// N.B. : on utilise exclusivement `Get.bottomSheet` / `Get.back()` (overlay
/// GetX, contexte stable) plutôt que `showModalBottomSheet`/`Navigator.pop`
/// avec le `BuildContext` de l'appelant — celui-ci peut être désactivé entre
/// deux frames (ex: bouton dans une liste qui se reconstruit), ce qui
/// provoquait un crash "Looking up a deactivated widget's ancestor".
class ShareHelper {
  static String buildLink(String path) => '$kShareHost$path';

  /// Ouvre la feuille de partage. [path] est le chemin relatif utilisé pour
  /// construire un lien cliquable (ex: '/media/12', '/club/offre/3',
  /// '/bizz/annonce/9', '/canal/5').
  static void showShareSheet(
    BuildContext context, {
    required String title,
    String? subtitle,
    required String path,
    required String type, // media | offer | listing | channel | partner
  }) {
    final link = buildLink(path);
    Get.bottomSheet(
      _ShareSheet(title: title, subtitle: subtitle, link: link, type: type),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
        color: context.bg,
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
          Text('Partager',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: context.primary)),
          const SizedBox(height: 4),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.subtle, fontSize: 13)),
          const SizedBox(height: 20),

          // "Envoyer à un ami" en premier — accès rapide au picker.
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: GPTheme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.send_rounded, color: GPTheme.primaryColor),
            ),
            title: Text('Envoyer à un ami', style: TextStyle(color: context.primary, fontWeight: FontWeight.w600)),
            subtitle: Text('Via une conversation Grand Public', style: TextStyle(color: context.subtle, fontSize: 12)),
            onTap: () {
              Get.back();
              Get.bottomSheet(
                _FriendPickerSheet(title: title, link: link),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: GPTheme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.ios_share_rounded, color: GPTheme.primaryColor),
            ),
            title: Text('Partager via…', style: TextStyle(color: context.primary, fontWeight: FontWeight.w600)),
            subtitle: Text('WhatsApp, Messages, autres apps', style: TextStyle(color: context.subtle, fontSize: 12)),
            onTap: () {
              Get.back();
              SharePlus.instance.share(ShareParams(text: '$title\n$link'));
            },
          ),
        ],
      ),
    );
  }
}

/// Feuille "Envoyer à un ami" : s'ouvre instantanément avec un loader,
/// charge l'annuaire en tâche de fond, et propose une recherche.
class _FriendPickerSheet extends StatefulWidget {
  final String title;
  final String link;
  const _FriendPickerSheet({required this.title, required this.link});

  @override
  State<_FriendPickerSheet> createState() => _FriendPickerSheetState();
}

class _FriendPickerSheetState extends State<_FriendPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  final Set<int> _sending = {};

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearch);
  }

  Future<void> _load() async {
    try {
      final res = await RequestService().get('/social/users');
      if (res.statusCode == 200) {
        _all = res.data['data'] as List;
        _filtered = _all;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((u) => (u['name'] ?? '').toString().toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _sendTo(Map u) async {
    final id = u['id'] as int;
    if (_sending.contains(id)) return;
    setState(() => _sending.add(id));

    final chatCtrl = Get.isRegistered<ChatController>() ? Get.find<ChatController>() : Get.put(ChatController());
    final convId = await chatCtrl.startConversationWithUser(id);
    if (convId != null) {
      await chatCtrl.loadPrivateConversations();
      final conv = chatCtrl.privateConversations.firstWhereOrNull((c) => c.id == convId);
      if (conv != null) {
        chatCtrl.messageCtrl.text = '${widget.title}\n${widget.link}';
        await chatCtrl.openPrivateConversation(conv);
        Get.back(); // ferme la feuille
        Get.to(() => ChatRoomView(privateConv: conv));
        return;
      }
    }
    if (mounted) setState(() => _sending.remove(id));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Choisir un ami',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: context.primary)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: context.primary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher un ami…',
                hintStyle: TextStyle(color: context.subtle, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: context.subtle),
                filled: true,
                fillColor: context.inputBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: GPTheme.primaryColor))
                : _filtered.isEmpty
                    ? Center(
                        child: Text('Aucun utilisateur trouvé', style: TextStyle(color: context.subtle)),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final u = _filtered[i] as Map;
                          final sending = _sending.contains(u['id']);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: GPTheme.primaryColor.withOpacity(0.12),
                              backgroundImage: u['avatar_url'] != null ? NetworkImage(u['avatar_url']) : null,
                              child: u['avatar_url'] == null
                                  ? Text((u['name'] ?? '?').toString()[0].toUpperCase(),
                                      style: TextStyle(color: GPTheme.primaryColor, fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            title: Text(u['name'] ?? '', style: TextStyle(color: context.primary)),
                            trailing: sending
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : null,
                            onTap: () => _sendTo(u),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
