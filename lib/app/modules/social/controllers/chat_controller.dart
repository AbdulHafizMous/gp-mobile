// lib/app/modules/social/controllers/chat_controller.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/models/chat_models.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

class ChatController extends GetxController {
  // ── State ──────────────────────────────────────────────────────────────────
  final channels = <ChatChannel>[].obs;
  final myChannels = <ChatChannel>[].obs;       // canaux rejoints
  final privateConversations = <PrivateConversation>[].obs;
  final isChannelsLoading = false.obs;
  final isMessagesLoading = false.obs;
  final isSending = false.obs;

  // Canal actif
  final activeChannel = Rxn<ChatChannel>();
  final messages = <ChatMessage>[].obs;

  // Conversation privée active
  final activeConversation = Rxn<PrivateConversation>();
  final privateMessages = <ChatMessage>[].obs;

  // Onglet actif dans Social (0=Chat, 1=Dating)
  final socialTab = 0.obs;

  // Texte du message
  final messageCtrl = TextEditingController();
  final searchCtrl = TextEditingController();
  final searchQuery = ''.obs;

  // Mon userId (depuis storage)
  int get myUserId => GetStorage().read<int>('userId') ?? 0;
  String get myName => GetStorage().read<String>('username') ?? 'Moi';

  // ─────────────────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    loadChannels();
    loadPrivateConversations();
    searchCtrl.addListener(() => searchQuery.value = searchCtrl.text);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CHANNELS
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadChannels() async {
    isChannelsLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 600));
        final all = _mockChannels();
        channels.value = all;
        myChannels.value = all.where((c) => c.isJoined).toList();
        return;
      }
      final r = await RequestService().get('/social/channels');
      final list = r.data['data'] as List<dynamic>;
      final all = list
          .map((e) => ChatChannel.fromJson(e as Map<String, dynamic>))
          .toList();
      channels.value = all;
      myChannels.value = all.where((c) => c.isJoined).toList();
    } on DioException catch (e) {
      _handleDioError(e);
    } finally {
      isChannelsLoading.value = false;
    }
  }

  List<ChatChannel> get filteredChannels {
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) return channels;
    return channels.where((c) =>
        c.name.toLowerCase().contains(q) ||
        (c.description?.toLowerCase().contains(q) ?? false) ||
        c.tags.any((t) => t.toLowerCase().contains(q))).toList();
  }

  Future<void> joinChannel(ChatChannel channel) async {
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
        final idx = channels.indexWhere((c) => c.id == channel.id);
        if (idx != -1) {
          channels[idx] = channels[idx].copyWith(isJoined: true);
          if (!myChannels.any((c) => c.id == channel.id)) {
            myChannels.add(channels[idx]);
          }
        }
        await ToastHelper.showToast(
          'Vous avez rejoint ${channel.name}',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        return;
      }
      await RequestService().post('/social/channels/${channel.id}/join');
      await loadChannels();
      await ToastHelper.showToast(
        'Vous avez rejoint ${channel.name}',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MESSAGES CANAL
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> openChannel(ChatChannel channel) async {
    activeChannel.value = channel;
    messages.clear();
    await loadChannelMessages(channel.id);
  }

  Future<void> loadChannelMessages(int channelId) async {
    isMessagesLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 500));
        messages.value = _mockMessages(channelId);
        return;
      }
      final r = await RequestService().get('/social/channels/$channelId/messages');
      final list = r.data['data'] as List<dynamic>;
      messages.value = list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } finally {
      isMessagesLoading.value = false;
    }
  }

  Future<void> sendMessage(int channelId) async {
    final text = messageCtrl.text.trim();
    if (text.isEmpty) return;

    // Optimistic
    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      channelId: channelId,
      senderId: myUserId,
      senderName: myName,
      content: text,
      sentAt: DateTime.now(),
      isMe: true,
    );
    messages.add(msg);
    messageCtrl.clear();

    if (useMock) return;
    try {
      await RequestService().post(
        '/social/channels/$channelId/messages',
        data: {'content': text},
      );
    } on DioException catch (e) {
      messages.removeLast();
      _handleDioError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONVERSATIONS PRIVÉES (dating DMs)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadPrivateConversations() async {
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 700));
        privateConversations.value = _mockPrivateConversations();
        return;
      }
      final r = await RequestService().get('/social/conversations');
      final list = r.data['data'] as List<dynamic>;
      privateConversations.value = list
          .map((e) => PrivateConversation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('loadPrivateConversations error: $e');
    }
  }

  Future<void> openPrivateConversation(PrivateConversation conv) async {
    activeConversation.value = conv;
    privateMessages.clear();
    await loadPrivateMessages(conv.id);
  }

  Future<void> loadPrivateMessages(int convId) async {
    isMessagesLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 500));
        privateMessages.value = _mockPrivateMessages(convId);
        return;
      }
      final r = await RequestService()
          .get('/social/conversations/$convId/messages');
      final list = r.data['data'] as List<dynamic>;
      privateMessages.value = list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } finally {
      isMessagesLoading.value = false;
    }
  }

  Future<void> sendPrivateMessage(int convId) async {
    final text = messageCtrl.text.trim();
    if (text.isEmpty) return;

    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      channelId: convId,
      senderId: myUserId,
      senderName: myName,
      content: text,
      sentAt: DateTime.now(),
      isMe: true,
    );
    privateMessages.add(msg);
    messageCtrl.clear();

    if (useMock) return;
    try {
      await RequestService().post(
        '/social/conversations/$convId/messages',
        data: {'content': text},
      );
    } on DioException catch (e) {
      privateMessages.removeLast();
      _handleDioError(e);
    }
  }

  /// Démarre une conversation privée avec un utilisateur (depuis dating)
  Future<int?> startConversationWithUser(int userId) async {
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 500));
        return 999; // mock conv id
      }
      final r = await RequestService().post(
        '/social/conversations',
        data: {'user_id': userId},
      );
      return r.data['data']['id'];
    } catch (e) {
      debugPrint('startConversation error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOCKS
  // ─────────────────────────────────────────────────────────────────────────
  List<ChatChannel> _mockChannels() {
    final topics = [
      {'name': "L'avenir des emplois face à l'IA", 'tag': 'Tech', 'count': 80},
      {'name': 'Musique béninoise : tendances 2025', 'tag': 'Musique', 'count': 145},
      {'name': 'Politique africaine et jeunesse', 'tag': 'Politique', 'count': 63},
      {'name': 'Entrepreneuriat au Bénin', 'tag': 'Business', 'count': 212},
      {'name': 'Culture & Art africain', 'tag': 'Culture', 'count': 98},
      {'name': 'Sport & Football local', 'tag': 'Sport', 'count': 77},
      {'name': 'Mode & Style africain', 'tag': 'Mode', 'count': 54},
      {'name': 'Tech & Innovation', 'tag': 'Tech', 'count': 130},
    ];
    return List.generate(topics.length, (i) {
      final t = topics[i];
      return ChatChannel(
        id: i + 1,
        name: t['name'] as String,
        description: 'Rejoignez un ou plusieurs chats et chattez avec des ami(e)s',
        membersCount: t['count'] as int,
        isJoined: i < 2,
        isOnline: i % 2 == 0,
        tags: [t['tag'] as String],
        lastMessage: i < 2
            ? ChatMessage(
                id: i * 10,
                channelId: i + 1,
                senderId: i + 10,
                senderName: 'Sam Jean',
                content: "L'expérience de la dame qui vend au marché...",
                sentAt: DateTime.now().subtract(const Duration(minutes: 5)),
              )
            : null,
        unreadCount: i == 1 ? 3 : 0,
      );
    });
  }

  List<ChatMessage> _mockMessages(int channelId) {
    final names = ['Kadi dld', 'Rickys Daf', 'Evelyne Dks', 'Rachel Bryan', 'Evelyne Dks', 'Kadi dld'];
    final avatars = List.generate(6, (i) =>
        'https://randomuser.me/api/portraits/${i % 2 == 0 ? 'women' : 'men'}/${i + 10}.jpg');
    const content = "L'intelligence artificielle redéfinit le marché du travail.";

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final today = DateTime.now();

    return [
      // Hier
      ...List.generate(4, (i) => ChatMessage(
        id: i + 1,
        channelId: channelId,
        senderId: i + 1,
        senderName: names[i % names.length],
        senderAvatar: avatars[i % avatars.length],
        content: content,
        sentAt: yesterday.subtract(Duration(minutes: i * 10)),
        isMe: i == 3, // Rachel Bryan = moi
      )),
      // Aujourd'hui
      ChatMessage(
        id: 100,
        channelId: channelId,
        senderId: 1,
        senderName: names[0],
        senderAvatar: avatars[0],
        content: content,
        sentAt: today.subtract(const Duration(minutes: 15)),
        isMe: false,
      ),
    ];
  }

  List<PrivateConversation> _mockPrivateConversations() {
    final names = [
      'Sam Jean', 'Aicha Bello', 'Kofi Mensah', 'Fatou Diallo',
      'Serge B.', 'Rachelle D.', 'Hans Dossou', 'Marie T.',
    ];
    return List.generate(names.length, (i) => PrivateConversation(
      id: i + 1,
      otherUserId: i + 100,
      otherUserName: names[i],
      otherUserAvatar:
          'https://randomuser.me/api/portraits/${i % 2 == 0 ? 'women' : 'men'}/${i + 20}.jpg',
      otherIsOnline: i % 3 == 0,
      lastMessage: ChatMessage(
        id: i * 10,
        channelId: i + 1,
        senderId: i + 100,
        senderName: names[i],
        content: "L'expérience de la dame qui vend au marché...",
        sentAt: DateTime.now().subtract(Duration(minutes: i * 5 + 5)),
      ),
      unreadCount: i % 4 == 0 ? 2 : 0,
    ));
  }

  List<ChatMessage> _mockPrivateMessages(int convId) {
    final otherName = privateConversations
        .firstWhere((c) => c.id == convId,
            orElse: () => const PrivateConversation(
                id: 0, otherUserId: 0, otherUserName: 'Utilisateur'))
        .otherUserName;
    const content = "L'intelligence artificielle redéfinit le marché du travail.";
    return List.generate(8, (i) => ChatMessage(
      id: i + 1,
      channelId: convId,
      senderId: i % 2 == 0 ? 0 : 1,
      senderName: i % 2 == 0 ? otherName : myName,
      content: content,
      sentAt: DateTime.now().subtract(Duration(minutes: (8 - i) * 5)),
      isMe: i % 2 != 0,
    ));
  }

  void _handleDioError(DioException e) {
    final msg = e.response != null
        ? 'Erreur ${e.response?.statusCode}'
        : e.message ?? 'Erreur réseau';
    ToastHelper.showToast(msg,
        backgroundColor: Colors.red, textColor: Colors.white);
  }

  @override
  void onClose() {
    messageCtrl.dispose();
    searchCtrl.dispose();
    super.onClose();
  }
}