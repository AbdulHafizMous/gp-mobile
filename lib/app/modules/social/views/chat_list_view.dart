// lib/app/modules/social/views/chat_list_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/chat_models.dart';
import 'package:grand_public_v2/app/modules/social/controllers/chat_controller.dart';
import 'package:grand_public_v2/app/modules/social/views/chat_room_view.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? const Color(0xFF111111) : Colors.white;
  Color get surface => isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50;
  Color get primaryText =>
      Theme.of(this).textTheme.bodyLarge?.color ??
      (isDark ? Colors.white : Colors.black87);
  Color get subtleText => Theme.of(this).hintColor;
  Color get divColor => Theme.of(this).dividerColor;
  Color get cardColor =>
      isDark ? const Color(0xFF1E1E1E) : Colors.white;
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT LIST VIEW
// ─────────────────────────────────────────────────────────────────────────────
class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final ChatController _ctrl = Get.find<ChatController>();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: context.bg,
      body: Column(
        children: [
          // ── Header My GP / Chat ──────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF111111) : Colors.black,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My GP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                // Onglets : En ligne / Messages
                TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: GPTheme.primaryColor,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 15),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 10, color: Colors.green),
                          SizedBox(width: 6),
                          Text('En ligne'),
                        ],
                      ),
                    ),
                    Tab(text: 'Chat'),
                  ],
                ),
              ],
            ),
          ),

          // ── Search bar ──────────────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF111111) : Colors.black,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: TextField(
              controller: _ctrl.searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher: ex(#Tech; #Musique; #Politique ect...)',
                hintStyle:
                    const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Subtitle ────────────────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF111111) : Colors.black,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: const Text(
              'Rejoignez un ou plusieurs chats et chattez avec des ami(e)s',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),

          // ── Tab content ──────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _ChannelsList(ctrl: _ctrl),
                _PrivateMessagesList(ctrl: _ctrl),
              ],
            ),
          ),
        ],
      ),
      // FAB pour créer un canal (admin)
      floatingActionButton: FloatingActionButton(
        backgroundColor: GPTheme.primaryColor,
        child: const Icon(Icons.add_rounded, color: Colors.white),
        onPressed: () {
          // TODO: créer un canal
          Get.snackbar(
            'Bientôt disponible',
            'La création de canaux arrive bientôt',
            backgroundColor: Colors.black87,
            colorText: Colors.white,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHANNELS LIST (onglet "En ligne")
// ─────────────────────────────────────────────────────────────────────────────
class _ChannelsList extends StatelessWidget {
  final ChatController ctrl;
  const _ChannelsList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isChannelsLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: GPTheme.primaryColor),
        );
      }
      final list = ctrl.filteredChannels;
      if (list.isEmpty) {
        return Center(
          child: Text(
            'Aucun canal trouvé',
            style: TextStyle(color: context.subtleText),
          ),
        );
      }
      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: list.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: context.divColor),
        itemBuilder: (_, i) => _ChannelTile(
          channel: list[i],
          onJoin: () => ctrl.joinChannel(list[i]),
          onTap: list[i].isJoined
              ? () => _openChannel(context, list[i])
              : null,
        ),
      );
    });
  }

  void _openChannel(BuildContext context, ChatChannel channel) async {
    await ctrl.openChannel(channel);
    Get.to(() => ChatRoomView(channel: channel));
  }
}

class _ChannelTile extends StatelessWidget {
  final ChatChannel channel;
  final VoidCallback onJoin;
  final VoidCallback? onTap;

  const _ChannelTile({
    required this.channel,
    required this.onJoin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: GPTheme.primaryColor,
            backgroundImage: channel.imageUrl != null
                ? NetworkImage(channel.imageUrl!)
                : null,
            child: channel.imageUrl == null
                ? Text(
                    channel.name[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          if (channel.isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.bg, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        channel.name,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: context.primaryText,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
            ),
          ),
          Text(
            '${channel.membersCount} personnes ont rejoint ce chat',
            style: TextStyle(color: context.subtleText, fontSize: 12),
          ),
        ],
      ),
      trailing: channel.isJoined
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: GPTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: GPTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Rejoint',
                style: TextStyle(
                    color: GPTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            )
          : GestureDetector(
              onTap: onJoin,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: GPTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Rejoindre',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE MESSAGES LIST (onglet "Chat")
// ─────────────────────────────────────────────────────────────────────────────
class _PrivateMessagesList extends StatelessWidget {
  final ChatController ctrl;
  const _PrivateMessagesList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final convs = ctrl.privateConversations;
      if (convs.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 48, color: context.subtleText),
              const SizedBox(height: 12),
              Text(
                'Aucune conversation pour l\'instant',
                style: TextStyle(color: context.subtleText, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Likez des profils dans Dating pour démarrer !',
                style: TextStyle(
                    color: context.subtleText,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // Compteur
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${convs.length}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: context.primaryText,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: convs.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: context.divColor),
              itemBuilder: (_, i) => _ConversationTile(
                conv: convs[i],
                onTap: () async {
                  await ctrl.openPrivateConversation(convs[i]);
                  Get.to(() => ChatRoomView(privateConv: convs[i]));
                },
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _ConversationTile extends StatelessWidget {
  final PrivateConversation conv;
  final VoidCallback onTap;

  const _ConversationTile({required this.conv, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: GPTheme.primaryColor.withValues(alpha: 0.2),
            backgroundImage: conv.otherUserAvatar != null
                ? NetworkImage(conv.otherUserAvatar!)
                : null,
            child: conv.otherUserAvatar == null
                ? Text(
                    conv.otherUserName[0].toUpperCase(),
                    style: TextStyle(
                      color: GPTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          if (conv.otherIsOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.bg, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        conv.otherUserName,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: context.primaryText,
        ),
      ),
      subtitle: Text(
        conv.lastMessage?.content ?? '',
        style: TextStyle(color: context.subtleText, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            conv.lastMessage?.timeLabel ?? '',
            style: TextStyle(color: context.subtleText, fontSize: 11),
          ),
          if (conv.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: GPTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${conv.unreadCount}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}