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
extension _Tx on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? const Color(0xFF0D0D0D) : Colors.white;
  // Color get surface => isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50;
  // Color get cardBg => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get primary => Theme.of(this).textTheme.bodyLarge!.color!;
  Color get subtle => Theme.of(this).hintColor;
  Color get divider => Theme.of(this).dividerColor;
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
  late TabController _tab;
  final _ctrl = Get.find<ChatController>();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (_tab.indexIsChanging) _ctrl.chatTab.value = _tab.index;
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
 Widget build(BuildContext context) {
    final isDark = context.isDark;
    final headerBg = isDark
        ? const Color(0xFF111111)
        : GPTheme.primaryColor.withOpacity(0.9);
    return Scaffold(
      backgroundColor: context.bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            color: headerBg,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre + icône refresh
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
                    child: Row(
                      children: [
                        const Text('My GP',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5)),
                        const Spacer(),
                        Obx(() => _ctrl.isChannelsLoading.value
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white54, strokeWidth: 2))
                            : IconButton(
                                onPressed: () {
                                  _ctrl.loadChannels();
                                  _ctrl.loadPrivateConversations();
                                },
                                icon: const Icon(Icons.refresh_rounded,
                                    color: Colors.white60, size: 20),
                              )),
                      ],
                    ),
                  ),
                  // Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: _SearchBar(ctrl: _ctrl),
                  ),
                  const SizedBox(height: 8),
                  // Tabs
                  TabBar(
                    controller: _tab,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    indicatorColor: GPTheme.primaryColor,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white38,
                    labelStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(fontSize: 14),
                    tabs: const [
                      Tab(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                          SizedBox(width: 6),
                          Text('Canaux'),
                        ]),
                      ),
                      Tab(text: 'Messages privés'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Tab content ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _ChannelsTab(ctrl: _ctrl),
                _MessagesTab(ctrl: _ctrl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH BAR
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final ChatController ctrl;
  const _SearchBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl.searchCtrl,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Rechercher: #Tech  #Musique  #Politique…',
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white30, size: 18),
        suffixIcon: Obx(() => ctrl.searchQuery.value.isNotEmpty
            ? IconButton(
                onPressed: ctrl.searchCtrl.clear,
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white38, size: 16))
            : const SizedBox.shrink()),
        filled: true,
        fillColor: Colors.white10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONGLET CANAUX
// ─────────────────────────────────────────────────────────────────────────────
class _ChannelsTab extends StatelessWidget {
  final ChatController ctrl;
  const _ChannelsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isChannelsLoading.value && ctrl.channels.isEmpty) {
        return Center(
            child: CircularProgressIndicator(color: GPTheme.primaryColor));
      }
      final list = ctrl.filteredChannels;
      if (list.isEmpty) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.search_off_rounded, size: 48, color: context.subtle),
            const SizedBox(height: 12),
            Text('Aucun canal trouvé',
                style: TextStyle(color: context.subtle, fontSize: 15)),
          ]),
        );
      }

      // Grouper: rejoints en premier
      final joined = list.where((c) => c.isJoined).toList();
      final others = list.where((c) => !c.isJoined).toList();

      return RefreshIndicator(
        color: GPTheme.primaryColor,
        onRefresh: ctrl.loadChannels,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (joined.isNotEmpty) ...[
              _SectionHeader(label: 'Mes canaux (${joined.length})'),
              ...joined.map((c) => _ChannelTile(
                    channel: c,
                    onTap: () => _openChannel(context, c),
                    onJoin: () => ctrl.joinChannel(c),
                    onLeave: () => _confirmLeave(context, c),
                  )),
            ],
            if (others.isNotEmpty) ...[
              _SectionHeader(label: 'Découvrir (${others.length})'),
              ...others.map((c) => _ChannelTile(
                    channel: c,
                    onTap: null,
                    onJoin: () => ctrl.joinChannel(c),
                    onLeave: null,
                  )),
            ],
          ],
        ),
      );
    });
  }

  void _openChannel(BuildContext context, ChatChannel channel) async {
    await ctrl.openChannel(channel);
    Get.to(() => ChatRoomView(channel: channel),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300));
  }

  Future<void> _confirmLeave(BuildContext context, ChatChannel channel) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitter ce canal ?'),
        content: Text('Vous ne recevrez plus les messages de "${channel.name}".'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Annuler')),
          TextButton(
              onPressed: () => Get.back(result: true),
              child: Text('Quitter', style: TextStyle(color: GPTheme.primaryColor))),
        ],
      ),
    );
    if (ok == true) ctrl.leaveChannel(channel);
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.subtle,
              letterSpacing: 0.8)),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final ChatChannel channel;
  final VoidCallback? onTap;
  final VoidCallback onJoin;
  final VoidCallback? onLeave;

  const _ChannelTile({
    required this.channel,
    required this.onTap,
    required this.onJoin,
    this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return InkWell(
      onTap: onTap,
      splashColor: GPTheme.primaryColor.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar canal
            Stack(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: isDark
                        ? GPTheme.primaryColor.withOpacity(0.15)
                        : GPTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    image: channel.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(channel.imageUrl!),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: channel.imageUrl == null
                      ? Center(
                          child: Text(
                            channel.name[0].toUpperCase(),
                            style: TextStyle(
                              color: GPTheme.primaryColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        )
                      : null,
                ),
                if (channel.isOnline)
                  Positioned(
                    bottom: 2, right: 2,
                    child: Container(
                      width: 11, height: 11,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.bg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(channel.name,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (channel.lastMessage != null)
                        Text(channel.lastMessage!.timeLabel,
                            style: TextStyle(
                                fontSize: 11, color: context.subtle)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Dernier message ou description
                  Text(
                    channel.lastMessage?.content ??
                        channel.description ?? '',
                    style: TextStyle(
                        fontSize: 13,
                        color: context.subtle,
                        height: 1.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Tags
                      ...channel.tags.take(2).map((t) => Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: GPTheme.primaryColor.withOpacity(
                                  isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('#$t',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: GPTheme.primaryColor,
                                    fontWeight: FontWeight.w700)),
                          )),
                      // Membres
                      Icon(Icons.people_outline_rounded,
                          size: 13, color: context.subtle),
                      const SizedBox(width: 3),
                      Text('${channel.membersCount}',
                          style: TextStyle(
                              fontSize: 11, color: context.subtle)),
                      const Spacer(),
                      // Badge unread
                      if (channel.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: GPTheme.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${channel.unreadCount}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ),
                      // Bouton rejoindre / quitter
                      const SizedBox(width: 8),
                      if (!channel.isJoined)
                        GestureDetector(
                          onTap: onJoin,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: GPTheme.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Rejoindre',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                        )
                      else if (onLeave != null)
                        GestureDetector(
                          onTap: onLeave,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: GPTheme.primaryColor.withOpacity(
                                  isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: GPTheme.primaryColor
                                      .withOpacity(0.3)),
                            ),
                            child: Text('Rejoint',
                                style: TextStyle(
                                    color: GPTheme.primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONGLET MESSAGES PRIVÉS
// ─────────────────────────────────────────────────────────────────────────────
class _MessagesTab extends StatelessWidget {
  final ChatController ctrl;
  const _MessagesTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isConvsLoading.value && ctrl.privateConversations.isEmpty) {
        return Center(
            child: CircularProgressIndicator(color: GPTheme.primaryColor));
      }
      final convs = ctrl.privateConversations;
      if (convs.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 56, color: context.subtle),
                const SizedBox(height: 16),
                Text('Aucune conversation',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.primary)),
                const SizedBox(height: 8),
                Text('Likez des profils dans Dating pour démarrer !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: context.subtle,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        height: 1.5)),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        color: GPTheme.primaryColor,
        onRefresh: ctrl.loadPrivateConversations,
        child: ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: convs.length,
          separatorBuilder: (_, __) => Divider(
              height: 1, indent: 76, color: context.divider),
          itemBuilder: (_, i) => _ConvTile(
            conv: convs[i],
            onTap: () async {
              await ctrl.openPrivateConversation(convs[i]);
              Get.to(() => ChatRoomView(privateConv: convs[i]),
                  transition: Transition.rightToLeft,
                  duration: const Duration(milliseconds: 300));
            },
          ),
        ),
      );
    });
  }
}

class _ConvTile extends StatelessWidget {
  final PrivateConversation conv;
  final VoidCallback onTap;
  const _ConvTile({required this.conv, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final hasUnread = conv.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      splashColor: GPTheme.primaryColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: isDark
                      ? GPTheme.primaryColor.withOpacity(0.15)
                      : GPTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: conv.otherUserAvatar != null
                      ? NetworkImage(conv.otherUserAvatar!)
                      : null,
                  child: conv.otherUserAvatar == null
                      ? Text(
                          conv.otherUserName.isNotEmpty
                              ? conv.otherUserName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              color: GPTheme.primaryColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 18))
                      : null,
                ),
                if (conv.otherIsOnline)
                  Positioned(
                    bottom: 1, right: 1,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.bg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.otherUserName,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: context.primary),
                        ),
                      ),
                      Text(
                        conv.lastMessage?.timeLabel ?? '',
                        style: TextStyle(
                            fontSize: 11,
                            color: hasUnread
                                ? GPTheme.primaryColor
                                : context.subtle,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: _LastMessagePreview(msg: conv.lastMessage),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                              color: GPTheme.primaryColor,
                              shape: BoxShape.circle),
                          child: Center(
                            child: Text('${conv.unreadCount}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastMessagePreview extends StatelessWidget {
  final ChatMessage? msg;
  const _LastMessagePreview({required this.msg});

  @override
  Widget build(BuildContext context) {
    if (msg == null) return const SizedBox.shrink();
    String preview;
    switch (msg!.type) {
      case MessageType.image:  preview = '📷 Photo';       break;
      case MessageType.audio:  preview = '🎤 Message vocal'; break;
      case MessageType.video:  preview = '🎬 Vidéo';       break;
      case MessageType.file:   preview = '📎 Fichier';     break;
      default:                 preview = msg!.content;
    }
    return Text(
      preview,
      style: TextStyle(fontSize: 13, color: context.subtle),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
