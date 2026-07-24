// lib/app/modules/social/views/chat_room_view.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:grand_public_v2/app/data/models/chat_models.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/social/controllers/chat_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _Tx on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF2F2F7);
  Color get appBarBg => isDark ? const Color(0xFF141414) : Colors.black;
  // Color get inputBg => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get bubbleMe => GPTheme.primaryColor;
  Color get bubbleOther => isDark ? const Color(0xFF2A2A2A) : Colors.white;
  Color get primary => Theme.of(this).textTheme.bodyLarge!.color!;
  Color get subtle => Theme.of(this).hintColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// FULLSCREEN IMAGE VIEWER
// ─────────────────────────────────────────────────────────────────────────────
class _FullscreenImageViewer extends StatelessWidget {
  final String url;
  const _FullscreenImageViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: url.startsWith('/')
              ? Image.file(File(url), fit: BoxFit.contain)
              : Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, prog) => prog == null
                      ? child
                      : const CircularProgressIndicator(color: Colors.white),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FULLSCREEN VIDEO PLAYER
// ─────────────────────────────────────────────────────────────────────────────
class _FullscreenVideoPlayer extends StatefulWidget {
  final String url;
  const _FullscreenVideoPlayer({required this.url});

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  late VideoPlayerController _vpc;
  bool _init = false;

  @override
  void initState() {
    super.initState();
    _vpc = widget.url.startsWith('/')
        ? VideoPlayerController.file(File(widget.url))
        : VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _vpc.initialize().then((_) {
      if (mounted) {
        setState(() => _init = true);
        _vpc.play();
      }
    });
  }

  @override
  void dispose() {
    _vpc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: _init
            ? GestureDetector(
                onTap: () => _vpc.value.isPlaying ? _vpc.pause() : _vpc.play(),
                child: AspectRatio(
                  aspectRatio: _vpc.value.aspectRatio,
                  child: VideoPlayer(_vpc),
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
      bottomNavigationBar: _init
          ? VideoProgressIndicator(
              _vpc,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: GPTheme.primaryColor,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white10,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT ROOM VIEW
// ─────────────────────────────────────────────────────────────────────────────
class ChatRoomView extends StatefulWidget {
  final ChatChannel? channel;
  final PrivateConversation? privateConv;
  const ChatRoomView({super.key, this.channel, this.privateConv})
    : assert(channel != null || privateConv != null);

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  final _ctrl = Get.find<ChatController>();
  final _scroll = ScrollController();
  bool _showAttach = false;

  bool get _isPrivate => widget.privateConv != null;
  String get _title =>
      widget.channel?.name ?? widget.privateConv?.otherUserName ?? '';

  @override
  void initState() {
    super.initState();
    _ctrl.onScrollToBottom = _scrollToBottom;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _ctrl.onScrollToBottom = null;
    _ctrl.closeRoom();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onSend() {
    if (_isPrivate) {
      _ctrl.sendPrivateMessage(widget.privateConv!.id);
    } else {
      _ctrl.sendMessage(widget.channel!.id);
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: _MessagesList(
              ctrl: _ctrl,
              scrollCtrl: _scroll,
              isPrivate: _isPrivate,
            ),
          ),
          if (_isPrivate) _TypingIndicator(ctrl: _ctrl),
          _ReplyPreview(ctrl: _ctrl),
          _PendingFilePreview(ctrl: _ctrl),
          _RecordingBar(ctrl: _ctrl),
          _InputBar(
            ctrl: _ctrl,
            onSend: _onSend,
            showAttach: _showAttach,
            onToggleAttach: () => setState(() => _showAttach = !_showAttach),
          ),
          if (_showAttach)
            _AttachMenu(
              ctrl: _ctrl,
              onDone: () => setState(() => _showAttach = false),
            ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final isOnline = widget.privateConv?.otherIsOnline ?? false;
    return AppBar(
      backgroundColor: context.appBarBg,
      foregroundColor: Colors.white,
      titleSpacing: 0,
      title: Row(
        children: [
          if (_isPrivate) ...[
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: GPTheme.primaryColor.withOpacity(0.2),
                  backgroundImage: widget.privateConv?.otherUserAvatar != null
                      ? NetworkImage(widget.privateConv!.otherUserAvatar!)
                      : null,
                  child: widget.privateConv?.otherUserAvatar == null
                      ? Text(
                          _title[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.appBarBg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
          ] else ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: GPTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                image: widget.channel?.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(widget.channel!.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.channel?.imageUrl == null
                  ? Center(
                      child: Text(
                        _title[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (activeUser.value.isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _isPrivate
                      ? (isOnline ? 'En ligne' : 'Hors ligne')
                      : '${widget.channel?.membersCount ?? 0} membres',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOnline
                        ? Colors.greenAccent.shade400
                        : Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Menu 3 points — actions réellement opérationnelles
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white60),
          color: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (_) => [
            if (!_isPrivate && widget.channel != null) ...[
              PopupMenuItem(
                value: 'media',
                child: _MenuItem(
                  icon: Icons.photo_library_rounded,
                  label: 'Médias partagés',
                ),
              ),
              PopupMenuItem(
                value: 'members',
                child: _MenuItem(icon: Icons.group_rounded, label: 'Membres'),
              ),
              PopupMenuItem(
                value: 'leave',
                child: _MenuItem(
                  icon: Icons.exit_to_app_rounded,
                  label: 'Quitter le canal',
                  color: Colors.red,
                ),
              ),
            ],
            if (_isPrivate) ...[
              PopupMenuItem(
                value: 'media',
                child: _MenuItem(
                  icon: Icons.photo_library_rounded,
                  label: 'Médias partagés',
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Obx(
                  () => _MenuItem(
                    icon: _ctrl.isBlocked.value
                        ? Icons.lock_open_rounded
                        : Icons.block_rounded,
                    label: _ctrl.isBlocked.value ? 'Débloquer' : 'Bloquer',
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'leave':
        if (widget.channel != null) {
          _confirmLeaveChannel(context);
        }
        break;
      case 'block':
        if (widget.privateConv != null) {
          final otherId = widget.privateConv!.otherUserId;
          if (_ctrl.isBlocked.value) {
            _ctrl.unblockUser(otherId);
          } else {
            _confirmBlockUser(context, otherId);
          }
        }
        break;
      case 'media':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _SharedMediaSheet(
            ctrl: _ctrl,
            channelId: widget.channel?.id,
            conversationId: widget.privateConv?.id,
          ),
        );
        break;
      case 'members':
        if (widget.channel != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _ChannelMembersSheet(
              ctrl: _ctrl,
              channelId: widget.channel!.id,
            ),
          );
        }
        break;
    }
  }

  Future<void> _confirmLeaveChannel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitter ce canal ?'),
        content: Text(
          'Vous ne recevrez plus les messages de "${widget.channel!.name}".',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'Quitter',
              style: TextStyle(color: GPTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _ctrl.leaveChannel(widget.channel!);
      Get.back();
    }
  }

  Future<void> _confirmBlockUser(BuildContext context, int userId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bloquer cet utilisateur ?'),
        content: const Text(
          'Vous ne recevrez plus de messages de cette personne.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Bloquer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) await _ctrl.blockUser(userId);
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MenuItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.primary;
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 14, color: c)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED MEDIA SHEET — câblé sur ctrl.loadSharedMedia + ctrl.sharedMedia
// ─────────────────────────────────────────────────────────────────────────────
class _SharedMediaSheet extends StatefulWidget {
  final ChatController ctrl;
  final int? channelId;
  final int? conversationId;
  const _SharedMediaSheet({
    required this.ctrl,
    this.channelId,
    this.conversationId,
  });

  @override
  State<_SharedMediaSheet> createState() => _SharedMediaSheetState();
}

class _SharedMediaSheetState extends State<_SharedMediaSheet> {
  @override
  void initState() {
    super.initState();
    widget.ctrl.loadSharedMedia(
      channelId: widget.channelId,
      conversationId: widget.conversationId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Médias partagés',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: context.primary,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (widget.ctrl.isMediaLoading.value) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: GPTheme.primaryColor,
                    ),
                  );
                }
                final media = widget.ctrl.sharedMedia;
                if (media.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.perm_media_outlined,
                          size: 48,
                          color: context.subtle,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun média partagé',
                          style: TextStyle(color: context.subtle),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: media.length,
                  itemBuilder: (_, i) {
                    final m = media[i];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: m.type == MessageType.image
                          ? Image.network(
                              m.mediaUrl ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.grey.shade300),
                            )
                          : Container(
                              color: Colors.grey.shade800,
                              child: Icon(
                                m.type == MessageType.video
                                    ? Icons.videocam_rounded
                                    : m.type == MessageType.audio
                                    ? Icons.mic_rounded
                                    : Icons.insert_drive_file_rounded,
                                color: Colors.white54,
                                size: 28,
                              ),
                            ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHANNEL MEMBERS SHEET — câblé sur ctrl.loadChannelMembers + ctrl.channelMembers
// ─────────────────────────────────────────────────────────────────────────────
class _ChannelMembersSheet extends StatefulWidget {
  final ChatController ctrl;
  final int channelId;
  const _ChannelMembersSheet({required this.ctrl, required this.channelId});

  @override
  State<_ChannelMembersSheet> createState() => _ChannelMembersSheetState();
}

class _ChannelMembersSheetState extends State<_ChannelMembersSheet> {
  @override
  void initState() {
    super.initState();
    widget.ctrl.loadChannelMembers(widget.channelId);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Obx(
              () => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Membres (${widget.ctrl.channelMembers.length})',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: context.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (widget.ctrl.isMembersLoading.value) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: GPTheme.primaryColor,
                    ),
                  );
                }
                final members = widget.ctrl.channelMembers;
                if (members.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucun membre',
                      style: TextStyle(color: context.subtle),
                    ),
                  );
                }
                return ListView.builder(
                  controller: scrollCtrl,
                  itemCount: members.length,
                  itemBuilder: (_, i) {
                    final m = members[i];
                    final isAdminMember =
                        (m['role']?.toString().toLowerCase() ?? '') ==
                            'admin' ||
                        (m['role']?.toString().toLowerCase() ?? '') ==
                            'super admin';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: GPTheme.primaryColor.withOpacity(0.15),
                        backgroundImage: m['avatar_url'] != null
                            ? NetworkImage(m['avatar_url'])
                            : null,
                        child: m['avatar_url'] == null
                            ? Text(
                                (m['name'] ?? '?')[0].toString().toUpperCase(),
                                style: TextStyle(
                                  color: GPTheme.primaryColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              m['name'] ?? '',
                              style: TextStyle(
                                color: context.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isAdminMember) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade600,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGES LIST
// ─────────────────────────────────────────────────────────────────────────────
class _MessagesList extends StatelessWidget {
  final ChatController ctrl;
  final ScrollController scrollCtrl;
  final bool isPrivate;
  const _MessagesList({
    required this.ctrl,
    required this.scrollCtrl,
    required this.isPrivate,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final msgs = isPrivate ? ctrl.privateMessages : ctrl.messages;
      if (ctrl.isMessagesLoading.value && msgs.isEmpty) {
        return Center(
          child: CircularProgressIndicator(color: GPTheme.primaryColor),
        );
      }
      if (msgs.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: context.subtle,
              ),
              const SizedBox(height: 12),
              Text(
                'Aucun message pour l\'instant',
                style: TextStyle(color: context.subtle, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                'Soyez le premier à écrire !',
                style: TextStyle(
                  color: context.subtle,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      }

      final groups = _groupByDate(msgs);
      return ListView.builder(
        controller: scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: groups.length,
        itemBuilder: (_, gi) {
          final group = groups[gi];
          return Column(
            children: [
              _DateSeparator(label: _dateLabel(group.date)),
              ...group.messages.asMap().entries.map((e) {
                final i = e.key;
                final msg = e.value;
                final prev = i > 0 ? group.messages[i - 1] : null;
                final showAvatar =
                    !isPrivate &&
                    !msg.isMe &&
                    (prev == null || prev.senderId != msg.senderId);
                final showName =
                    !isPrivate &&
                    !msg.isMe &&
                    (prev == null || prev.senderId != msg.senderId);
                return _MessageBubble(
                  message: msg,
                  isChannel: !isPrivate,
                  showAvatar: showAvatar,
                  showName: showName,
                  ctrl: ctrl,
                );
              }),
            ],
          );
        },
      );
    });
  }

  List<_MsgGroup> _groupByDate(List<ChatMessage> msgs) {
    final groups = <_MsgGroup>[];
    DateTime? lastDate;
    List<ChatMessage> current = [];
    for (final msg in msgs) {
      final d = DateTime(msg.sentAt.year, msg.sentAt.month, msg.sentAt.day);
      if (lastDate == null || d != lastDate) {
        if (current.isNotEmpty) {
          groups.add(_MsgGroup(date: lastDate!, messages: List.of(current)));
          current = [];
        }
        lastDate = d;
      }
      current.add(msg);
    }
    if (current.isNotEmpty && lastDate != null)
      groups.add(_MsgGroup(date: lastDate, messages: current));
    return groups;
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(d.year, d.month, d.day);
    if (date == today) return 'AUJOURD\'HUI';
    if (date == yesterday) return 'HIER';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _MsgGroup {
  final DateTime date;
  final List<ChatMessage> messages;
  const _MsgGroup({required this.date, required this.messages});
}

// ─────────────────────────────────────────────────────────────────────────────
// DATE SEPARATOR
// ─────────────────────────────────────────────────────────────────────────────
class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: context.isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: context.isDark ? Colors.white10 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: context.subtle,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: context.isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE BUBBLE — avec swipe reply, long-press menu
// ─────────────────────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isChannel;
  final bool showAvatar;
  final bool showName;
  final ChatController ctrl;
  const _MessageBubble({
    required this.message,
    required this.isChannel,
    required this.showAvatar,
    required this.showName,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    return Padding(
      padding: EdgeInsets.only(
        top: 2,
        bottom: 2,
        left: isMe ? 40 : 0,
        right: isMe ? 0 : 40,
      ),
      child: Dismissible(
        key: ValueKey('swipe_${message.id}'),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          ctrl.startReply(message);
          return false;
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 16),
          child: Icon(
            Icons.reply_rounded,
            color: GPTheme.primaryColor.withOpacity(0.6),
            size: 22,
          ),
        ),
        child: GestureDetector(
          onLongPress: () => _showContextMenu(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isMe && isChannel) ...[
                SizedBox(
                  width: 34,
                  child: showAvatar
                      ? CircleAvatar(
                          radius: 14,
                          backgroundColor: GPTheme.primaryColor.withOpacity(
                            0.2,
                          ),
                          backgroundImage: message.senderAvatar != null
                              ? NetworkImage(message.senderAvatar!)
                              : null,
                          child: message.senderAvatar == null
                              ? Text(
                                  message.senderName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: GPTheme.primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : null,
                        )
                      : null,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (showName && !isMe)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.senderName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: GPTheme.primaryColor,
                              ),
                            ),
                            if (message.isAdminSender) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade600,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.65,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? context.bubbleMe : context.bubbleOther,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(isMe ? 18 : 4),
                          topRight: Radius.circular(isMe ? 4 : 18),
                          bottomLeft: const Radius.circular(18),
                          bottomRight: const Radius.circular(18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.hasReply)
                            _ReplyQuote(message: message, isMe: isMe),
                          _BubbleContent(
                            message: message,
                            isMe: isMe,
                            ctrl: ctrl,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.timeLabel,
                          style: TextStyle(fontSize: 10, color: context.subtle),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 3),
                          _StatusIcon(status: message.status),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MessageContextMenu(message: message, ctrl: ctrl),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REPLY QUOTE — aperçu du message cité dans la bulle
// ─────────────────────────────────────────────────────────────────────────────
class _ReplyQuote extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _ReplyQuote({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final textColor = isMe ? Colors.white : context.primary;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withOpacity(0.15)
            : GPTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: GPTheme.primaryColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyToSenderName ?? '',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          _replyPreview(context, textColor),
        ],
      ),
    );
  }

  Widget _replyPreview(BuildContext context, Color textColor) {
    switch (message.replyToType) {
      case MessageType.image:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image, size: 14, color: textColor.withOpacity(0.7)),
            const SizedBox(width: 4),
            Text(
              "Photo",
              style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      case MessageType.audio:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic_rounded,
              size: 14,
              color: textColor.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              "Message vocal",
              style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      case MessageType.video:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam, size: 14, color: textColor.withOpacity(0.7)),
            const SizedBox(width: 4),
            Text(
              "Vidéo",
              style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_rounded,
              size: 14,
              color: textColor.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              "Fichier",
              style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.message, size: 14, color: textColor.withOpacity(0.7)),
            const SizedBox(width: 4),
            Text(
              message.replyToContent ?? '',
              style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTEXT MENU — long press
// ─────────────────────────────────────────────────────────────────────────────
class _MessageContextMenu extends StatelessWidget {
  final ChatMessage message;
  final ChatController ctrl;
  const _MessageContextMenu({required this.message, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _CtxItem(
            icon: Icons.reply_rounded,
            label: 'Répondre',
            onTap: () {
              Get.back();
              ctrl.startReply(message);
            },
          ),
          if (message.isMe)
            _CtxItem(
              icon: Icons.delete_rounded,
              label: 'Supprimer',
              color: Colors.red,
              onTap: () {
                Get.back();
                ctrl.deleteMessage(message);
              },
            ),
          if (message.type == MessageType.text)
            _CtxItem(
              icon: Icons.copy_rounded,
              label: 'Copier',
              onTap: () {
                Get.back();
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CtxItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _CtxItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.primary;
    return ListTile(
      leading: Icon(icon, color: c, size: 20),
      title: Text(
        label,
        style: TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS ICON
// ─────────────────────────────────────────────────────────────────────────────
class _StatusIcon extends StatelessWidget {
  final MessageStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: context.subtle,
          ),
        );
      case MessageStatus.failed:
        return const Icon(
          Icons.error_outline_rounded,
          size: 12,
          color: Colors.red,
        );
      case MessageStatus.read:
        return Icon(
          Icons.done_all_rounded,
          size: 13,
          color: GPTheme.primaryColor,
        );
      case MessageStatus.delivered:
        return Icon(Icons.done_all_rounded, size: 13, color: context.subtle);
      default:
        return Icon(Icons.check_rounded, size: 13, color: context.subtle);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUBBLE CONTENT
// ─────────────────────────────────────────────────────────────────────────────
class _BubbleContent extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final ChatController ctrl;
  const _BubbleContent({
    required this.message,
    required this.isMe,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return _ImageBubble(message: message, isMe: isMe);
      case MessageType.audio:
        return _AudioBubble(message: message, isMe: isMe, ctrl: ctrl);
      case MessageType.video:
        return _VideoBubble(message: message, isMe: isMe);
      case MessageType.file:
        return _FileBubble(message: message, isMe: isMe, ctrl: ctrl);
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            message.content,
            style: TextStyle(
              color: isMe ? Colors.white : context.primary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        );
    }
  }
}

// ── Image — cliquable pour fullscreen
class _ImageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _ImageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final local = message.localFilePath;
    final url = message.mediaUrl ?? message.content;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isMe ? 18 : 4),
      topRight: Radius.circular(isMe ? 4 : 18),
      bottomLeft: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
    );

    Widget img;
    if (local != null && local.isNotEmpty) {
      img = Image.file(
        File(local),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _broken(),
      );
    } else if (url.isNotEmpty) {
      img = Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, prog) => prog == null ? child : _loading(),
        errorBuilder: (_, __, ___) => _broken(),
      );
    } else {
      img = _broken();
    }

    return GestureDetector(
      onTap: () => Get.to(
        () => _FullscreenImageViewer(url: local ?? url),
        transition: Transition.fadeIn,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(width: 200, height: 200, child: img),
      ),
    );
  }

  Widget _broken() => Container(
    width: 200,
    height: 200,
    color: Colors.grey.shade300,
    child: const Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
  );
  Widget _loading() => Container(
    width: 200,
    height: 200,
    color: Colors.grey.shade200,
    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );
}

// ── Audio — progression complète
class _AudioBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final ChatController ctrl;
  const _AudioBubble({
    required this.message,
    required this.isMe,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isMe ? Colors.white : context.primary;
    return Obx(() {
      final isPlaying = ctrl.playingMessageId.value == message.id;
      final isThisPlay = isPlaying && ctrl.isAudioPlaying.value;
      final totalSecs = isPlaying && ctrl.audioDuration.value.inSeconds > 0
          ? ctrl.audioDuration.value.inSeconds
          : (message.audioDurationSec ?? 0);
      final posSecs = isPlaying ? ctrl.audioPosition.value.inSeconds : 0;
      final progress = totalSecs > 0
          ? (posSecs / totalSecs).clamp(0.0, 1.0)
          : 0.0;

      return GestureDetector(
        onTap: () => ctrl.toggleAudio(message),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white24
                      : GPTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isThisPlay ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: isMe ? Colors.white : GPTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      const waveWidth = 18 * 5.0;
                      ctrl.seekAudio(
                        message,
                        (details.localPosition.dx / waveWidth).clamp(0.0, 1.0),
                      );
                    },
                    child: Row(
                      children: List.generate(18, (i) {
                        final active = progress > 0 && (i / 18) <= progress;
                        final height = 4.0 + (i % 5) * 4.0;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 80),
                          width: 3,
                          height: isThisPlay
                              ? height *
                                    (0.7 +
                                        0.3 *
                                            ((i + posSecs) % 3 == 0 ? 1 : 0.5))
                              : height,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: active
                                ? (isMe ? Colors.white : GPTheme.primaryColor)
                                : (isMe
                                      ? Colors.white.withOpacity(0.35)
                                      : GPTheme.primaryColor.withOpacity(0.25)),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPlaying
                        ? '${_fmt(posSecs)} / ${_fmt(totalSecs)}'
                        : _fmt(totalSecs),
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  String _fmt(int secs) =>
      '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';
}

// ── Video — CORRIGÉ : génère une vraie miniature de la première frame
// au lieu d'un fond noir, cliquable pour fullscreen
class _VideoBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;
  const _VideoBubble({required this.message, required this.isMe});

  @override
  State<_VideoBubble> createState() => _VideoBubbleState();
}

class _VideoBubbleState extends State<_VideoBubble> {
  VideoPlayerController? _thumbCtrl;
  bool _ready = false;

  String get _url =>
      widget.message.localFilePath ?? widget.message.mediaUrl ?? '';

  @override
  void initState() {
    super.initState();
    _initThumbnail();
  }

  void _initThumbnail() {
    if (_url.isEmpty) return;
    try {
      _thumbCtrl = _url.startsWith('/')
          ? VideoPlayerController.file(File(_url))
          : VideoPlayerController.networkUrl(Uri.parse(_url));
      _thumbCtrl!
          .initialize()
          .then((_) {
            if (mounted) {
              // Se positionne sur la première frame pour l'aperçu
              _thumbCtrl!.seekTo(Duration.zero);
              setState(() => _ready = true);
            }
          })
          .catchError((_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _thumbCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: Radius.circular(widget.isMe ? 18 : 4),
      topRight: Radius.circular(widget.isMe ? 4 : 18),
      bottomLeft: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
    );
    return GestureDetector(
      onTap: _url.isNotEmpty
          ? () => Get.to(
              () => _FullscreenVideoPlayer(url: _url),
              transition: Transition.fadeIn,
            )
          : null,
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: 200,
          height: 150,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Vraie miniature de la vidéo (première frame) si dispo
              if (_ready && _thumbCtrl != null)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _thumbCtrl!.value.size.width,
                    height: _thumbCtrl!.value.size.height,
                    child: VideoPlayer(_thumbCtrl!),
                  ),
                )
              else
                Container(color: Colors.grey.shade800),
              // Voile sombre pour lisibilité de l'icône play
              Container(color: Colors.black.withOpacity(0.25)),
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              if (!_ready)
                const Positioned(
                  top: 8,
                  left: 8,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── File — download button
class _FileBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final ChatController ctrl;
  const _FileBubble({
    required this.message,
    required this.isMe,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isMe ? Colors.white : context.primary;
    return Obx(() {
      final isDownloading = ctrl.downloadingMessageId.value == message.id;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_rounded,
              color: isMe ? Colors.white70 : GPTheme.primaryColor,
              size: 28,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'Fichier',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (message.fileSizeBytes != null)
                    Text(
                      _fmtSize(message.fileSizeBytes!),
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (message.mediaUrl != null && !message.isPending)
              GestureDetector(
                onTap: isDownloading ? null : () => ctrl.downloadFile(message),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.white.withOpacity(0.2)
                        : GPTheme.primaryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: isDownloading
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isMe ? Colors.white : GPTheme.primaryColor,
                          ),
                        )
                      : Icon(
                          Icons.download_rounded,
                          size: 18,
                          color: isMe ? Colors.white : GPTheme.primaryColor,
                        ),
                ),
              ),
          ],
        ),
      );
    });
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPING INDICATOR
// ─────────────────────────────────────────────────────────────────────────────
class _TypingIndicator extends StatelessWidget {
  final ChatController ctrl;
  const _TypingIndicator({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!ctrl.otherIsTyping.value && ctrl.typingUsers.isEmpty)
        return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Row(
          children: [
            _DotsAnim(),
            const SizedBox(width: 8),
            Text(
              'est en train d\'écrire…',
              style: TextStyle(
                fontSize: 12,
                color: context.subtle,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _DotsAnim extends StatefulWidget {
  @override
  State<_DotsAnim> createState() => _DotsAnimState();
}

class _DotsAnimState extends State<_DotsAnim>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final offset = ((_anim.value * 3) - i).clamp(0.0, 1.0);
          final bounce = (offset < 0.5 ? offset : 1 - offset) * 2;
          return Transform.translate(
            offset: Offset(0, -4 * bounce),
            child: Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: GPTheme.primaryColor.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REPLY PREVIEW — barre au dessus de l'input
// ─────────────────────────────────────────────────────────────────────────────
class _ReplyPreview extends StatelessWidget {
  final ChatController ctrl;
  const _ReplyPreview({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final reply = ctrl.replyingTo.value;
      if (reply == null) return const SizedBox.shrink();
      return Container(
        color: context.isDark ? const Color(0xFF1C1C1C) : Colors.grey.shade50,
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 36,
              color: GPTheme.primaryColor,
              margin: const EdgeInsets.only(right: 10),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reply.senderName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: GPTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _preview(context, reply),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: ctrl.cancelReply,
              color: context.subtle,
            ),
          ],
        ),
      );
    });
  }

  Widget _preview(BuildContext context, ChatMessage msg) {
    switch (msg.type) {
      case MessageType.image:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image, size: 14, color: context.subtle),
            const SizedBox(width: 4),
            Text(
              "Photo",
              style: TextStyle(fontSize: 12, color: context.subtle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      case MessageType.audio:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic_rounded, size: 14, color: context.subtle),
            const SizedBox(width: 4),
            Text(
              "Message vocal",
              style: TextStyle(fontSize: 12, color: context.subtle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      case MessageType.video:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam, size: 14, color: context.subtle),
            const SizedBox(width: 4),
            Text(
              "Vidéo",
              style: TextStyle(fontSize: 12, color: context.subtle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_rounded,
              size: 14,
              color: context.subtle,
            ),
            const SizedBox(width: 4),
            Text(
              "Fichier",
              style: TextStyle(fontSize: 12, color: context.subtle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.message, size: 14, color: context.subtle),
            const SizedBox(width: 4),
            Text(
              msg.content,
              style: TextStyle(fontSize: 12, color: context.subtle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PENDING FILE PREVIEW
// ─────────────────────────────────────────────────────────────────────────────
class _PendingFilePreview extends StatelessWidget {
  final ChatController ctrl;
  const _PendingFilePreview({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final file = ctrl.pendingFile.value;
      if (file == null) return const SizedBox.shrink();
      return Container(
        color: context.isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            if (ctrl.pendingFileType.value == MessageType.image)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: GPTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  ctrl.pendingFileType.value == MessageType.video
                      ? Icons.videocam_rounded
                      : ctrl.pendingFileType.value == MessageType.audio
                      ? Icons.mic_rounded
                      : Icons.insert_drive_file_rounded,
                  color: GPTheme.primaryColor,
                  size: 28,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.path.split('/').last,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    ctrl.pendingFileType.value?.label ?? '',
                    style: TextStyle(fontSize: 12, color: GPTheme.primaryColor),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: ctrl.clearPendingFile,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: Colors.grey,
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECORDING BAR
// ─────────────────────────────────────────────────────────────────────────────
class _RecordingBar extends StatelessWidget {
  final ChatController ctrl;
  const _RecordingBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!ctrl.isRecording.value) return const SizedBox.shrink();
      final secs = ctrl.recordingDuration.value;
      final m = (secs ~/ 60).toString().padLeft(2, '0');
      final s = (secs % 60).toString().padLeft(2, '0');
      return Container(
        color: Colors.red.shade600,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _PulseDot(),
            const SizedBox(width: 10),
            Text(
              'Enregistrement $m:$s',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: ctrl.cancelRecording,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: ctrl.stopAndSendRecording,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.send, size: 16, color: Colors.red.shade600),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Opacity(
      opacity: 0.4 + _anim.value * 0.6,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// INPUT BAR — WhatsApp-style
// ─────────────────────────────────────────────────────────────────────────────
class _InputBar extends StatefulWidget {
  final ChatController ctrl;
  final VoidCallback onSend;
  final bool showAttach;
  final VoidCallback onToggleAttach;
  const _InputBar({
    required this.ctrl,
    required this.onSend,
    required this.showAttach,
    required this.onToggleAttach,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _isLongPressing = false;

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    return Container(
      color: context.isDark ? const Color(0xFF141414) : Colors.white,
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Obx(() {
        final isRec = ctrl.isRecording.value;
        final hasFile = ctrl.pendingFile.value != null;
        final hasText = ctrl.messageText.value.trim().isNotEmpty;
        final hasContent = hasText || hasFile;

        if (isRec) return const SizedBox.shrink();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: widget.onToggleAttach,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.showAttach
                      ? GPTheme.primaryColor
                      : (context.isDark
                            ? Colors.white10
                            : Colors.grey.shade100),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.showAttach ? Icons.close_rounded : Icons.add_rounded,
                  color: widget.showAttach ? Colors.white : context.subtle,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.isDark
                        ? Colors.white10
                        : Colors.grey.shade200,
                  ),
                ),
                child: TextField(
                  controller: ctrl.messageCtrl,
                  style: TextStyle(fontSize: 14),
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: hasFile ? 'Ajouter une légende…' : 'Message…',
                    hintStyle: TextStyle(fontSize: 14),
                    border: InputBorder.none,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: hasContent
                  ? GestureDetector(
                      key: const ValueKey('send'),
                      onTap: widget.onSend,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: GPTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    )
                  : GestureDetector(
                      key: const ValueKey('mic'),
                      onLongPressStart: (_) async {
                        setState(() => _isLongPressing = true);
                        await ctrl.startRecording();
                      },
                      onLongPressEnd: (_) async {
                        if (!_isLongPressing) return;
                        setState(() => _isLongPressing = false);
                        await ctrl.stopAndSendRecording();
                      },
                      onLongPressCancel: () {
                        setState(() => _isLongPressing = false);
                        ctrl.cancelRecording();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _isLongPressing
                              ? Colors.red.shade600
                              : (context.isDark
                                    ? Colors.white10
                                    : Colors.grey.shade100),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mic_rounded,
                          color: _isLongPressing
                              ? Colors.white
                              : context.subtle,
                          size: 22,
                        ),
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ATTACH MENU
// ─────────────────────────────────────────────────────────────────────────────
class _AttachMenu extends StatelessWidget {
  final ChatController ctrl;
  final VoidCallback onDone;
  const _AttachMenu({required this.ctrl, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _AttachItem(
            icon: Icons.image_rounded,
            label: 'Galerie',
            color: Colors.purple,
            onTap: () async {
              await ctrl.pickImage();
              onDone();
            },
          ),
          _AttachItem(
            icon: Icons.camera_alt_rounded,
            label: 'Caméra',
            color: Colors.blue,
            onTap: () async {
              await ctrl.pickImage(fromCamera: true);
              onDone();
            },
          ),
          _AttachItem(
            icon: Icons.videocam_rounded,
            label: 'Vidéo',
            color: Colors.red,
            onTap: () async {
              await ctrl.pickVideo();
              onDone();
            },
          ),
          _AttachItem(
            icon: Icons.insert_drive_file_rounded,
            label: 'Fichier',
            color: Colors.green,
            onTap: () async {
              await ctrl.pickFile();
              onDone();
            },
          ),
        ],
      ),
    );
  }
}

class _AttachItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AttachItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: context.subtle,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOAST HELPER (import guard)
// ─────────────────────────────────────────────────────────────────────────────
// class ToastHelper {
//   static Future<void> showToast(
//     String msg, {
//     Color? backgroundColor,
//     Color? textColor,
//   }) async {
//     Get.snackbar(
//       '',
//       msg,
//       backgroundColor: backgroundColor ?? Colors.black87,
//       colorText: textColor ?? Colors.white,
//       snackPosition: SnackPosition.BOTTOM,
//       margin: const EdgeInsets.all(12),
//       duration: const Duration(seconds: 3),
//     );
//   }
// }
