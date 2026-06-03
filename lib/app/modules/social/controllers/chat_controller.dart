// lib/app/modules/social/controllers/chat_controller.dart

import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/models/chat_models.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class ChatController extends GetxController {
  // ── State ──────────────────────────────────────────────────────────────────
  final channels             = <ChatChannel>[].obs;
  final privateConversations = <PrivateConversation>[].obs;
  final isChannelsLoading    = false.obs;
  final isConvsLoading       = false.obs;
  final isMessagesLoading    = false.obs;
  final isSending            = false.obs;

  final activeChannel      = Rxn<ChatChannel>();
  final messages           = <ChatMessage>[].obs;
  final activeConversation = Rxn<PrivateConversation>();
  final privateMessages    = <ChatMessage>[].obs;

  // ── Typing ─────────────────────────────────────────────────────────────────
  final typingUsers    = <String>{}.obs;
  final otherIsTyping  = false.obs;
  Timer? _typingDebounce;
  bool   _iAmTyping = false;

  // ── Tabs ───────────────────────────────────────────────────────────────────
  final socialTab = 0.obs;
  final chatTab   = 0.obs;

  // ── Input ──────────────────────────────────────────────────────────────────
  final messageCtrl = TextEditingController();
  final searchCtrl  = TextEditingController();
  final searchQuery = ''.obs;

  // ── Polling ────────────────────────────────────────────────────────────────
  Timer? _pollingTimer;
  static const _pollInterval = Duration(seconds: 4);

  // ── Scroll callback ────────────────────────────────────────────────────────
  VoidCallback? onScrollToBottom;

  // ── Pièce jointe ──────────────────────────────────────────────────────────
  final pendingFile     = Rxn<File>();
  final pendingFileType = Rxn<MessageType>();
  final uploadProgress  = 0.0.obs;

  // ── Audio recorder ────────────────────────────────────────────────────────
  final _recorder          = AudioRecorder();
  final isRecording        = false.obs;
  final recordingDuration  = 0.obs;  // secondes
  Timer? _recordTimer;
  String? _recordingPath;

  // ── Audio player (messages reçus) ─────────────────────────────────────────
  // playerId → state (playing | paused | stopped)
  final Map<int, AudioPlayer> _players = {};
  final playingMessageId = Rxn<int>();
  final audioPosition    = Duration.zero.obs;
  final audioDuration    = Duration.zero.obs;

  // ── Pickers ───────────────────────────────────────────────────────────────
  final _picker = ImagePicker();

  // ── Auth ───────────────────────────────────────────────────────────────────
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
    _recordTimer?.cancel();
    _recorder.dispose();
    for (final p in _players.values) { p.dispose(); }
    messageCtrl.dispose();
    searchCtrl.dispose();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TYPING
  // ─────────────────────────────────────────────────────────────────────────
  void _onTyping() {
    if (messageCtrl.text.isEmpty) { _stopTyping(); return; }
    if (!_iAmTyping) { _iAmTyping = true; }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), _stopTyping);
  }

  void _stopTyping() {
    _iAmTyping = false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // POLLING
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
        final list = (r.data['data'] as List<dynamic>)
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        _mergeMessages(messages, list);
        onScrollToBottom?.call();
      } else if (activeConversation.value != null) {
        final r = await RequestService()
            .get('/social/conversations/${activeConversation.value!.id}/messages');
        final list = (r.data['data'] as List<dynamic>)
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        _mergeMessages(privateMessages, list);
        onScrollToBottom?.call();
      }
    } catch (_) {}
  }

  void _mergeMessages(RxList<ChatMessage> target, List<ChatMessage> fresh) {
    final freshIds = fresh.map((m) => m.id).toSet();
    final pending  = target.where((m) => m.isPending).toList();
    target.assignAll(fresh);  // déjà en ordre croissant (oldest first)
    for (final p in pending) {
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
      channels.value = (r.data['data'] as List<dynamic>)
          .map((e) => ChatChannel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _dioErr(e);
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
        final i = channels.indexWhere((c) => c.id == channel.id);
        if (i != -1) channels[i] = channels[i].copyWith(isJoined: true);
        ToastHelper.showToast('Vous avez rejoint ${channel.name}',
            backgroundColor: Colors.green, textColor: Colors.white);
        return;
      }
      await RequestService().post('/social/channels/${channel.id}/join');
      await loadChannels();
      ToastHelper.showToast('Vous avez rejoint ${channel.name}',
          backgroundColor: Colors.green, textColor: Colors.white);
    } on DioException catch (e) { _dioErr(e); }
  }

  Future<void> leaveChannel(ChatChannel channel) async {
    try {
      if (!useMock) {
        await RequestService().post('/social/channels/${channel.id}/leave');
      }
      final i = channels.indexWhere((c) => c.id == channel.id);
      if (i != -1) channels[i] = channels[i].copyWith(isJoined: false);
      await loadChannels();
    } on DioException catch (e) { _dioErr(e); }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MESSAGES CANAL
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> openChannel(ChatChannel channel) async {
    activeChannel.value = channel;
    activeConversation.value = null;
    messages.clear();
    _stopPolling();
    isMessagesLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
        messages.value = _mockMessages(channel.id);
      } else {
        final r = await RequestService()
            .get('/social/channels/${channel.id}/messages');
        // Backend renvoie oldest first (ordre croissant)
        messages.value = (r.data['data'] as List<dynamic>)
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } finally {
      isMessagesLoading.value = false;
      _startPolling();
      WidgetsBinding.instance.addPostFrameCallback((_) => onScrollToBottom?.call());
    }
  }

  void closeRoom() {
    _stopPolling();
    _stopTyping();
    stopAudio();
    activeChannel.value = null;
    activeConversation.value = null;
    messages.clear();
    privateMessages.clear();
  }

  Future<void> sendMessage(int channelId) async {
    final text = messageCtrl.text.trim();
    final file = pendingFile.value;
    if (text.isEmpty && file == null) return;
    _stopTyping();

    final tempId    = -DateTime.now().millisecondsSinceEpoch;
    final optimistic = ChatMessage(
      id: tempId, channelId: channelId,
      senderId: myUserId, senderName: myName,
      content: text.isNotEmpty ? text : pendingFileType.value?.label ?? '',
      sentAt: DateTime.now(), isMe: true,
      type: pendingFileType.value ?? MessageType.text,
      status: MessageStatus.sending, isPending: true,
      localFilePath: file?.path,
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
      _confirmPending(messages, tempId);
      return;
    }
    try {
      final data = await _buildFormData(text, capturedFile, capturedType);
      await RequestService().post('/social/channels/$channelId/messages', data: data);
      _confirmPending(messages, tempId);
    } on DioException catch (e) {
      _failPending(messages, tempId);
      _dioErr(e);
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
      privateConversations.value = (r.data['data'] as List<dynamic>)
          .map((e) => PrivateConversation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('loadConvs error: $e');
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
        privateMessages.value = (r.data['data'] as List<dynamic>)
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } finally {
      isMessagesLoading.value = false;
      _startPolling();
      WidgetsBinding.instance.addPostFrameCallback((_) => onScrollToBottom?.call());
    }
  }

  Future<void> sendPrivateMessage(int convId) async {
    final text = messageCtrl.text.trim();
    final file = pendingFile.value;
    if (text.isEmpty && file == null) return;
    _stopTyping();

    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimistic = ChatMessage(
      id: tempId, channelId: convId,
      senderId: myUserId, senderName: myName,
      content: text.isNotEmpty ? text : pendingFileType.value?.label ?? '',
      sentAt: DateTime.now(), isMe: true,
      type: pendingFileType.value ?? MessageType.text,
      status: MessageStatus.sending, isPending: true,
      localFilePath: file?.path,
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
      _confirmPending(privateMessages, tempId);
      return;
    }
    try {
      final data = await _buildFormData(text, capturedFile, capturedType);
      await RequestService()
          .post('/social/conversations/$convId/messages', data: data);
      _confirmPending(privateMessages, tempId);
    } on DioException catch (e) {
      _failPending(privateMessages, tempId);
      _dioErr(e);
    }
  }

  Future<int?> startConversationWithUser(int userId) async {
    try {
      if (useMock) return 999;
      final r = await RequestService()
          .post('/social/conversations', data: {'user_id': userId});
      await loadPrivateConversations();
      return _i(r.data['data']['id']);
    } catch (e) {
      debugPrint('startConversation error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MEDIA PICKERS
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
    } catch (e) { debugPrint('pickImage error: $e'); }
  }

  Future<void> pickVideo() async {
    try {
      final XFile? xfile =
          await _picker.pickVideo(source: ImageSource.gallery);
      if (xfile == null) return;
      pendingFile.value = File(xfile.path);
      pendingFileType.value = MessageType.video;
    } catch (e) { debugPrint('pickVideo error: $e'); }
  }

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final pf = result.files.first;
      if (pf.path == null) return;
      pendingFile.value = File(pf.path!);
      pendingFileType.value = MessageType.file;
    } catch (e) { debugPrint('pickFile error: $e'); }
  }

  void clearPendingFile() {
    pendingFile.value = null;
    pendingFileType.value = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AUDIO RECORDER
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        ToastHelper.showToast('Permission micro refusée',
            backgroundColor: Colors.red, textColor: Colors.white);
        return;
      }
      final dir = await getTemporaryDirectory();
      _recordingPath =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: _recordingPath!,
      );
      isRecording.value = true;
      recordingDuration.value = 0;
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        recordingDuration.value++;
        if (recordingDuration.value >= 120) stopAndSendRecording();
      });
    } catch (e) {
      debugPrint('startRecording error: $e');
    }
  }

  Future<void> stopAndSendRecording() async {
    try {
      _recordTimer?.cancel();
      final path = await _recorder.stop();
      isRecording.value = false;
      recordingDuration.value = 0;
      if (path == null) return;

      final file = File(path);
      pendingFile.value = file;
      pendingFileType.value = MessageType.audio;
      // Envoie directement
      if (activeChannel.value != null) {
        await sendMessage(activeChannel.value!.id);
      } else if (activeConversation.value != null) {
        await sendPrivateMessage(activeConversation.value!.id);
      }
    } catch (e) {
      debugPrint('stopRecording error: $e');
    }
  }

  void cancelRecording() async {
    _recordTimer?.cancel();
    await _recorder.stop();
    isRecording.value = false;
    recordingDuration.value = 0;
    _recordingPath = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AUDIO PLAYER
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> toggleAudio(ChatMessage msg) async {
    final url = msg.mediaUrl ?? msg.content;
    if (url.isEmpty || url == 'mock_audio') return;

    if (playingMessageId.value == msg.id) {
      // Pause / reprendre
      final p = _players[msg.id];
      if (p == null) return;
      final state = await p.getCurrentPosition();
      if (state != null) { await p.pause(); }
      else { await p.resume(); }
      return;
    }

    // Arrêter le précédent
    await stopAudio();

    final player = AudioPlayer();
    _players[msg.id] = player;
    playingMessageId.value = msg.id;

    player.onDurationChanged.listen((d) => audioDuration.value = d);
    player.onPositionChanged.listen((p) => audioPosition.value = p);
    player.onPlayerComplete.listen((_) {
      playingMessageId.value = null;
      audioPosition.value = Duration.zero;
    });

    try {
      await player.play(UrlSource(url));
    } catch (e) {
      debugPrint('Audio play error: $e');
      playingMessageId.value = null;
    }
  }

  Future<void> stopAudio() async {
    for (final p in _players.values) {
      await p.stop();
      await p.dispose();
    }
    _players.clear();
    playingMessageId.value = null;
    audioPosition.value = Duration.zero;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS PRIVÉS
  // ─────────────────────────────────────────────────────────────────────────
  Future<FormData> _buildFormData(
      String text, File? file, MessageType? type) async {
    if (file != null) {
      return FormData.fromMap({
        'content': text,
        'type': type?.name ?? 'file',
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });
    }
    return FormData.fromMap({'content': text, 'type': 'text'});
  }

  void _confirmPending(RxList<ChatMessage> target, int tempId) {
    final i = target.indexWhere((m) => m.id == tempId);
    if (i != -1) {
      target[i] = target[i].copyWith(
          status: MessageStatus.sent, isPending: false);
    }
  }

  void _failPending(RxList<ChatMessage> target, int tempId) {
    final i = target.indexWhere((m) => m.id == tempId);
    if (i != -1) {
      target[i] = target[i].copyWith(
          status: MessageStatus.failed, isPending: false);
    }
  }

  void _dioErr(DioException e) {
    final msg = e.response != null
        ? 'Erreur ${e.response?.statusCode}'
        : e.message ?? 'Erreur réseau';
    ToastHelper.showToast(msg,
        backgroundColor: Colors.red, textColor: Colors.white);
  }

  static int _i(dynamic v) =>
      v is int ? v : int.tryParse('$v') ?? 0;

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
        id: i + 1, name: t['name'] as String,
        description: 'Rejoignez ce canal et échangez avec la communauté GP',
        membersCount: t['count'] as int,
        isJoined: i < 2, isOnline: i % 2 == 0, tags: [t['tag'] as String],
        lastMessage: i < 2
            ? ChatMessage(
                id: i * 10, channelId: i + 1, senderId: i + 10,
                senderName: 'Sam Jean',
                content: "L'expérience de la dame qui vend au marché...",
                sentAt: DateTime.now().subtract(const Duration(minutes: 5)))
            : null,
        unreadCount: i == 1 ? 3 : 0,
      );
    });
  }

  List<ChatMessage> _mockMessages(int channelId) {
    final names = ['Kadi D.', 'Rickys R.', 'Evelyne K.', 'Rachel B.', 'Sam J.'];
    final avatars = List.generate(5,
        (i) => 'https://randomuser.me/api/portraits/${i%2==0?"women":"men"}/${i+10}.jpg');
    const txt = "L'IA redéfinit le marché du travail et ouvre de nouvelles perspectives.";
    final now = DateTime.now();
    // Retournés en ordre croissant (les plus anciens d'abord)
    return [
      ChatMessage(id:1, channelId:channelId, senderId:1, senderName:names[0], senderAvatar:avatars[0],
          content:txt, sentAt:now.subtract(const Duration(hours:2))),
      ChatMessage(id:2, channelId:channelId, senderId:2, senderName:names[1], senderAvatar:avatars[1],
          content:'Totalement d\'accord 💯', sentAt:now.subtract(const Duration(hours:1, minutes:50))),
      ChatMessage(id:3, channelId:channelId, senderId:myUserId, senderName:myName,
          content:'Je pense que la formation continue est la clé 🔑',
          sentAt:now.subtract(const Duration(hours:1, minutes:30)), isMe:true, status:MessageStatus.read),
      ChatMessage(id:4, channelId:channelId, senderId:3, senderName:names[2], senderAvatar:avatars[2],
          content:'', type:MessageType.audio, audioDurationSec:8,
          sentAt:now.subtract(const Duration(minutes:20))),
      ChatMessage(id:5, channelId:channelId, senderId:myUserId, senderName:myName,
          content:'Exactement 🔥', sentAt:now.subtract(const Duration(minutes:5)),
          isMe:true, status:MessageStatus.delivered),
    ];
  }

  List<PrivateConversation> _mockPrivateConversations() {
    final names = ['Sam Jean', 'Aicha Bello', 'Kofi Mensah', 'Fatou Diallo',
                   'Serge B.', 'Rachelle D.', 'Hans Dossou', 'Marie T.'];
    return List.generate(names.length, (i) => PrivateConversation(
      id: i+1, otherUserId: i+100, otherUserName: names[i],
      otherUserAvatar:
          'https://randomuser.me/api/portraits/${i%2==0?"women":"men"}/${i+20}.jpg',
      otherIsOnline: i%3==0,
      lastMessage: ChatMessage(
        id: i*10, channelId: i+1, senderId: i+100, senderName: names[i],
        content: i%2==0 ? '🎤 Message vocal' : 'Salut, comment tu vas ? 😊',
        sentAt: DateTime.now().subtract(Duration(minutes: i*5+5)),
        type: i%2==0 ? MessageType.audio : MessageType.text,
      ),
      unreadCount: i%4==0 ? 2 : 0,
    ));
  }

  List<ChatMessage> _mockPrivateMessages(int convId) {
    final conv = privateConversations.firstWhereOrNull((c) => c.id == convId);
    final otherName   = conv?.otherUserName ?? 'Utilisateur';
    final otherAvatar = conv?.otherUserAvatar;
    final now = DateTime.now();
    return [
      ChatMessage(id:1, channelId:convId, senderId:100, senderName:otherName,
          senderAvatar:otherAvatar,
          content:'Salut ! Comment tu vas ?',
          sentAt:now.subtract(const Duration(minutes:40))),
      ChatMessage(id:2, channelId:convId, senderId:myUserId, senderName:myName,
          content:'Bien merci ! Et toi ?',
          sentAt:now.subtract(const Duration(minutes:38)),
          isMe:true, status:MessageStatus.read),
      ChatMessage(id:3, channelId:convId, senderId:100, senderName:otherName,
          senderAvatar:otherAvatar,
          content:'Super bien ! On se voit ce week-end ?',
          sentAt:now.subtract(const Duration(minutes:35))),
      ChatMessage(id:4, channelId:convId, senderId:myUserId, senderName:myName,
          content:'Oui avec plaisir 😊',
          sentAt:now.subtract(const Duration(minutes:20)),
          isMe:true, status:MessageStatus.delivered),
      ChatMessage(id:5, channelId:convId, senderId:100, senderName:otherName,
          senderAvatar:otherAvatar,
          content:'', mediaUrl:'mock_audio', type:MessageType.audio,
          audioDurationSec:12,
          sentAt:now.subtract(const Duration(minutes:5))),
    ];
  }
}
