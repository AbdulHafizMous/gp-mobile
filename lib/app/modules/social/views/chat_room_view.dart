// lib/app/modules/social/views/chat_room_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/chat_models.dart';
import 'package:grand_public_v2/app/modules/social/controllers/chat_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5);
  Color get primaryText =>
      Theme.of(this).textTheme.bodyLarge?.color ??
      (isDark ? Colors.white : Colors.black87);
  Color get subtleText => Theme.of(this).hintColor;
  Color get inputBg => isDark ? const Color(0xFF1E1E1E) : Colors.white;
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT ROOM VIEW — canal ou conversation privée
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
  final ChatController _ctrl = Get.find<ChatController>();
  final ScrollController _scrollCtrl = ScrollController();

  bool get _isPrivate => widget.privateConv != null;
  String get _title =>
      widget.channel?.name ?? widget.privateConv?.otherUserName ?? '';

  // Regrouper les messages par date
  List<_MessageGroup> _groupMessages(List<ChatMessage> msgs) {
    if (msgs.isEmpty) return [];
    final groups = <_MessageGroup>[];
    DateTime? lastDate;
    List<ChatMessage> current = [];

    for (final msg in msgs) {
      final d = DateTime(msg.sentAt.year, msg.sentAt.month, msg.sentAt.day);
      if (lastDate == null || d != lastDate) {
        if (current.isNotEmpty) {
          groups.add(_MessageGroup(date: lastDate!, messages: current));
          current = [];
        }
        lastDate = d;
      }
      current.add(msg);
    }
    if (current.isNotEmpty && lastDate != null) {
      groups.add(_MessageGroup(date: lastDate, messages: current));
    }
    return groups;
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(d.year, d.month, d.day);
    if (date == today) return 'AUJOURD\'HUI';
    if (date == yesterday) return 'HIER';
    return '${d.day}/${d.month}/${d.year}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor:
            context.isDark ? const Color(0xFF1A1A1A) : Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: Get.back,
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: GPTheme.primaryColor,
              backgroundImage: widget.privateConv?.otherUserAvatar != null
                  ? NetworkImage(widget.privateConv!.otherUserAvatar!)
                  : null,
              child: widget.privateConv?.otherUserAvatar == null
                  ? Text(
                      _title[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.channel != null)
                    Text(
                      '${widget.channel!.membersCount} membres',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white60),
                    ),
                  if (widget.privateConv?.otherIsOnline == true)
                    const Text(
                      'En ligne',
                      style: TextStyle(fontSize: 11, color: Colors.green),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!_isPrivate)
            IconButton(
              icon: const Icon(Icons.people_outline_rounded,
                  color: Colors.white),
              onPressed: () {},
            ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Bannière "Vous avez rejoint ce chat" ─────────────────────────
          if (!_isPrivate)
            Container(
              color: context.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'Vous avez rejoint ce chat',
                  style: TextStyle(
                      color: context.subtleText,
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ),

          // ── Messages ─────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              final msgs =
                  _isPrivate ? _ctrl.privateMessages : _ctrl.messages;

              if (_ctrl.isMessagesLoading.value) {
                return Center(
                  child:
                      CircularProgressIndicator(color: GPTheme.primaryColor),
                );
              }

              if (msgs.isEmpty) {
                return Center(
                  child: Text(
                    'Aucun message pour l\'instant.\nSoyez le premier !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: context.subtleText, fontSize: 14),
                  ),
                );
              }

              final groups = _groupMessages(msgs.toList());
              _scrollToBottom();

              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                itemCount: groups.length,
                itemBuilder: (_, gi) {
                  final group = groups[gi];
                  return Column(
                    children: [
                      // Date label
                      _DateSeparator(label: _dateLabel(group.date)),
                      ...group.messages.map((msg) => _MessageBubble(
                            message: msg,
                            isChannel: !_isPrivate,
                          )),
                    ],
                  );
                },
              );
            }),
          ),

          // ── Input ─────────────────────────────────────────────────────────
          _MessageInput(
            ctrl: _ctrl,
            onSend: _isPrivate
                ? () => _ctrl
                    .sendPrivateMessage(widget.privateConv!.id)
                    .then((_) => _scrollToBottom())
                : () => _ctrl
                    .sendMessage(widget.channel!.id)
                    .then((_) => _scrollToBottom()),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isChannel; // canal = affiche le nom + avatar de l'auteur

  const _MessageBubble({required this.message, this.isChannel = false});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

    if (isMe) {
      // Message de MOI → bulle rouge à droite
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isChannel)
                  Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 2),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                          fontSize: 11,
                          color: GPTheme.primaryColor,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: GPTheme.primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, height: 1.4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.timeLabel,
                  style: TextStyle(fontSize: 10, color: context.subtleText),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Message des AUTRES → bulle sombre/grise à gauche
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: GPTheme.primaryColor.withValues(alpha: 0.2),
            backgroundImage: message.senderAvatar != null
                ? NetworkImage(message.senderAvatar!)
                : null,
            child: message.senderAvatar == null
                ? Text(
                    message.senderName[0].toUpperCase(),
                    style: TextStyle(
                      color: GPTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom de l'expéditeur (toujours visible dans canal)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 3),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.primaryText,
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.62,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                      color: context.primaryText,
                      fontSize: 14,
                      height: 1.4),
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  message.timeLabel,
                  style:
                      TextStyle(fontSize: 10, color: context.subtleText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: context.isDark
                  ? Colors.white12
                  : Colors.grey.shade300,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: context.subtleText,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: context.isDark
                  ? Colors.white12
                  : Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE INPUT
// ─────────────────────────────────────────────────────────────────────────────
class _MessageInput extends StatelessWidget {
  final ChatController ctrl;
  final VoidCallback onSend;

  const _MessageInput({required this.ctrl, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.isDark ? const Color(0xFF1A1A1A) : Colors.white,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.inputBg,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: context.isDark
                      ? Colors.white12
                      : Colors.grey.shade300,
                ),
              ),
              child: TextField(
                controller: ctrl.messageCtrl,
                style: TextStyle(color: context.primaryText, fontSize: 14),
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(
                      color: context.subtleText, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Bouton micro (futur audio)
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.isDark
                    ? Colors.white12
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mic_rounded,
                color: context.subtleText,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Bouton envoyer
          GestureDetector(
            onTap: onSend,
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
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER
// ─────────────────────────────────────────────────────────────────────────────
class _MessageGroup {
  final DateTime date;
  final List<ChatMessage> messages;
  const _MessageGroup({required this.date, required this.messages});
}