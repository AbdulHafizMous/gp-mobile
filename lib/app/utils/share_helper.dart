import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:grand_public_v2/app/data/models/chat_models.dart';
import 'package:grand_public_v2/app/modules/social/controllers/chat_controller.dart';
import 'package:grand_public_v2/app/modules/social/views/chat_room_view.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

/// Domaine public des liens de partage : https://grandpublic.bj/m/{type}/{id}
/// Résolu côté serveur (ShareController) : aperçu Open Graph, ouverture de l'app si elle
/// est installée, sinon page « Télécharger Grandpublic » (le contenu s'ouvre au 1er lancement).
const String kShareHost = 'https://grandpublic.bj';

/// Types de liens gérés (identiques côté serveur ShareController / AppLinkRouter) :
/// media · short · article · channel (chaîne) · canal (canal de discussion) · promotion ·
/// partner · listing (Bizz) · bm_track · bm_playlist · bm_live · game · room.
class ShareHelper {
  static String buildLink(String type, String id) => '$kShareHost/m/$type/$id';

  /// Texte riche pour un partage HORS de l'app (WhatsApp, SMS…) : titre, description, lien
  /// et invitation à télécharger l'application.
  static String buildExternalText({
    required String title,
    String? subtitle,
    required String link,
  }) {
    final b = StringBuffer('📣 $title');
    if (subtitle != null && subtitle.trim().isNotEmpty) {
      final s = subtitle.trim();
      b.write('\n\n${s.length > 140 ? '${s.substring(0, 140)}…' : s}');
    }
    b.write('\n\n👉 $link');
    b.write('\n\n📲 Ouvre-le dans Grandpublic — télécharge l\'application si tu ne l\'as pas encore.');
    return b.toString();
  }

  /// Texte court pour un message INTERNE (conversation / canal) : le lien est rendu en carte.
  static String buildInternalText(String title, String link) => '$title\n$link';

  static void showShareSheet(
    BuildContext context, {
    required String title,
    String? subtitle,
    required String type,
    required String id,
    String? imageUrl,
  }) {
    final link = buildLink(type, id);
    Get.bottomSheet(
      _ShareSheet(title: title, subtitle: subtitle, link: link, type: type, imageUrl: imageUrl),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// Raccourci : partage direct hors app (sans feuille).
  static Future<void> shareExternal({
    required String title,
    String? subtitle,
    required String type,
    required String id,
  }) {
    final link = buildLink(type, id);
    return SharePlus.instance.share(
      ShareParams(text: buildExternalText(title: title, subtitle: subtitle, link: link)),
    );
  }

  /// Envoie [text] dans un canal de la communauté.
  static Future<bool> postToChannel(int channelId, String text) async {
    try {
      final res = await RequestService().post(
        '/social/channels/$channelId/messages',
        data: dio.FormData.fromMap({'type': 'text', 'content': text}),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Envoie [text] dans une conversation privée.
  static Future<bool> postToConversation(int convId, String text) async {
    try {
      final res = await RequestService().post(
        '/social/conversations/$convId/messages',
        data: dio.FormData.fromMap({'type': 'text', 'content': text}),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}

extension _Tx on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? const Color(0xFF0D0D0D) : Colors.white;
  Color get inputBg => isDark ? Colors.white10 : Colors.grey.shade100;
  Color get primary => Theme.of(this).textTheme.bodyLarge!.color!;
  Color get subtle => Theme.of(this).hintColor;
}

class _ShareSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String link;
  final String type;
  final String? imageUrl;
  const _ShareSheet({
    required this.title,
    this.subtitle,
    required this.link,
    required this.type,
    this.imageUrl,
  });

  Widget _row(
    BuildContext c, {
    required IconData icon,
    required String label,
    required String hint,
    required VoidCallback onTap,
    Color? color,
  }) {
    final col = color ?? GPTheme.primaryColor;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: col.withValues(alpha: 0.12),
        child: Icon(icon, color: col),
      ),
      title: Text(label, style: TextStyle(color: c.primary, fontWeight: FontWeight.w700)),
      subtitle: Text(hint, style: TextStyle(color: c.subtle, fontSize: 12)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
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
            Row(
              children: [
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Partager',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: context.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.subtle, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _row(
              context,
              icon: Icons.groups_rounded,
              label: 'Dans la communauté',
              hint: 'Publier dans un de tes canaux Grandpublic',
              onTap: () {
                Get.back();
                Get.bottomSheet(
                  _ChannelPickerSheet(text: ShareHelper.buildInternalText(title, link)),
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                );
              },
            ),
            _row(
              context,
              icon: Icons.send_rounded,
              label: 'Envoyer à un ami',
              hint: 'Via une conversation Grandpublic',
              onTap: () {
                Get.back();
                Get.bottomSheet(
                  _FriendPickerSheet(text: ShareHelper.buildInternalText(title, link)),
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                );
              },
            ),
            _row(
              context,
              icon: Icons.ios_share_rounded,
              label: 'Partager hors de l\'app',
              hint: 'WhatsApp, SMS, réseaux… avec lien de téléchargement',
              onTap: () {
                Get.back();
                SharePlus.instance.share(
                  ShareParams(
                    text: ShareHelper.buildExternalText(
                      title: title,
                      subtitle: subtitle,
                      link: link,
                    ),
                  ),
                );
              },
            ),
            _row(
              context,
              icon: Icons.link_rounded,
              label: 'Copier le lien',
              hint: link,
              color: Colors.blueGrey,
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: link));
                Get.back();
                Get.snackbar(
                  'Lien copié',
                  link,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(12),
                  duration: const Duration(seconds: 2),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Feuille de choix d'un canal de la communauté (canaux rejoints) puis envoi immédiat.
class _ChannelPickerSheet extends StatefulWidget {
  final String text;
  const _ChannelPickerSheet({required this.text});

  @override
  State<_ChannelPickerSheet> createState() => _ChannelPickerSheetState();
}

class _ChannelPickerSheetState extends State<_ChannelPickerSheet> {
  late final ChatController _chat = Get.isRegistered<ChatController>()
      ? Get.find<ChatController>()
      : Get.put(ChatController());
  final _sending = <int>{};

  @override
  void initState() {
    super.initState();
    if (_chat.channels.isEmpty) _chat.loadChannels();
  }

  Future<void> _send(ChatChannel ch) async {
    if (_sending.contains(ch.id)) return;
    setState(() => _sending.add(ch.id));
    final ok = await ShareHelper.postToChannel(ch.id, widget.text);
    if (!mounted) return;
    Get.back();
    Get.snackbar(
      ok ? 'Partagé' : 'Échec',
      ok ? 'Publié dans #${ch.name}' : 'Impossible de publier dans #${ch.name}',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
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
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Choisir un canal',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: context.primary),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              final list = _chat.channels.where((c) => c.isJoined || c.isMine).toList();
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Rejoins d\'abord un canal dans Social pour y partager.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.subtle),
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final c = list[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: GPTheme.socialColor.withValues(alpha: 0.15),
                      backgroundImage: (c.imageUrl != null && c.imageUrl!.isNotEmpty)
                          ? NetworkImage(c.imageUrl!)
                          : null,
                      child: (c.imageUrl == null || c.imageUrl!.isEmpty)
                          ? Text('#', style: TextStyle(color: GPTheme.socialColor, fontWeight: FontWeight.w900))
                          : null,
                    ),
                    title: Text('#${c.name}', style: TextStyle(color: context.primary, fontWeight: FontWeight.w700)),
                    subtitle: Text('${c.membersCount} membres', style: TextStyle(color: context.subtle, fontSize: 12)),
                    trailing: _sending.contains(c.id)
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 18),
                    onTap: () => _send(c),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Feuille « Envoyer à un ami » : annuaire + recherche, envoi immédiat du lien (carte).
class _FriendPickerSheet extends StatefulWidget {
  final String text;
  const _FriendPickerSheet({required this.text});

  @override
  State<_FriendPickerSheet> createState() => _FriendPickerSheetState();
}

class _FriendPickerSheetState extends State<_FriendPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  final _sending = <int>{};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _load();
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
    final chat = Get.isRegistered<ChatController>() ? Get.find<ChatController>() : Get.put(ChatController());
    final convId = await chat.startConversationWithUser(id);
    var ok = false;
    if (convId != null) ok = await ShareHelper.postToConversation(convId, widget.text);
    if (!mounted) return;
    if (ok) {
      await chat.loadPrivateConversations();
      Get.back();
      Get.snackbar(
        'Envoyé',
        'Lien envoyé à ${u['name'] ?? 'ton ami'}',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        mainButton: TextButton(
          onPressed: () {
            final conv = chat.privateConversations.firstWhereOrNull((c) => c.id == convId);
            if (conv != null) Get.to(() => ChatRoomView(privateConv: conv));
          },
          child: const Text('Voir'),
        ),
      );
    } else {
      setState(() => _sending.remove(id));
      Get.snackbar('Échec', 'Message non envoyé', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
    }
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
            child: Text(
              'Choisir un ami',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: context.primary),
            ),
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
                ? Center(child: Text('Aucun utilisateur trouvé', style: TextStyle(color: context.subtle)))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final u = _filtered[i] as Map;
                      final sending = _sending.contains(u['id']);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: GPTheme.primaryColor.withValues(alpha: 0.12),
                          backgroundImage: u['avatar_url'] != null ? NetworkImage(u['avatar_url']) : null,
                          child: u['avatar_url'] == null
                              ? Text(
                                  (u['name'] ?? '?').toString()[0].toUpperCase(),
                                  style: TextStyle(color: GPTheme.primaryColor, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        title: Text(u['name'] ?? '', style: TextStyle(color: context.primary)),
                        trailing: sending
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send_rounded, size: 18),
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
