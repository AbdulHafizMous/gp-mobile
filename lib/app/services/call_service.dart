// Appels vocaux / vidéo de la messagerie — WebRTC pair-à-pair.
// - Sonnerie : push FCM + polling 4 s de /social/calls/incoming (app ouverte).
// - Signalisation (offre / réponse / ICE) : API Laravel en long-polling.
// - Média : flutter_webrtc (STUN public ; TURN configurable côté serveur pour les réseaux mobiles stricts).
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/social/views/call_pages.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

class CallInfo {
  final int id, conversationId;
  final String type, status, room, otherName;
  final String? otherAvatar;
  final bool isCaller;
  final List<Map<String, dynamic>> iceServers;
  final bool group;
  final int myJoinedAt;
  final List<Map<String, dynamic>> participants;
  CallInfo.fromJson(Map<String, dynamic> j)
      : id = int.tryParse('${j['id']}') ?? 0,
        conversationId = int.tryParse('${j['conversation_id']}') ?? 0,
        type = j['type']?.toString() ?? 'audio',
        status = j['status']?.toString() ?? 'ringing',
        room = j['room']?.toString() ?? '',
        otherName = j['other_user_name']?.toString() ?? '',
        otherAvatar = j['other_user_avatar']?.toString(),
        isCaller = j['is_caller'] == true,
        group = j['group'] == true,
        myJoinedAt = int.tryParse('${j['my_joined_at']}') ?? 0,
        participants = ((j['participants'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        iceServers = ((j['ice_servers'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
  bool get isVideo => type == 'video';
}

/// Un participant distant : sa connexion WebRTC + son flux vidéo.
class CallPeer {
  final int userId;
  String name;
  String? avatar;
  RTCPeerConnection? pc;
  final renderer = RTCVideoRenderer();
  final connected = false.obs;
  bool remoteSet = false;
  final List<RTCIceCandidate> pending = [];
  CallPeer(this.userId, this.name, this.avatar);
}

/// Une session d'appel en cours — 1-à-1 ou à plusieurs (maillage pair-à-pair, 4 personnes max).
/// Règle d'établissement : celui qui rejoint en dernier envoie l'offre à chaque participant déjà présent.
class CallSession extends GetxController {
  final CallInfo call;
  CallSession(this.call);

  final int me = activeUser.value.id;
  MediaStream? _local;
  final localR = RTCVideoRenderer();
  final Map<int, CallPeer> _peers = {};
  final tiles = <CallPeer>[].obs; // pairs connectés / en cours de connexion (vue)
  final roster = <Map<String, dynamic>>[].obs; // participants du serveur (inclut ceux qui sonnent)
  final state = 'Connexion…'.obs;
  final connected = false.obs;
  final muted = false.obs;
  final speaker = false.obs;
  final camOn = true.obs;
  final seconds = 0.obs;
  final ended = false.obs;
  Timer? _clock;
  int _lastSig = 0, _myJoinedAt = 0;
  // ignore: unused_field
  bool _closed = false, _hadPeers = false;

  bool get video => call.isVideo;

  Future<void> start() async {
    await localR.initialize();
    _myJoinedAt = call.myJoinedAt;
    speaker.value = video;
    try {
      _local = await navigator.mediaDevices.getUserMedia({
        'audio': {'echoCancellation': true, 'noiseSuppression': true, 'autoGainControl': true},
        'video': video ? {'facingMode': 'user', 'width': 640, 'height': 480, 'frameRate': 24} : false,
      });
    } catch (_) {
      state.value = 'Micro / caméra refusés';
      await hangup();
      return;
    }
    localR.srcObject = _local;
    await Helper.setSpeakerphoneOn(speaker.value);
    _loop();
  }

  Future<CallPeer> _ensurePeer(int uid) async {
    final existing = _peers[uid];
    if (existing != null) return existing;
    Map<String, dynamic>? info;
    for (final p in roster) {
      if (p['user_id'] == uid) info = p;
    }
    final peer = CallPeer(uid, info?['name']?.toString() ?? 'Participant', info?['avatar']?.toString());
    _peers[uid] = peer;
    await peer.renderer.initialize();
    final pc = await createPeerConnection({'iceServers': call.iceServers, 'sdpSemantics': 'unified-plan'});
    peer.pc = pc;
    for (final t in _local!.getTracks()) {
      await pc.addTrack(t, _local!);
    }
    pc.onIceCandidate = (c) {
      if (c.candidate != null) _signal('ice', {'candidate': c.candidate, 'sdpMid': c.sdpMid, 'sdpMLineIndex': c.sdpMLineIndex}, to: uid);
    };
    pc.onTrack = (e) {
      if (e.streams.isNotEmpty) peer.renderer.srcObject = e.streams.first;
    };
    pc.onConnectionState = (st) {
      if (st == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        peer.connected.value = true;
        _onConnected();
      } else if (st == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        state.value = 'Connexion impossible (réseau)';
      }
    };
    tiles.add(peer);
    _hadPeers = true;
    return peer;
  }

  Future<void> _offerTo(int uid) async {
    final peer = await _ensurePeer(uid);
    final offer = await peer.pc!.createOffer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': video ? 1 : 0});
    await peer.pc!.setLocalDescription(offer);
    await _signal('offer', {'sdp': offer.sdp, 'type': offer.type}, to: uid);
  }

  void _onConnected() {
    if (connected.value) return;
    connected.value = true;
    state.value = '';
    HapticFeedback.mediumImpact();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => seconds.value++);
  }

  Future<void> _signal(String type, dynamic data, {int? to}) async {
    try {
      await RequestService().post('/social/calls/${call.id}/signal', data: {'type': type, 'data': data, if (to != null) 'to': to});
    } catch (_) {}
  }

  Future<void> _loop() async {
    while (!_closed) {
      try {
        final r = await RequestService().get('/social/calls/${call.id}/signals', queryParameters: {'after': _lastSig, 'wait': 2});
        final d = r.data['data'] as Map;
        final parts = (d['participants'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        roster.assignAll(parts);
        final mj = int.tryParse('${d['my_joined_at']}') ?? 0;
        if (mj > 0) _myJoinedAt = mj;
        for (final s in (d['signals'] as List)) {
          final m = Map<String, dynamic>.from(s as Map);
          final id = (m['id'] as num).toInt();
          if (id > _lastSig) _lastSig = id;
          await _handle((m['from'] as num).toInt(), m['type'].toString(), m['data']);
        }
        await _reconcile(parts);
        if (d['status'] != 'accepted') {
          _finish();
          return;
        }
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }
  }

  /// Aligne les connexions sur la liste des participants : offre aux plus anciens, nettoyage des partis.
  Future<void> _reconcile(List<Map<String, dynamic>> parts) async {
    final joined = parts.where((p) => p['status'] == 'joined' && p['user_id'] != me).toList();
    for (final p in joined) {
      final uid = (p['user_id'] as num).toInt();
      final theirs = int.tryParse('${p['joined_at']}') ?? 0;
      final mineFirst = _myJoinedAt > 0 && (_myJoinedAt < theirs || (_myJoinedAt == theirs && me < uid));
      if (!_peers.containsKey(uid) && !mineFirst) await _offerTo(uid); // je suis arrivé après : j'offre
      final pe = _peers[uid];
      if (pe != null) {
        pe.name = p['name']?.toString() ?? pe.name;
        pe.avatar = p['avatar']?.toString() ?? pe.avatar;
      }
    }
    final ids = joined.map((p) => (p['user_id'] as num).toInt()).toSet();
    for (final uid in _peers.keys.toList()) {
      if (!ids.contains(uid)) await _removePeer(uid);
    }
  }

  Future<void> _handle(int from, String type, dynamic data) async {
    if (_local == null) return;
    final map = data is String ? jsonDecode(data) : data;
    if (type == 'bye') {
      await _removePeer(from);
      return;
    }
    final peer = await _ensurePeer(from);
    final pc = peer.pc!;
    if (type == 'offer') {
      await pc.setRemoteDescription(RTCSessionDescription(map['sdp'], map['type']));
      peer.remoteSet = true;
      final ans = await pc.createAnswer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': video ? 1 : 0});
      await pc.setLocalDescription(ans);
      await _signal('answer', {'sdp': ans.sdp, 'type': ans.type}, to: from);
      await _flushIce(peer);
    } else if (type == 'answer') {
      await pc.setRemoteDescription(RTCSessionDescription(map['sdp'], map['type']));
      peer.remoteSet = true;
      await _flushIce(peer);
    } else if (type == 'ice') {
      final c = RTCIceCandidate(map['candidate'], map['sdpMid'], map['sdpMLineIndex']);
      peer.remoteSet ? await pc.addCandidate(c) : peer.pending.add(c);
    }
  }

  Future<void> _flushIce(CallPeer p) async {
    for (final c in p.pending) {
      await p.pc?.addCandidate(c);
    }
    p.pending.clear();
  }

  Future<void> _removePeer(int uid) async {
    final p = _peers.remove(uid);
    if (p == null) return;
    tiles.remove(p);
    p.renderer.srcObject = null;
    try { await p.pc?.close(); } catch (_) {}
    await p.renderer.dispose();
    if (_peers.values.every((x) => !x.connected.value)) {
      connected.value = _peers.isNotEmpty ? connected.value : false;
    }
  }

  // ── Commandes ───────────────────────────────────────────────────────────────
  void toggleMute() {
    muted.value = !muted.value;
    for (final t in _local?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      t.enabled = !muted.value;
    }
  }

  Future<void> toggleSpeaker() async {
    speaker.value = !speaker.value;
    await Helper.setSpeakerphoneOn(speaker.value);
  }

  void toggleCam() {
    camOn.value = !camOn.value;
    for (final t in _local?.getVideoTracks() ?? <MediaStreamTrack>[]) {
      t.enabled = camOn.value;
    }
  }

  Future<void> switchCamera() async {
    final t = _local?.getVideoTracks();
    if (t != null && t.isNotEmpty) await Helper.switchCamera(t.first);
  }

  /// Ajoute quelqu'un à l'appel (renvoie un message d'erreur éventuel).
  Future<String?> invite(int userId) async {
    try {
      final r = await RequestService().post('/social/calls/${call.id}/invite', data: {'user_id': userId});
      final d = r.data['data'];
      if (d is Map && d['participants'] is List) {
        roster.assignAll((d['participants'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
      return null;
    } catch (e) {
      try {
        final resp = (e as dynamic).response;
        return resp?.data?['message']?.toString() ?? "Impossible d'ajouter cette personne.";
      } catch (_) {
        return "Impossible d'ajouter cette personne.";
      }
    }
  }

  Future<void> hangup() async {
    if (_closed) return;
    await _signal('bye', null);
    try { await RequestService().post('/social/calls/${call.id}/end'); } catch (_) {}
    _finish();
  }

  void _finish() {
    if (_closed) return;
    _closed = true;
    _clock?.cancel();
    ended.value = true;
    for (final t in _local?.getTracks() ?? <MediaStreamTrack>[]) {
      t.stop();
    }
    _local?.dispose();
    for (final p in _peers.values) {
      p.renderer.srcObject = null;
      p.pc?.close();
      p.renderer.dispose();
    }
    _peers.clear();
    tiles.clear();
    localR.srcObject = null;
  }

  @override
  void onClose() {
    _finish();
    localR.dispose();
    super.onClose();
  }
}

class CallService extends GetxService with WidgetsBindingObserver {
  static CallService get to => Get.find();

  Timer? _poll;
  bool _busy = false; // un écran d'appel est déjà affiché
  bool _foreground = true;

  Future<CallService> init() async {
    WidgetsBinding.instance.addObserver(this);
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _checkIncoming());
    return this;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    _foreground = s == AppLifecycleState.resumed;
    if (_foreground) _checkIncoming();
  }

  @override
  void onClose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  Future<void> _checkIncoming() async {
    if (_busy || !_foreground || GetStorage().read('token') == null) return;
    try {
      final r = await RequestService().get('/social/calls/incoming');
      final d = r.data['data'];
      if (d is Map && !_busy) {
        _busy = true;
        await Get.to(() => IncomingCallPage(call: CallInfo.fromJson(Map<String, dynamic>.from(d))), fullscreenDialog: true);
        _busy = false;
      }
    } catch (_) {}
  }

  /// Lance un appel sortant depuis une discussion privée.
  Future<void> startCall(int conversationId, {required bool video}) async {
    if (_busy) return;
    try {
      final r = await RequestService().post('/social/conversations/$conversationId/call', data: {'type': video ? 'video' : 'audio'});
      final call = CallInfo.fromJson(Map<String, dynamic>.from(r.data['data'] as Map));
      _busy = true;
      await Get.to(() => OutgoingCallPage(call: call), fullscreenDialog: true);
      _busy = false;
    } catch (e) {
      Get.snackbar('', 'Appel impossible : la personne est déjà en appel ou injoignable.', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
    }
  }

  Future<CallInfo?> fetch(int id) async {
    try {
      final r = await RequestService().get('/social/calls/$id');
      return CallInfo.fromJson(Map<String, dynamic>.from(r.data['data'] as Map));
    } catch (_) {
      return null;
    }
  }

  Future<CallInfo?> answer(CallInfo c) async {
    try {
      final r = await RequestService().post('/social/calls/${c.id}/answer');
      return CallInfo.fromJson(Map<String, dynamic>.from(r.data['data'] as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> decline(CallInfo c) async {
    try { await RequestService().post('/social/calls/${c.id}/decline'); } catch (_) {}
  }

  /// Ouvre l'écran d'appel (une fois l'appel accepté) et attend sa fin.
  Future<void> join(CallInfo c) async {
    final s = Get.put(CallSession(c), tag: 'call${c.id}');
    await Get.to(() => InCallPage(session: s), fullscreenDialog: true);
    Get.delete<CallSession>(tag: 'call${c.id}');
  }
}

/// Vibration de sonnerie (boucle) pendant un appel entrant.
class Ringer {
  Timer? _t;
  void start() {
    HapticFeedback.heavyImpact();
    _t = Timer.periodic(const Duration(milliseconds: 1500), (_) => HapticFeedback.heavyImpact());
  }

  void stop() => _t?.cancel();
}
