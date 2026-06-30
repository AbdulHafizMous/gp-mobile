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
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;

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
  final typingUsers   = <String>{}.obs;
  final otherIsTyping = false.obs;
  Timer? _typingDebounce;

  // ── Tabs ───────────────────────────────────────────────────────────────────
  final socialTab = 0.obs;
  final chatTab   = 0.obs;

  // ── Input ─────────────────────────────────────────────────────────────────
  final messageCtrl = TextEditingController();
  final messageText = ''.obs;
  final searchCtrl  = TextEditingController();
  final searchQuery = ''.obs;

  // ── Reply ─────────────────────────────────────────────────────────────────
  final replyingTo = Rxn<ChatMessage>();

  // ── Polling ────────────────────────────────────────────────────────────────
  Timer? _pollingTimer;
  static const _pollInterval = Duration(seconds: 4);

  VoidCallback? onScrollToBottom;

  // ── Pièce jointe ──────────────────────────────────────────────────────────
  final pendingFile     = Rxn<File>();
  final pendingFileType = Rxn<MessageType>();

  // ── Audio recorder ────────────────────────────────────────────────────────
  final _recorder         = AudioRecorder();
  final isRecording       = false.obs;
  final recordingDuration = 0.obs;
  Timer? _recordTimer;

  // ── Audio player ──────────────────────────────────────────────────────────
  final Map<int, AudioPlayer> _players = {};
  final playingMessageId = Rxn<int>();
  final audioPosition    = Duration.zero.obs;
  final audioDuration    = Duration.zero.obs;
  final isAudioPlaying   = false.obs;

  // ── File download ─────────────────────────────────────────────────────────
  final downloadingMessageId = Rxn<int>();

  // ── Pickers ───────────────────────────────────────────────────────────────
  final _picker = ImagePicker();

  // ── Auth ───────────────────────────────────────────────────────────────────
  int    get myUserId => GetStorage().read<int>('userId') ?? 0;
  String get myName   => GetStorage().read<String>('username') ?? 'Moi';

  // ─────────────────────────────────────────────────────────────────────────
  // INIT / CLOSE
  // ─────────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    loadChannels();
    loadPrivateConversations();
    messageCtrl.addListener(() {
      messageText.value = messageCtrl.text;
      _onTyping();
    });
    searchCtrl.addListener(() => searchQuery.value = searchCtrl.text);
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
  // REPLY
  // ─────────────────────────────────────────────────────────────────────────
  void startReply(ChatMessage msg) {
    replyingTo.value = msg;
    // Focus le champ de saisie
    messageCtrl.text = messageCtrl.text; // trigger rebuild
  }

  void cancelReply() => replyingTo.value = null;

  // ─────────────────────────────────────────────────────────────────────────
  // TYPING
  // ─────────────────────────────────────────────────────────────────────────
  void _onTyping() {
    if (messageCtrl.text.isEmpty) { _typingDebounce?.cancel(); return; }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // POLLING
  // ─────────────────────────────────────────────────────────────────────────
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollInterval, (_) => _pollMessages());
  }

  void _stopPolling() { _pollingTimer?.cancel(); _pollingTimer = null; }

  Future<void> _pollMessages() async {
    if (useMock) return;
    try {
      if (activeChannel.value != null) {
        final r = await RequestService().get('/social/channels/${activeChannel.value!.id}/messages');
        _mergeMessages(messages, (r.data['data'] as List).map((e) => ChatMessage.fromJson(e)).toList());
        onScrollToBottom?.call();
      } else if (activeConversation.value != null) {
        final r = await RequestService().get('/social/conversations/${activeConversation.value!.id}/messages');
        _mergeMessages(privateMessages, (r.data['data'] as List).map((e) => ChatMessage.fromJson(e)).toList());
        onScrollToBottom?.call();
      }
    } catch (_) {}
  }

  void _mergeMessages(RxList<ChatMessage> target, List<ChatMessage> fresh) {
    final freshIds = fresh.map((m) => m.id).toSet();
    final pending  = target.where((m) => m.isPending).toList();
    target.assignAll(fresh);
    for (final p in pending) { if (!freshIds.contains(p.id)) target.add(p); }
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
      channels.value = (r.data['data'] as List).map((e) => ChatChannel.fromJson(e)).toList();
    } on DioException catch (e) { _dioErr(e); }
    finally { isChannelsLoading.value = false; }
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
      if (!useMock) await RequestService().post('/social/channels/${channel.id}/join');
      final i = channels.indexWhere((c) => c.id == channel.id);
      if (i != -1) channels[i] = channels[i].copyWith(isJoined: true);
      ToastHelper.showToast('Vous avez rejoint ${channel.name}', backgroundColor: Colors.green, textColor: Colors.white);
    } on DioException catch (e) { _dioErr(e); }
  }

  Future<void> leaveChannel(ChatChannel channel) async {
    try {
      if (!useMock) await RequestService().post('/social/channels/${channel.id}/leave');
      final i = channels.indexWhere((c) => c.id == channel.id);
      if (i != -1) channels[i] = channels[i].copyWith(isJoined: false);
      await loadChannels();
    } on DioException catch (e) { _dioErr(e); }
  }

  Future<void> openChannel(ChatChannel channel) async {
    activeChannel.value = channel;
    activeConversation.value = null;
    messages.clear();
    replyingTo.value = null;
    _stopPolling();
    isMessagesLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
        messages.value = _mockMessages(channel.id);
      } else {
        final r = await RequestService().get('/social/channels/${channel.id}/messages');
        messages.value = (r.data['data'] as List).map((e) => ChatMessage.fromJson(e)).toList();
      }
    } finally {
      isMessagesLoading.value = false;
      _startPolling();
      WidgetsBinding.instance.addPostFrameCallback((_) => onScrollToBottom?.call());
    }
  }

  void closeRoom() {
    _stopPolling();
    stopAudio();
    replyingTo.value = null;
    activeChannel.value = null;
    activeConversation.value = null;
    messages.clear();
    privateMessages.clear();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEND — CANAL
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> sendMessage(int channelId) async {
    final text = messageCtrl.text.trim();
    final file = pendingFile.value;
    if (text.isEmpty && file == null) return;

    final reply = replyingTo.value;
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimistic = ChatMessage(
      id: tempId, channelId: channelId,
      senderId: myUserId, senderName: myName,
      content: text.isNotEmpty ? text : pendingFileType.value?.label ?? '',
      sentAt: DateTime.now(), isMe: true,
      type: pendingFileType.value ?? MessageType.text,
      status: MessageStatus.sending, isPending: true,
      localFilePath: file?.path,
      replyToId: reply?.id,
      replyToSenderName: reply?.senderName,
      replyToContent: reply?.content,
      replyToType: reply?.type,
    );
    messages.add(optimistic);
    messageCtrl.clear();
    final capturedFile = file;
    final capturedType = pendingFileType.value;
    pendingFile.value = null;
    pendingFileType.value = null;
    replyingTo.value = null;
    onScrollToBottom?.call();

    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      _confirmPending(messages, tempId);
      return;
    }
    try {
      final data = await _buildFormData(text, capturedFile, capturedType, replyId: reply?.id);
      await RequestService().post('/social/channels/$channelId/messages', data: data);
      _confirmPending(messages, tempId);
    } on DioException catch (e) {
      _failPending(messages, tempId);
      _dioErr(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELETE MESSAGE
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> deleteMessage(ChatMessage msg) async {
    // Supprime localement immédiatement
    messages.removeWhere((m) => m.id == msg.id);
    privateMessages.removeWhere((m) => m.id == msg.id);

    if (useMock || msg.id < 0) return;
    try {
      await RequestService().delete('/social/messages/${msg.id}');
    } on DioException catch (e) {
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
      privateConversations.value = (r.data['data'] as List)
          .map((e) => PrivateConversation.fromJson(e)).toList();
    } catch (e) { debugPrint('loadConvs error: $e'); }
    finally { isConvsLoading.value = false; }
  }

  Future<void> openPrivateConversation(PrivateConversation conv) async {
    activeConversation.value = conv;
    activeChannel.value = null;
    privateMessages.clear();
    replyingTo.value = null;
    _stopPolling();
    isMessagesLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
        privateMessages.value = _mockPrivateMessages(conv.id);
      } else {
        final r = await RequestService().get('/social/conversations/${conv.id}/messages');
        privateMessages.value = (r.data['data'] as List)
            .map((e) => ChatMessage.fromJson(e)).toList();
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

    final reply = replyingTo.value;
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimistic = ChatMessage(
      id: tempId, channelId: convId,
      senderId: myUserId, senderName: myName,
      content: text.isNotEmpty ? text : pendingFileType.value?.label ?? '',
      sentAt: DateTime.now(), isMe: true,
      type: pendingFileType.value ?? MessageType.text,
      status: MessageStatus.sending, isPending: true,
      localFilePath: file?.path,
      replyToId: reply?.id,
      replyToSenderName: reply?.senderName,
      replyToContent: reply?.content,
      replyToType: reply?.type,
    );
    privateMessages.add(optimistic);
    messageCtrl.clear();
    final capturedFile = file;
    final capturedType = pendingFileType.value;
    pendingFile.value = null;
    pendingFileType.value = null;
    replyingTo.value = null;
    onScrollToBottom?.call();

    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      _confirmPending(privateMessages, tempId);
      return;
    }
    try {
      final data = await _buildFormData(text, capturedFile, capturedType, replyId: reply?.id);
      await RequestService().post('/social/conversations/$convId/messages', data: data);
      _confirmPending(privateMessages, tempId);
    } on DioException catch (e) {
      _failPending(privateMessages, tempId);
      _dioErr(e);
    }
  }

  Future<int?> startConversationWithUser(int userId) async {
    try {
      if (useMock) return 999;
      final r = await RequestService().post('/social/conversations', data: {'user_id': userId});
      await loadPrivateConversations();
      return _i(r.data['data']['id']);
    } catch (e) { debugPrint('startConversation error: $e'); return null; }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MEMBRES / MÉDIAS PARTAGÉS / BLOCAGE — pour le menu 3 points
  // ─────────────────────────────────────────────────────────────────────────
  final channelMembers   = <Map<String, dynamic>>[].obs;
  final sharedMedia       = <ChatMessage>[].obs;
  final isMembersLoading  = false.obs;
  final isMediaLoading    = false.obs;
  final isBlocked         = false.obs;

  Future<void> loadChannelMembers(int channelId) async {
    isMembersLoading.value = true;
    channelMembers.clear();
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
        channelMembers.value = List.generate(8, (i) => {
          'id': i + 1,
          'name': 'Membre ${i + 1}',
          'avatar_url': 'https://randomuser.me/api/portraits/${i%2==0?"women":"men"}/${i+30}.jpg',
          'role': i == 0 ? 'Admin' : 'User',
        });
        return;
      }
      final r = await RequestService().get('/social/channels/$channelId/members');
      channelMembers.value = (r.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      debugPrint('loadChannelMembers error: $e');
    } finally { isMembersLoading.value = false; }
  }

  Future<void> loadSharedMedia({int? channelId, int? conversationId}) async {
    isMediaLoading.value = true;
    sharedMedia.clear();
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
        return;
      }
      final path = channelId != null
          ? '/social/channels/$channelId/media'
          : '/social/conversations/$conversationId/media';
      final r = await RequestService().get(path);
      sharedMedia.value = (r.data['data'] as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('loadSharedMedia error: $e');
    } finally { isMediaLoading.value = false; }
  }

  Future<void> blockUser(int userId) async {
    try {
      if (!useMock) await RequestService().post('/social/users/$userId/block');
      isBlocked.value = true;
      ToastHelper.showToast('Utilisateur bloqué', backgroundColor: Colors.green, textColor: Colors.white);
    } on DioException catch (e) { _dioErr(e); }
  }

  Future<void> unblockUser(int userId) async {
    try {
      if (!useMock) await RequestService().delete('/social/users/$userId/block');
      isBlocked.value = false;
      ToastHelper.showToast('Utilisateur débloqué', backgroundColor: Colors.green, textColor: Colors.white);
    } on DioException catch (e) { _dioErr(e); }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MEDIA PICKERS
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? xfile = await _picker.pickImage(
          source: fromCamera ? ImageSource.camera : ImageSource.gallery, imageQuality: 80);
      if (xfile == null) return;
      pendingFile.value = File(xfile.path);
      pendingFileType.value = MessageType.image;
    } catch (e) { debugPrint('pickImage error: $e'); }
  }

  Future<void> pickVideo() async {
    try {
      final XFile? xfile = await _picker.pickVideo(source: ImageSource.gallery);
      if (xfile == null) return;
      pendingFile.value = File(xfile.path);
      pendingFileType.value = MessageType.video;
    } catch (e) { debugPrint('pickVideo error: $e'); }
  }

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
      if (result == null || result.files.isEmpty || result.files.first.path == null) return;
      pendingFile.value = File(result.files.first.path!);
      pendingFileType.value = MessageType.file;
    } catch (e) { debugPrint('pickFile error: $e'); }
  }

  void clearPendingFile() { pendingFile.value = null; pendingFileType.value = null; }

  // ─────────────────────────────────────────────────────────────────────────
  // FILE DOWNLOAD
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> downloadFile(ChatMessage msg) async {
    final url = msg.mediaUrl;
    if (url == null || url.isEmpty) {
      ToastHelper.showToast('URL invalide', backgroundColor: Colors.red, textColor: Colors.white);
      return;
    }
    downloadingMessageId.value = msg.id;
    try {
      final dir = await getTemporaryDirectory();
      final fileName = msg.fileName ?? url.split('/').last;
      final filePath = '${dir.path}/$fileName';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await File(filePath).writeAsBytes(response.bodyBytes);
        await OpenFilex.open(filePath);
      } else {
        ToastHelper.showToast('Téléchargement échoué', backgroundColor: Colors.red, textColor: Colors.white);
      }
    } catch (e) {
      ToastHelper.showToast('Erreur de téléchargement', backgroundColor: Colors.red, textColor: Colors.white);
    } finally { downloadingMessageId.value = null; }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AUDIO RECORDER — Flow WhatsApp
  // startRecording  : appel manuel (onLongPress ou bouton dans AttachMenu)
  // stopAndSend     : relâcher le long press → demande confirmation
  // cancelRecording : glisser vers annuler ou bouton annuler
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> startRecording() async {
    try {
      final ok = await _recorder.hasPermission();
      if (!ok) {
        ToastHelper.showToast('Permission micro refusée', backgroundColor: Colors.red, textColor: Colors.white);
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
          path: path);
      isRecording.value = true;
      recordingDuration.value = 0;
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        recordingDuration.value++;
        if (recordingDuration.value >= 120) stopAndSendRecording();
      });
    } catch (e) { debugPrint('startRecording error: $e'); }
  }

  /// Arrête et envoie directement (appelé depuis le flow long-press release)
  Future<void> stopAndSendRecording() async {
    try {
      _recordTimer?.cancel();
      final path = await _recorder.stop();
      isRecording.value = false;
      recordingDuration.value = 0;
      if (path == null) return;
      pendingFile.value = File(path);
      pendingFileType.value = MessageType.audio;
      if (activeChannel.value != null) {
        await sendMessage(activeChannel.value!.id);
      } else if (activeConversation.value != null) {
        await sendPrivateMessage(activeConversation.value!.id);
      }
    } catch (e) { debugPrint('stopRecording error: $e'); }
  }

  void cancelRecording() async {
    _recordTimer?.cancel();
    await _recorder.stop();
    isRecording.value = false;
    recordingDuration.value = 0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AUDIO PLAYER
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> toggleAudio(ChatMessage msg) async {
    final url = msg.mediaUrl ?? msg.content;
    if (url.isEmpty || url == 'mock_audio') return;

    if (playingMessageId.value == msg.id) {
      final player = _players[msg.id];
      if (player == null) return;
      if (isAudioPlaying.value) {
        await player.pause();
        isAudioPlaying.value = false;
      } else {
        await player.resume();
        isAudioPlaying.value = true;
      }
      return;
    }

    await stopAudio();
    final player = AudioPlayer();
    _players[msg.id] = player;
    playingMessageId.value = msg.id;
    audioPosition.value = Duration.zero;
    audioDuration.value = Duration.zero;

    player.onDurationChanged.listen((d) => audioDuration.value = d);
    player.onPositionChanged.listen((pos) { if (playingMessageId.value == msg.id) audioPosition.value = pos; });
    player.onPlayerComplete.listen((_) {
      playingMessageId.value = null;
      isAudioPlaying.value = false;
      audioPosition.value = Duration.zero;
      audioDuration.value = Duration.zero;
      _players.remove(msg.id);
    });
    player.onPlayerStateChanged.listen((state) {
      if (playingMessageId.value == msg.id) isAudioPlaying.value = state == PlayerState.playing;
    });

    try {
      await player.play(UrlSource(url));
      isAudioPlaying.value = true;
    } catch (e) {
      debugPrint('Audio play error: $e');
      playingMessageId.value = null;
      isAudioPlaying.value = false;
      _players.remove(msg.id);
    }
  }

  Future<void> seekAudio(ChatMessage msg, double progress) async {
    final player = _players[msg.id];
    if (player == null) return;
    final total = audioDuration.value;
    if (total.inMilliseconds == 0) return;
    await player.seek(Duration(milliseconds: (total.inMilliseconds * progress).round()));
  }

  Future<void> stopAudio() async {
    for (final p in _players.values) { await p.stop(); await p.dispose(); }
    _players.clear();
    playingMessageId.value = null;
    isAudioPlaying.value = false;
    audioPosition.value = Duration.zero;
    audioDuration.value = Duration.zero;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  Future<FormData> _buildFormData(String text, File? file, MessageType? type, {int? replyId}) async {
    final Map<String, dynamic> map = {
      'content': text,
      'type': type?.name ?? 'text',
      if (replyId != null) 'reply_to_id': replyId,
    };
    if (file != null) {
      map['file'] = await MultipartFile.fromFile(file.path, filename: file.path.split('/').last);
    }
    return FormData.fromMap(map);
  }

  void _confirmPending(RxList<ChatMessage> target, int tempId) {
    final i = target.indexWhere((m) => m.id == tempId);
    if (i != -1) target[i] = target[i].copyWith(status: MessageStatus.sent, isPending: false);
  }

  void _failPending(RxList<ChatMessage> target, int tempId) {
    final i = target.indexWhere((m) => m.id == tempId);
    if (i != -1) target[i] = target[i].copyWith(status: MessageStatus.failed, isPending: false);
  }

  void _dioErr(DioException e) {
    final msg = e.response != null ? 'Erreur ${e.response?.statusCode}' : e.message ?? 'Erreur réseau';
    ToastHelper.showToast(msg, backgroundColor: Colors.red, textColor: Colors.white);
  }

  static int _i(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

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
    ];
    return List.generate(topics.length, (i) {
      final t = topics[i];
      return ChatChannel(
        id: i + 1, name: t['name'] as String,
        description: 'Rejoignez ce canal et échangez avec la communauté GP',
        membersCount: t['count'] as int,
        isJoined: i < 2, isOnline: i % 2 == 0, tags: [t['tag'] as String],
        lastMessage: i < 2 ? ChatMessage(
          id: i * 10, channelId: i + 1, senderId: i + 10,
          senderName: 'Sam Jean', content: "L'expérience de la dame qui vend au marché...",
          sentAt: DateTime.now().subtract(const Duration(minutes: 5))) : null,
        unreadCount: i == 1 ? 3 : 0,
      );
    });
  }

  List<ChatMessage> _mockMessages(int channelId) {
    final names   = ['Kadi D.', 'Rickys R.', 'Evelyne K.', 'Rachel B.'];
    final avatars = List.generate(4, (i) => 'https://randomuser.me/api/portraits/${i%2==0?"women":"men"}/${i+10}.jpg');
    final now = DateTime.now();
    return [
      ChatMessage(id:1, channelId:channelId, senderId:1, senderName:names[0], senderAvatar:avatars[0],
          content:"L'IA redéfinit le marché du travail.", sentAt:now.subtract(const Duration(hours:2))),
      ChatMessage(id:2, channelId:channelId, senderId:2, senderName:names[1], senderAvatar:avatars[1],
          content:'Totalement d\'accord 💯', sentAt:now.subtract(const Duration(hours:1, minutes:50)),
          replyToId:1, replyToSenderName:'Kadi D.', replyToContent:"L'IA redéfinit le marché du travail."),
      ChatMessage(id:3, channelId:channelId, senderId:myUserId, senderName:myName,
          content:'Je pense que la formation continue est la clé 🔑',
          sentAt:now.subtract(const Duration(hours:1, minutes:30)), isMe:true, status:MessageStatus.read),
      ChatMessage(id:4, channelId:channelId, senderId:3, senderName:names[2], senderAvatar:avatars[2],
          content:'', type:MessageType.audio, audioDurationSec:8, sentAt:now.subtract(const Duration(minutes:20))),
      ChatMessage(id:5, channelId:channelId, senderId:myUserId, senderName:myName,
          content:'Exactement 🔥', sentAt:now.subtract(const Duration(minutes:5)),
          isMe:true, status:MessageStatus.delivered),
    ];
  }

  List<PrivateConversation> _mockPrivateConversations() {
    final names = ['Sam Jean', 'Aicha Bello', 'Kofi Mensah', 'Fatou Diallo', 'Serge B.', 'Rachelle D.'];
    return List.generate(names.length, (i) => PrivateConversation(
      id: i+1, otherUserId: i+100, otherUserName: names[i],
      otherUserAvatar: 'https://randomuser.me/api/portraits/${i%2==0?"women":"men"}/${i+20}.jpg',
      otherIsOnline: i%3==0,
      lastMessage: ChatMessage(id: i*10, channelId: i+1, senderId: i+100, senderName: names[i],
          content: i%2==0 ? '🎤 Message vocal' : 'Salut, comment tu vas ? 😊',
          sentAt: DateTime.now().subtract(Duration(minutes: i*5+5)),
          type: i%2==0 ? MessageType.audio : MessageType.text),
      unreadCount: i%4==0 ? 2 : 0,
    ));
  }

  List<ChatMessage> _mockPrivateMessages(int convId) {
    final conv = privateConversations.firstWhereOrNull((c) => c.id == convId);
    final otherName = conv?.otherUserName ?? 'Utilisateur';
    final otherAvatar = conv?.otherUserAvatar;
    final now = DateTime.now();
    return [
      ChatMessage(id:1, channelId:convId, senderId:100, senderName:otherName, senderAvatar:otherAvatar,
          content:'Salut ! Comment tu vas ?', sentAt:now.subtract(const Duration(minutes:40))),
      ChatMessage(id:2, channelId:convId, senderId:myUserId, senderName:myName,
          content:'Bien merci ! Et toi ?', sentAt:now.subtract(const Duration(minutes:38)),
          isMe:true, status:MessageStatus.read),
      ChatMessage(id:3, channelId:convId, senderId:100, senderName:otherName, senderAvatar:otherAvatar,
          content:'Super bien ! On se voit ce week-end ?', sentAt:now.subtract(const Duration(minutes:35)),
          replyToId:2, replyToSenderName:myName, replyToContent:'Bien merci ! Et toi ?'),
      ChatMessage(id:4, channelId:convId, senderId:myUserId, senderName:myName,
          content:'Oui avec plaisir 😊', sentAt:now.subtract(const Duration(minutes:20)),
          isMe:true, status:MessageStatus.delivered),
    ];
  }
}