// Appels vocaux / vidéo de la messagerie.
// - Signalisation : API Laravel (sonnerie push FCM + polling 4 s tant que l'app est ouverte).
// - Média : salle Jitsi (SDK natif) — fiable sur réseaux mobiles (TURN inclus).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/social/views/call_pages.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class CallInfo {
  final int id, conversationId;
  final String type, status, room, serverUrl, otherName;
  final String? otherAvatar;
  final bool isCaller;
  CallInfo.fromJson(Map<String, dynamic> j)
      : id = int.tryParse('${j['id']}') ?? 0,
        conversationId = int.tryParse('${j['conversation_id']}') ?? 0,
        type = j['type']?.toString() ?? 'audio',
        status = j['status']?.toString() ?? 'ringing',
        room = j['room']?.toString() ?? '',
        serverUrl = j['server_url']?.toString() ?? 'https://meet.jit.si',
        otherName = j['other_user_name']?.toString() ?? '',
        otherAvatar = j['other_user_avatar']?.toString(),
        isCaller = j['is_caller'] == true;
  bool get isVideo => type == 'video';
}

class CallService extends GetxService with WidgetsBindingObserver {
  static CallService get to => Get.find();

  Timer? _poll;
  bool _busy = false; // un écran d'appel est déjà affiché / appel en cours
  bool _foreground = true;
  final _jitsi = JitsiMeet();

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

  // Les permissions micro/caméra sont demandées par le SDK Jitsi (Android) / le système (iOS) au join.
  Future<bool> _perms(bool video) async => true;

  /// Lance un appel sortant depuis une discussion privée.
  Future<void> startCall(int conversationId, {required bool video}) async {
    if (_busy) return;
    if (!await _perms(video)) {
      Get.snackbar('', 'Autorisez le micro${video ? ' et la caméra' : ''} pour appeler.', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
      return;
    }
    try {
      final r = await RequestService().post('/social/conversations/$conversationId/call', data: {'type': video ? 'video' : 'audio'});
      final call = CallInfo.fromJson(Map<String, dynamic>.from(r.data['data'] as Map));
      _busy = true;
      await Get.to(() => OutgoingCallPage(call: call), fullscreenDialog: true);
      _busy = false;
    } catch (e) {
      Get.snackbar('', 'Appel impossible (déjà en appel ou réseau).', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
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
    if (!await _perms(c.isVideo)) {
      await decline(c);
      return null;
    }
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

  /// Rejoint la salle ; à la fin de la conférence, clôt l'appel côté serveur.
  Future<void> join(CallInfo c) async {
    final completer = Completer<void>();
    final options = JitsiMeetConferenceOptions(
      serverURL: c.serverUrl,
      room: c.room,
      configOverrides: {
        'startWithAudioMuted': false,
        'startWithVideoMuted': !c.isVideo,
        'startAudioOnly': !c.isVideo,
        'prejoinConfig.enabled': false,
        'disableDeepLinking': true,
      },
      featureFlags: {
        'welcomepage.enabled': false,
        'invite.enabled': false,
        'add-people.enabled': false,
        'chat.enabled': false,
        'meeting-name.enabled': false,
        'call-integration.enabled': false,
        'recording.enabled': false,
        'live-streaming.enabled': false,
        'pip.enabled': true,
      },
      userInfo: JitsiMeetUserInfo(displayName: activeUser.value.name),
    );
    await _jitsi.join(
      options,
      JitsiMeetEventListener(
        conferenceTerminated: (url, error) {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    await completer.future;
    try { await RequestService().post('/social/calls/${c.id}/end'); } catch (_) {}
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
