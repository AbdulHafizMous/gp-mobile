// lib/app/modules/social/controllers/chat_controller.dart

import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/models/chat_models.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:image_picker/image_picker.dart';

class ChatController extends GetxController {
  // ── State ──────────────────────────────────────────────────────────────────
  final channels             = <ChatChannel>[].obs;
  final privateConversations = <PrivateConversation>[].obs;
  final isChannelsLoading    = false.obs;
  final isConvsLoading       = false.obs;
  final isMessagesLoading    = false.obs;
  final isSending            = false.obs;

  // Canal / conversation actifs
  final activeChannel      = Rxn<ChatChannel>();
  final messages           = <ChatMessage>[].obs;
  final activeConversation = Rxn<PrivateConversation>();
  final privateMessages    = <ChatMessage>[].obs;

  // Typing indicators
  final typingUsers        = <String>{}.obs;   // noms des gens qui tapent (canal)
  final otherIsTyping      = false.obs;         // pour privé
  Timer? _typingDebounce;
  Timer? _clearTypingTimer;
  bool   _iAmTyping = false;

  // Tab social principal (0=Chat, 1=Dating)
  final socialTab  = 0.obs;
  // Tab interne Chat (0=Canaux, 1=Messages privés)
  final chatTab    = 0.obs;

  // Input
  final messageCtrl = TextEditingController();
  final searchCtrl  = TextEditingController();
  final searchQuery = ''.obs;

  // Polling
  Timer? _pollingTimer;
  static const _pollInterval = Duration(seconds: 4);

  // Scroll to bottom callback (set by view)
  VoidCallback? onScrollToBottom;

  // Pièce jointe en attente
  final pendingFile     = Rxn<File>();
  final pendingFileType = Rxn<MessageType>();
  final isUploadingFile = false.obs;
  final uploadProgress  = 0.0.obs;

  // Image picker
  final _picker = ImagePicker();

  // Auth
  int get myUserId => GetStorage().read<int>('userId') ?? 0;
  String get myName => GetStorage().read<String>('username') ?? 'Moi';

  // ─────────────────────────────────────────────────────────────────────────
  // INIT / CLOSE
  // ─────────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    loadChannels();
    loadPrivateConversations();
    searchCtrl.addListener(() => searchQuery.value = searchCtrl.text);
    messageCtrl.addListener(_onTyping);
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    _typingDebounce?.cancel();
    _clearTypingTimer?.cancel();
    messageCtrl.dispose();
    searchCtrl.dispose();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TYPING INDICATOR — émetteur local
  // ─────────────────────────────────────────────────────────────────────────
  void _onTyping() {
    if (messageCtrl.text.isEmpty) {
      _stopTyping();
      return;
    }
    if (!_iAmTyping) {
      _iAmTyping = true;
      _sendTypingEvent(true);
    }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), _stopTyping);
  }

  void _stopTyping() {
    if (_iAmTyping) {
      _iAmTyping = false;
      _sendTypingEvent(false);
    }
  }

  void _sendTypingEvent(bool isTyping) {
    // Pusher / WebSocket ici — pour l'instant on utilise le polling
    // On met juste à jour le state local (le vrai typing arrive via poll)
  }

  // Simule la réception d'un typing depuis un autre user (polling-based)
  void _processTypingFromPoll(List<ChatMessage> freshMessages) {
    // Si le dernier message date de moins de 5 sec et n'est pas de moi → typing
    if (freshMessages.isNotEmpty) {
      final last = freshMessages.last;
      if (!last.isMe &&
          DateTime.now().difference(last.sentAt).inSeconds < 5) {
        otherIsTyping.value = false; // message reçu → arrête le typing
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // POLLING — rafraîchit les messages actifs toutes les 4s
  // ─────────────────────────────────────────────────────────────────────────
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollInterval, (_) => _pollMessages());
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollMessages() async {
    if (useMock) return;
    try {
      if (activeChannel.value != null) {
        final r = await RequestService()
            .get('/social/channels/${activeChannel.value!.id}/messages');
        final list = r.data['data'] as List<dynamic>;
        final fresh = list
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        _mergeMessages(messages, fresh);
        _processTypingFromPoll(fresh);
        onScrollToBottom?.call();
      } else if (activeConversation.value != null) {
        final r = await RequestService()
            .get('/social/conversations/${activeConversation.value!.id}/messages');
        final list = r.data['data'] as List<dynamic>;
        final fresh = list
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        _mergeMessages(privateMessages, fresh);
        onScrollToBottom?.call();
      }
    } catch (_) {}
  }

  /// Fusionne sans duplication ni suppression des messages optimistes pending
  void _mergeMessages(RxList<ChatMessage> target, List<ChatMessage> fresh) {
    final freshIds = fresh.map((m) => m.id).toSet();
    // Garde les messages pending non encore confirmés
    final pendingMsgs = target.where((m) => m.isPending).toList();
    target.assignAll(fresh);
    // Ré-ajoute les pendants non présents dans fresh
    for (final p in pendingMsgs) {
      if (!freshIds.contains(p.id)) target.add(p);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CHANNELS
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadChannels() async {
    isChannelsLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 600));
        channels.value = _mockChannels();
        return;
      }
      final r = await RequestService().get('/social/channels');
      final list = r.data['data'] as List<dynamic>;
      channels.value = list
          .map((e) => ChatChannel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleDioError(e);
    } finally {
      isChannelsLoading.value = false;
    }
  }

  List<ChatChannel> get filteredChannels {
    final q = searchQuery.value.toLowerCase();
    final joined = channels.where((c) => c.isJoined).toList();
    final others = channels.where((c) => !c.isJoined).toList();
    if (q.isEmpty) return [...joined, ...others];
    bool match(ChatChannel c) =>
        c.name.toLowerCase().contains(q) ||
        (c.description?.toLowerCase().contains(q) ?? false) ||
        c.tags.any((t) => t.toLowerCase().contains(q));
    return [...joined.where(match), ...others.where(match)];
  }

  Future<void> joinChannel(ChatChannel channel) async {
    try {
      if (useMock) {
        final idx = channels.indexWhere((c) => c.id == channel.id);
        if (idx != -1) channels[idx] = channels[idx].copyWith(isJoined: true);
        await ToastHelper.showToast('Vous avez rejoint ${channel.name}',
            backgroundColor: Colors.green, textColor: Colors.white);
        return;
      }
      await RequestService().post('/social/channels/${channel.id}/join');
      await loadChannels();
      await ToastHelper.showToast('Vous avez rejoint ${channel.name}',
          backgroundColor: Colors.green, textColor: Colors.white);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<void> leaveChannel(ChatChannel channel) async {
    try {
      if (!useMock) {
        await RequestService().post('/social/channels/${channel.id}/leave');
      }
      final idx = channels.indexWhere((c) => c.id == channel.id);
      if (idx != -1) channels[idx] = channels[idx].copyWith(isJoined: false);
      await loadChannels();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MESSAGES CANAL
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> openChannel(ChatChannel channel) async {
    activeChannel.value = channel;
    activeConversation.value = null;
    messages.clear();
    _stopPolling();
    await _loadChannelMessages(channel.id);
    _startPolling();
  }

  void closeRoom() {
    _stopPolling();
    _stopTyping();
    activeChannel.value = null;
    activeConversation.value = null;
    messages.clear();
    privateMessages.clear();
  }

  Future<void> _loadChannelMessages(int channelId) async {
    isMessagesLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
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
    final file = pendingFile.value;

    if (text.isEmpty && file == null) return;
    _stopTyping();

    // Optimistic
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimistic = ChatMessage(
      id: tempId,
      channelId: channelId,
      senderId: myUserId,
      senderName: myName,
      content: text.isNotEmpty ? text : pendingFileType.value?.label ?? '',
      sentAt: DateTime.now(),
      isMe: true,
      type: pendingFileType.value ?? MessageType.text,
      status: MessageStatus.sending,
      isPending: true,
    );
    messages.add(optimistic);
    messageCtrl.clear();
    final capturedFile = file;
    final capturedType = pendingFileType.value;
    pendingFile.value = null;
    pendingFileType.value = null;
    onScrollToBottom?.call();

    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      final idx = messages.indexWhere((m) => m.id == tempId);
      if (idx != -1) messages[idx] = messages[idx].copyWith(status: MessageStatus.sent, isPending: false);
      return;
    }

    try {
      FormData data;
      if (capturedFile != null) {
        data = FormData.fromMap({
          'content': text,
          'type': capturedType?.name ?? 'text',
          'file': await MultipartFile.fromFile(capturedFile.path,
              filename: capturedFile.path.split('/').last),
        });
      } else {
        data = FormData.fromMap({'content': text, 'type': 'text'});
      }
      await RequestService().post('/social/channels/$channelId/messages', data: data);
      final idx = messages.indexWhere((m) => m.id == tempId);
      if (idx != -1) messages[idx] = messages[idx].copyWith(status: MessageStatus.sent, isPending: false);
    } on DioException catch (e) {
      final idx = messages.indexWhere((m) => m.id == tempId);
      if (idx != -1) messages[idx] = messages[idx].copyWith(status: MessageStatus.failed, isPending: false);
      _handleDioError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONVERSATIONS PRIVÉES
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadPrivateConversations() async {
    isConvsLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 500));
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
    } finally {
      isConvsLoading.value = false;
    }
  }

  Future<void> openPrivateConversation(PrivateConversation conv) async {
    activeConversation.value = conv;
    activeChannel.value = null;
    privateMessages.clear();
    _stopPolling();
    isMessagesLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
        privateMessages.value = _mockPrivateMessages(conv.id);
      } else {
        final r = await RequestService()
            .get('/social/conversations/${conv.id}/messages');
        final list = r.data['data'] as List<dynamic>;
        privateMessages.value = list
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } finally {
      isMessagesLoading.value = false;
    }
    _startPolling();
  }

  Future<void> sendPrivateMessage(int convId) async {
    final text = messageCtrl.text.trim();
    final file = pendingFile.value;
    if (text.isEmpty && file == null) return;
    _stopTyping();

    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimistic = ChatMessage(
      id: tempId,
      channelId: convId,
      senderId: myUserId,
      senderName: myName,
      content: text.isNotEmpty ? text : pendingFileType.value?.label ?? '',
      sentAt: DateTime.now(),
      isMe: true,
      type: pendingFileType.value ?? MessageType.text,
      status: MessageStatus.sending,
      isPending: true,
    );
    privateMessages.add(optimistic);
    messageCtrl.clear();
    final capturedFile = file;
    final capturedType = pendingFileType.value;
    pendingFile.value = null;
    pendingFileType.value = null;
    onScrollToBottom?.call();

    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      final idx = privateMessages.indexWhere((m) => m.id == tempId);
      if (idx != -1) privateMessages[idx] = privateMessages[idx].copyWith(status: MessageStatus.sent, isPending: false);
      return;
    }

    try {
      FormData data;
      if (capturedFile != null) {
        data = FormData.fromMap({
          'content': text,
          'type': capturedType?.name ?? 'text',
          'file': await MultipartFile.fromFile(capturedFile.path,
              filename: capturedFile.path.split('/').last),
        });
      } else {
        data = FormData.fromMap({'content': text, 'type': 'text'});
      }
      await RequestService().post('/social/conversations/$convId/messages', data: data);
      final idx = privateMessages.indexWhere((m) => m.id == tempId);
      if (idx != -1) privateMessages[idx] = privateMessages[idx].copyWith(status: MessageStatus.sent, isPending: false);
    } on DioException catch (e) {
      final idx = privateMessages.indexWhere((m) => m.id == tempId);
      if (idx != -1) privateMessages[idx] = privateMessages[idx].copyWith(status: MessageStatus.failed, isPending: false);
      _handleDioError(e);
    }
  }

  Future<int?> startConversationWithUser(int userId) async {
    try {
      if (useMock) return 999;
      final r = await RequestService().post('/social/conversations', data: {'user_id': userId});
      await loadPrivateConversations();
      return r.data['data']['id'];
    } catch (e) {
      debugPrint('startConversation error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MEDIA PICKER
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? xfile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
      );
      if (xfile == null) return;
      pendingFile.value = File(xfile.path);
      pendingFileType.value = MessageType.image;
    } catch (e) {
      debugPrint('pickImage error: $e');
    }
  }

  Future<void> pickVideo() async {
    try {
      final XFile? xfile = await _picker.pickVideo(source: ImageSource.gallery);
      if (xfile == null) return;
      pendingFile.value = File(xfile.path);
      pendingFileType.value = MessageType.video;
    } catch (e) {
      debugPrint('pickVideo error: $e');
    }
  }

  void clearPendingFile() {
    pendingFile.value = null;
    pendingFileType.value = null;
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
        description: 'Rejoignez ce canal et échangez avec la communauté GP',
        membersCount: t['count'] as int,
        isJoined: i < 2,
        isOnline: i % 2 == 0,
        tags: [t['tag'] as String],
        lastMessage: i < 2
            ? ChatMessage(
                id: i * 10, channelId: i + 1, senderId: i + 10,
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
    final names = ['Kadi D.', 'Rickys R.', 'Evelyne K.', 'Rachel B.', 'Sam J.'];
    final avatars = List.generate(5, (i) =>
        'https://randomuser.me/api/portraits/${i % 2 == 0 ? 'women' : 'men'}/${i + 10}.jpg');
    const content = "L'intelligence artificielle redéfinit le marché du travail et ouvre de nouvelles perspectives.";
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final today = DateTime.now();
    return [
      ...List.generate(4, (i) => ChatMessage(
        id: i + 1, channelId: channelId, senderId: i + 1,
        senderName: names[i % names.length],
        senderAvatar: avatars[i % avatars.length],
        content: content,
        sentAt: yesterday.subtract(Duration(minutes: i * 12)),
        isMe: i == 3,
      )),
      ChatMessage(
        id: 100, channelId: channelId, senderId: 1,
        senderName: names[0], senderAvatar: avatars[0],
        content: content,
        sentAt: today.subtract(const Duration(minutes: 15)),
      ),
      ChatMessage(
        id: 101, channelId: channelId, senderId: myUserId,
        senderName: myName,
        content: 'Totalement d\'accord avec ça ! 🔥',
        sentAt: today.subtract(const Duration(minutes: 8)),
        isMe: true,
      ),
    ];
  }

  List<PrivateConversation> _mockPrivateConversations() {
    final names = ['Sam Jean', 'Aicha Bello', 'Kofi Mensah', 'Fatou Diallo',
                   'Serge B.', 'Rachelle D.', 'Hans Dossou', 'Marie T.'];
    return List.generate(names.length, (i) => PrivateConversation(
      id: i + 1, otherUserId: i + 100, otherUserName: names[i],
      otherUserAvatar:
          'https://randomuser.me/api/portraits/${i % 2 == 0 ? 'women' : 'men'}/${i + 20}.jpg',
      otherIsOnline: i % 3 == 0,
      lastMessage: ChatMessage(
        id: i * 10, channelId: i + 1, senderId: i + 100, senderName: names[i],
        content: i % 2 == 0 ? '🎤 Audio' : 'Salut, comment tu vas ? 😊',
        sentAt: DateTime.now().subtract(Duration(minutes: i * 5 + 5)),
        type: i % 2 == 0 ? MessageType.audio : MessageType.text,
      ),
      unreadCount: i % 4 == 0 ? 2 : 0,
    ));
  }

  List<ChatMessage> _mockPrivateMessages(int convId) {
    final conv = privateConversations.firstWhereOrNull((c) => c.id == convId);
    final otherName = conv?.otherUserName ?? 'Utilisateur';
    final otherAvatar = conv?.otherUserAvatar;
    final msgs = [
      ChatMessage(id: 1, channelId: convId, senderId: 100, senderName: otherName,
        senderAvatar: otherAvatar,
        content: 'Salut ! Comment tu vas ?', sentAt: DateTime.now().subtract(const Duration(minutes: 40))),
      ChatMessage(id: 2, channelId: convId, senderId: myUserId, senderName: myName,
        content: 'Bien merci ! Et toi ?', sentAt: DateTime.now().subtract(const Duration(minutes: 38)),
        isMe: true, status: MessageStatus.read),
      ChatMessage(id: 3, channelId: convId, senderId: 100, senderName: otherName,
        senderAvatar: otherAvatar,
        content: 'Super bien ! On se voit ce week-end ?',
        sentAt: DateTime.now().subtract(const Duration(minutes: 35))),
      ChatMessage(id: 4, channelId: convId, senderId: myUserId, senderName: myName,
        content: 'Oui avec plaisir 😊', sentAt: DateTime.now().subtract(const Duration(minutes: 20)),
        isMe: true, status: MessageStatus.delivered),
      ChatMessage(id: 5, channelId: convId, senderId: 100, senderName: otherName,
        senderAvatar: otherAvatar,
        content: '', mediaUrl: 'mock_audio', type: MessageType.audio, audioDurationSec: 12,
        sentAt: DateTime.now().subtract(const Duration(minutes: 5))),
    ];
    return msgs;
  }

  void _handleDioError(DioException e) {
    final msg = e.response != null
        ? 'Erreur ${e.response?.statusCode}'
        : e.message ?? 'Erreur réseau';
    ToastHelper.showToast(msg, backgroundColor: Colors.red, textColor: Colors.white);
  }
}
