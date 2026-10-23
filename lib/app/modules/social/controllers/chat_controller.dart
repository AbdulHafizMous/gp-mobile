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
import 'package:grand_public_v2/app/services/crush_quota_service.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/api_error_helper.dart';
import 'package:grand_public_v2/app/utils/crush_paywall_helper.dart';
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

  // ── Présence / saisie / accusés (conversations privées) ────────────────────
  final peerOnline   = false.obs;
  final peerLastSeen = Rxn<DateTime>();
  final peerTyping   = ''.obs;          // '' | text | audio
  int _peerDeliveredId = 0, _peerReadId = 0;
  Timer? _presenceTimer;
  DateTime _lastTypingPing = DateTime.fromMillisecondsSinceEpoch(0);
  int _pollTick = 0;
  final _box = GetStorage();

  /// « vu aujourd'hui à 14:32 » / « vu hier à … » / « vu le 12/10 à … ».
  String lastSeenLabel(DateTime? t) {
    if (t == null) return 'Hors ligne';
    final l = t.toLocal(), n = DateTime.now();
    final hm = '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    final d0 = DateTime(n.year, n.month, n.day), d1 = DateTime(l.year, l.month, l.day);
    final diff = d0.difference(d1).inDays;
    if (diff == 0) return 'vu aujourd\'hui à $hm';
    if (diff == 1) return 'vu hier à $hm';
    return 'vu le ${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')} à $hm';
  }

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
  // static const _pollInterval = Duration(seconds: 4);

  VoidCallback? onScrollToBottom;

  // ── Pièce jointe ──────────────────────────────────────────────────────────
  final pendingFile     = Rxn<File>();
  final pendingFileType = Rxn<MessageType>();
  final pendingViewOnce = false.obs; // photo/vidéo envoyée en « vue unique »

  // ── Thème & fond d'écran (locaux à l'appareil, par discussion) ─────────────
  final myBubbleColor = Rxn<Color>();
  final wallpaper     = 'none'.obs; // none | preset id | file:<path>
  int? _themeConv;

  void loadTheme(int? convId) {
    _themeConv = convId;
    final m = _box.read('chat_theme_${convId ?? 'default'}') ?? _box.read('chat_theme_default');
    if (m is Map) {
      myBubbleColor.value = m['accent'] != null ? Color(m['accent'] as int) : null;
      wallpaper.value = m['wallpaper']?.toString() ?? 'none';
    } else {
      myBubbleColor.value = null;
      wallpaper.value = 'none';
    }
  }

  void saveTheme({bool asDefault = false}) {
    final data = {'accent': myBubbleColor.value?.toARGB32(), 'wallpaper': wallpaper.value};
    _box.write('chat_theme_${_themeConv ?? 'default'}', data);
    if (asDefault) _box.write('chat_theme_default', data);
  }

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
  bool   get myIsAdmin {
    final role = GetStorage().read<String>('role')?.toLowerCase() ?? '';
    return role == 'admin' || role == 'super admin';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INIT / CLOSE
  // ─────────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    loadChannels();
    loadPrivateConversations();
    _presenceTimer = Timer.periodic(const Duration(seconds: 40), (_) => _pingPresence());
    _pingPresence();
    messageCtrl.addListener(() {
      messageText.value = messageCtrl.text;
      _onTyping();
    });
    searchCtrl.addListener(() => searchQuery.value = searchCtrl.text);
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    _presenceTimer?.cancel();
    _stateTimer?.cancel();
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
    // « écrit… » : au plus un ping toutes les 3 s, uniquement en privé.
    final conv = activeConversation.value;
    if (useMock || conv == null) return;
    final now = DateTime.now();
    if (now.difference(_lastTypingPing).inSeconds < 3) return;
    _lastTypingPing = now;
    RequestService().post('/social/conversations/${conv.id}/typing');
  }

  Future<void> _pingPresence() async {
    if (useMock) return;
    try { await RequestService().post('/social/presence'); } catch (_) {}
  }

  /// Accusés + présence de l'autre (léger, appelé par le polling).
  Future<void> _pollState() async {
    final conv = activeConversation.value;
    if (useMock || conv == null) return;
    try {
      final d = (await RequestService().get('/social/conversations/${conv.id}/state')).data['data'] as Map;
      peerOnline.value = d['online'] == true;
      peerLastSeen.value = d['last_seen_at'] != null ? DateTime.tryParse(d['last_seen_at'].toString()) : null;
      peerTyping.value = d['typing']?.toString() ?? '';
      otherIsTyping.value = peerTyping.value.isNotEmpty;
      _peerDeliveredId = int.tryParse('${d['peer_delivered_id']}') ?? 0;
      _peerReadId = int.tryParse('${d['peer_read_id']}') ?? 0;
      _applyReceipts();
    } catch (_) {}
  }

  /// ✓ envoyé · ✓✓ reçu · ✓✓ bleu lu — calculés depuis les ids vus par l'autre.
  void _applyReceipts() {
    for (var i = 0; i < privateMessages.length; i++) {
      final m = privateMessages[i];
      if (!m.isMe || m.isPending || m.id <= 0) continue;
      final st = m.id <= _peerReadId ? MessageStatus.read : (m.id <= _peerDeliveredId ? MessageStatus.delivered : MessageStatus.sent);
      if (st != m.status) privateMessages[i] = m.copyWith(status: st);
    }
  }

  DateTime _lastReadPing = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void> _markRead({bool force = false}) async {
    final conv = activeConversation.value;
    if (useMock || conv == null) return;
    if (!force && DateTime.now().difference(_lastReadPing).inSeconds < 3) return;
    _lastReadPing = DateTime.now();
    try {
      await RequestService().post('/social/conversations/${conv.id}/read');
      final i = privateConversations.indexWhere((c) => c.id == conv.id);
      if (i != -1) privateConversations[i] = privateConversations[i].copyWith(unreadCount: 0);
    } catch (_) {}
  }

  // ── Cache local (évite de re-télécharger l'historique à chaque ouverture) ──
  List<dynamic> _cachedMsgs(int convId) {
    final v = _box.read('chat_msgs_$convId');
    return v is List ? v : <dynamic>[];
  }

  void _saveMsgs(int convId, List<dynamic> raw) {
    final cut = raw.length > 150 ? raw.sublist(raw.length - 150) : raw;
    _box.write('chat_msgs_$convId', cut);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // POLLING
  // ─────────────────────────────────────────────────────────────────────────
  // Réception quasi instantanée : long-polling (le serveur répond dès qu'un message arrive) ;
  // « écrit… » / accusés / présence : état léger toutes les 1,5 s, indépendant du long-polling.
  bool _pollOn = false, _loopRunning = false;
  Timer? _stateTimer;

  void _startPolling() {
    _pollingTimer?.cancel();
    _stateTimer?.cancel();
    _pollOn = true;
    _stateTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) => _pollState());
    _pollLoop();
  }

  Future<void> _pollLoop() async {
    if (_loopRunning) return;
    _loopRunning = true;
    while (_pollOn) {
      final t0 = DateTime.now();
      try { await _pollMessages(); } catch (_) {}
      final el = DateTime.now().difference(t0).inMilliseconds;
      final gap = activeChannel.value != null ? 3000 : 350;
      if (el < gap) await Future.delayed(Duration(milliseconds: gap - el));
    }
    _loopRunning = false;
  }

  void _stopPolling() { _pollOn = false; _pollingTimer?.cancel(); _pollingTimer = null; _stateTimer?.cancel(); _stateTimer = null; }

  Future<void> _pollMessages() async {
    if (useMock) return;
    try {
      if (activeChannel.value != null) {
        final r = await RequestService().get('/social/channels/${activeChannel.value!.id}/messages');
        _mergeMessages(messages, (r.data['data'] as List).map((e) => ChatMessage.fromJson(e)).toList());
        onScrollToBottom?.call();
      } else if (activeConversation.value != null) {
        final cid = activeConversation.value!.id;
        // Delta : seulement les nouveaux messages (data minimale) ; refresh complet
        // toutes les ~10 passes pour répercuter suppressions / modérations.
        final lastId = privateMessages.where((m) => !m.isPending && m.id > 0).fold<int>(0, (a, m) => m.id > a ? m.id : a);
        final full = _pollTick++ % 10 == 0 || lastId == 0;
        final r = await RequestService().get('/social/conversations/$cid/messages', queryParameters: full ? null : {'after_id': lastId, 'wait': 3});
        final raw = (r.data['data'] as List);
        final fresh = raw.map((e) => ChatMessage.fromJson(e)).toList();
        if (full) {
          _mergeMessages(privateMessages, fresh);
          _saveMsgs(cid, raw);
        } else if (fresh.isNotEmpty) {
          final have = privateMessages.map((m) => m.id).toSet();
          privateMessages.addAll(fresh.where((m) => !have.contains(m.id)));
          _saveMsgs(cid, [..._cachedMsgs(cid), ...raw]);
          onScrollToBottom?.call();
          if (fresh.any((m) => !m.isMe)) _markRead();
        }
        _applyReceipts();
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

  /// "Mes canaux" — canaux déjà rejoints, triés par ordre de récence
  /// (dernier message reçu en premier), comme une messagerie classique.
  List<ChatChannel> get myChannelsSorted {
    final q = searchQuery.value.toLowerCase();
    var list = channels.where((c) => c.isJoined).toList();
    if (q.isNotEmpty) {
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              (c.description?.toLowerCase().contains(q) ?? false) ||
              c.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }
    list.sort((a, b) => compareByRecency(
          a.lastMessage?.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          b.lastMessage?.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        ));
    return list;
  }

  /// "À découvrir" — canaux non rejoints ET approuvés par un admin
  /// uniquement (un canal en attente de validation reste invisible pour
  /// tout le monde sauf son créateur, cf. isPending ci-dessous).
  List<ChatChannel> get discoverChannels {
    final q = searchQuery.value.toLowerCase();
    var list = channels
        .where((c) => !c.isJoined && (c.status == 'approved' || c.isMine))
        .toList();
    if (q.isNotEmpty) {
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              (c.description?.toLowerCase().contains(q) ?? false) ||
              c.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }
    return list;
  }

  /// Canaux créés par l'utilisateur encore en attente de validation admin
  /// (à afficher avec un badge "En attente" dans "Mes canaux").
  List<ChatChannel> get myPendingChannels =>
      channels.where((c) => c.isMine && c.isPending).toList();

  Future<void> joinChannel(ChatChannel channel) async {
    try {
      if (!useMock) await RequestService().post('/social/channels/${channel.id}/join');
      final i = channels.indexWhere((c) => c.id == channel.id);
      if (i != -1) channels[i] = channels[i].copyWith(isJoined: true);
      ToastHelper.showToast('Vous avez rejoint ${channel.name}', backgroundColor: Colors.green, textColor: Colors.white);
    } on DioException catch (e) { _dioErr(e); }
  }

  /// N'importe quel utilisateur peut créer son propre canal de discussion.
  /// Les tags thématiques sont désormais OBLIGATOIRES (au moins un), et si
  /// le créateur n'est pas admin, le canal part en statut "pending" : il
  /// reste invisible des autres jusqu'à validation par un administrateur.
  final isCreatingChannel = false.obs;

  Future<bool> createChannel(
    String name,
    String? description, {
    required List<String> tags,
  }) async {
    if (tags.isEmpty) {
      ToastHelper.showToast(
        'Ajoutez au moins un thème (tag) pour décrire votre canal.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }

    isCreatingChannel.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 500));
        await loadChannels();
        ToastHelper.showToast(
          myIsAdmin
              ? 'Canal créé avec succès.'
              : 'Canal créé — en attente de validation par un administrateur.',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        return true;
      }
      await RequestService().post('/social/channels', data: {
        'name': name,
        'tags': tags,
        if (description != null && description.isNotEmpty) 'description': description,
      });
      await loadChannels();
      ToastHelper.showToast(
        myIsAdmin
            ? 'Canal créé avec succès.'
            : 'Canal créé — en attente de validation par un administrateur.',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      return true;
    } on DioException catch (e) {
      _dioErr(e);
      return false;
    } finally {
      isCreatingChannel.value = false;
    }
  }

  /// Modification réservée au créateur du canal (ou à un admin, géré côté API).
  final isUpdatingChannel = false.obs;

  Future<bool> updateChannel(ChatChannel channel, {String? name, String? description}) async {
    isUpdatingChannel.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
        await loadChannels();
        return true;
      }
      await RequestService().put('/social/channels/${channel.id}', data: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (description != null) 'description': description,
      });
      await loadChannels();
      ToastHelper.showToast('Canal mis à jour', backgroundColor: Colors.green, textColor: Colors.white);
      return true;
    } on DioException catch (e) {
      _dioErr(e);
      return false;
    } finally {
      isUpdatingChannel.value = false;
    }
  }

  Future<bool> deleteChannel(ChatChannel channel) async {
    try {
      if (!useMock) await RequestService().delete('/social/channels/${channel.id}');
      channels.removeWhere((c) => c.id == channel.id);
      ToastHelper.showToast('Canal supprimé', backgroundColor: Colors.green, textColor: Colors.white);
      return true;
    } on DioException catch (e) {
      _dioErr(e);
      return false;
    }
  }

  Future<void> leaveChannel(ChatChannel channel) async {
    try {      if (!useMock) await RequestService().post('/social/channels/${channel.id}/leave');
      final i = channels.indexWhere((c) => c.id == channel.id);
      if (i != -1) channels[i] = channels[i].copyWith(isJoined: false);
      await loadChannels();
    } on DioException catch (e) { _dioErr(e); }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MUTE — mise en sourdine (pas de notif push) d'un canal ou d'une
  // conversation privée. Purement côté "volet social", comme demandé.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> toggleMuteChannel(ChatChannel channel) async {
    final newValue = !channel.isMuted;
    final i = channels.indexWhere((c) => c.id == channel.id);
    if (i != -1) channels[i] = channels[i].copyWith(isMuted: newValue);
    try {
      if (!useMock) {
        await RequestService().post(
          '/social/channels/${channel.id}/mute',
          data: {'muted': newValue},
        );
      }
      ToastHelper.showToast(
        newValue ? 'Notifications coupées pour ${channel.name}' : 'Notifications réactivées pour ${channel.name}',
        backgroundColor: Colors.black87,
        textColor: Colors.white,
      );
    } on DioException catch (e) {
      // Rollback en cas d'échec réseau.
      if (i != -1) channels[i] = channels[i].copyWith(isMuted: !newValue);
      _dioErr(e);
    }
  }

  Future<void> toggleMuteConversation(PrivateConversation conv) async {
    final newValue = !conv.isMuted;
    final i = privateConversations.indexWhere((c) => c.id == conv.id);
    if (i != -1) privateConversations[i] = privateConversations[i].copyWith(isMuted: newValue);
    try {
      if (!useMock) {
        await RequestService().post(
          '/social/conversations/${conv.id}/mute',
          data: {'muted': newValue},
        );
      }
      ToastHelper.showToast(
        newValue ? 'Notifications coupées' : 'Notifications réactivées',
        backgroundColor: Colors.black87,
        textColor: Colors.white,
      );
    } on DioException catch (e) {
      if (i != -1) privateConversations[i] = privateConversations[i].copyWith(isMuted: !newValue);
      _dioErr(e);
    }
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
  // DELETE MESSAGE (auteur du message — retrait pur et simple)
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
  // ADMIN DELETE MESSAGE — modération : le message N'EST PAS retiré de
  // l'historique, son contenu est remplacé par "Supprimé par
  // l'administration" (transparence pour les autres membres du canal).
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> adminDeleteMessage(ChatMessage msg) async {
    final i = messages.indexWhere((m) => m.id == msg.id);
    if (i != -1) messages[i] = messages[i].copyWith(isRemovedByAdmin: true);

    if (useMock || msg.id < 0) return;
    try {
      await RequestService().delete(
        '/social/messages/${msg.id}',
        data: {'moderation': true},
      );
    } on DioException catch (e) {
      if (i != -1) messages[i] = messages[i].copyWith(isRemovedByAdmin: false);
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
      // Cache : la liste s'affiche instantanément, puis se rafraîchit.
      final cachedList = _box.read('chat_convs');
      if (privateConversations.isEmpty && cachedList is List && cachedList.isNotEmpty) {
        privateConversations.value = cachedList.map((e) => PrivateConversation.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        isConvsLoading.value = false;
      }
      final r = await RequestService().get('/social/conversations');
      _box.write('chat_convs', r.data['data']);
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
        // 1) Affichage immédiat depuis le cache local, 2) puis mise à jour par delta.
        final cached = _cachedMsgs(conv.id);
        if (cached.isNotEmpty) {
          privateMessages.value = cached.map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          isMessagesLoading.value = false;
          onScrollToBottom?.call();
        }
        final lastCached = privateMessages.fold<int>(0, (a, m) => m.id > a ? m.id : a);
        final r = await RequestService().get('/social/conversations/${conv.id}/messages',
            queryParameters: lastCached > 0 ? {'after_id': lastCached} : null);
        final raw = (r.data['data'] as List);
        final fresh = raw.map((e) => ChatMessage.fromJson(e)).toList();
        if (lastCached > 0) {
          final have = privateMessages.map((m) => m.id).toSet();
          privateMessages.addAll(fresh.where((m) => !have.contains(m.id)));
          _saveMsgs(conv.id, [...cached, ...raw]);
        } else {
          privateMessages.value = fresh;
          _saveMsgs(conv.id, raw);
        }
        peerOnline.value = conv.otherIsOnline;
        await _pollState();
        _markRead(force: true);
      }
    } finally {
      isMessagesLoading.value = false;
      _startPolling();
      WidgetsBinding.instance.addPostFrameCallback((_) => onScrollToBottom?.call());
    }
  }

  Future<void> sendPrivateMessage(int convId, {BuildContext? context}) async {
    final text = messageCtrl.text.trim();
    final file = pendingFile.value;
    if (text.isEmpty && file == null) return;

    // Vérification OPTIMISTE du quota Crush avant même de tenter l'envoi —
    // évite un aller-retour réseau inutile quand on sait déjà que le quota
    // est épuisé. No-op tant que CrushQuotaService.isEnabled est false.
    final quota = CrushQuotaService.to;
    final conv = privateConversations.firstWhereOrNull((c) => c.id == convId);
    if (quota.isEnabled && (conv?.isCrushMatch ?? false) && !quota.status.value.canSendMessage) {
      if (context != null && context.mounted) {
        await showCrushPacksSheet(context);
      }
      return;
    }

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
      viewOnce: pendingViewOnce.value && file != null,
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
      pendingViewOnce.value = false;
      await RequestService().post('/social/conversations/$convId/messages', data: data);
      _confirmPending(privateMessages, tempId);
      // Message Crush envoyé avec succès : le quota a été décompté côté
      // serveur, on rafraîchit l'affichage local (no-op si désactivé).
      if (quota.isEnabled && (conv?.isCrushMatch ?? false)) {
        unawaited(quota.refreshQuota());
      }
    } on DioException catch (e) {
      _failPending(privateMessages, tempId);
      if (e.response?.statusCode == 402) {
        // Quota épuisé (détecté serveur, ex: appareil désynchronisé) :
        // on resynchronise le quota local puis on propose le paywall.
        unawaited(quota.refreshQuota());
        if (context != null && context.mounted) {
          showCrushPacksSheet(context);
          return;
        }
      }
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
  // ── Sondages ────────────────────────────────────────────────────────────────
  Future<bool> sendPoll(int convId, String question, List<String> options, {bool multiple = false}) async {
    try {
      final r = await RequestService().post('/social/conversations/$convId/poll', data: {
        'question': question, 'options': options, 'multiple': multiple,
      });
      privateMessages.add(ChatMessage.fromJson(Map<String, dynamic>.from(r.data['data'] as Map)));
      onScrollToBottom?.call();
      return true;
    } on DioException catch (e) { _dioErr(e); return false; }
  }

  Future<void> votePoll(ChatMessage m, List<int> picked) async {
    try {
      final r = await RequestService().post('/social/messages/${m.id}/vote', data: {'options': picked});
      final upd = ChatMessage.fromJson(Map<String, dynamic>.from(r.data['data'] as Map));
      final i = privateMessages.indexWhere((x) => x.id == m.id);
      if (i != -1) privateMessages[i] = privateMessages[i].copyWith(poll: upd.poll);
    } on DioException catch (e) { _dioErr(e); }
  }

  // ── Vue unique : le serveur ne sert le média qu'une fois ───────────────────
  Future<List<int>?> openViewOnce(ChatMessage m) async {
    try {
      final r = await RequestService().getBytes('/social/messages/${m.id}/view-once');
      final i = privateMessages.indexWhere((x) => x.id == m.id);
      if (i != -1) privateMessages[i] = privateMessages[i].copyWith(viewOnceOpened: true);
      return r.data;
    } on DioException catch (e) {
      final i = privateMessages.indexWhere((x) => x.id == m.id);
      if (i != -1 && e.response?.statusCode == 410) privateMessages[i] = privateMessages[i].copyWith(viewOnceOpened: true);
      ToastHelper.showToast(e.response?.statusCode == 410 ? 'Ce média a déjà été ouvert.' : 'Ouverture impossible.');
      return null;
    }
  }

  Future<bool> savePrivacy({bool? hideLastSeen, bool? hideReadReceipts}) async {
    try {
      await RequestService().put('/social/privacy', data: {
        if (hideLastSeen != null) 'hide_last_seen': hideLastSeen,
        if (hideReadReceipts != null) 'hide_read_receipts': hideReadReceipts,
      });
      return true;
    } catch (_) { return false; }
  }

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

  void clearPendingFile() { pendingFile.value = null; pendingFileType.value = null; pendingViewOnce.value = false; }

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
      if (pendingViewOnce.value && (type == MessageType.image || type == MessageType.video)) 'view_once': 1,
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

  // Factorisé : voir lib/app/utils/api_error_helper.dart. Corrige entre
  // autres l'affichage brut "Erreur 401" -> "Vous êtes déconnecté".
  void _dioErr(DioException e) => ApiErrorHelper.showError(e);

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