import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/services/call_service.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

const _bg = BoxDecoration(
  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1B2735), Color(0xFF090A0F)]),
);

String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

/// Avatar avec ondes pulsées (sonnerie / connexion).
class _PulseAvatar extends StatefulWidget {
  final CallInfo call;
  final bool pulse;
  const _PulseAvatar({required this.call, this.pulse = true});
  @override
  State<_PulseAvatar> createState() => _PulseAvatarState();
}

class _PulseAvatarState extends State<_PulseAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.call;
    return SizedBox(
      width: 220,
      height: 220,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(alignment: Alignment.center, children: [
          if (widget.pulse)
            for (final o in [0.0, 0.5])
              Container(
                width: 120 + 100 * ((_c.value + o) % 1),
                height: 120 + 100 * ((_c.value + o) % 1),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12 * (1 - ((_c.value + o) % 1)))),
              ),
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white12,
            backgroundImage: c.otherAvatar != null ? NetworkImage(c.otherAvatar!) : null,
            child: c.otherAvatar == null
                ? Text(c.otherName.isEmpty ? '?' : c.otherName[0].toUpperCase(), style: const TextStyle(fontSize: 46, color: Colors.white, fontWeight: FontWeight.w800))
                : null,
          ),
        ]),
      ),
    );
  }
}

Widget _round(IconData i, Color bg, VoidCallback onTap, {String? label, Color fg = Colors.white, double size = 62}) => Column(mainAxisSize: MainAxisSize.min, children: [
      Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: size, height: size, child: Icon(i, color: fg, size: size * 0.46)),
        ),
      ),
      if (label != null) ...[const SizedBox(height: 6), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5))],
    ]);

/// Appel sortant : ça sonne chez l'autre (45 s max).
class OutgoingCallPage extends StatefulWidget {
  final CallInfo call;
  const OutgoingCallPage({super.key, required this.call});
  @override
  State<OutgoingCallPage> createState() => _OutgoingCallPageState();
}

class _OutgoingCallPageState extends State<OutgoingCallPage> {
  Timer? _t;
  bool _joined = false;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 1200), (_) => _tick());
  }

  Future<void> _tick() async {
    if (_joined) return;
    final c = await CallService.to.fetch(widget.call.id);
    if (c == null || !mounted) return;
    if (c.status == 'accepted') {
      _joined = true;
      _t?.cancel();
      await CallService.to.join(c);
      if (mounted) Get.back();
    } else if (c.status != 'ringing') {
      _t?.cancel();
      Get.back();
      Get.snackbar('', c.status == 'declined' ? 'Appel refusé.' : 'Pas de réponse.', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.call;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: _bg,
          width: double.infinity,
          child: SafeArea(
            child: Column(children: [
              const SizedBox(height: 40),
              Text(c.isVideo ? 'Appel vidéo' : 'Appel vocal', style: const TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 8),
              Text(c.otherName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Ça sonne…', style: TextStyle(color: Colors.white60)),
              const Spacer(),
              _PulseAvatar(call: c),
              const Spacer(),
              _round(Icons.call_end_rounded, Colors.red, () async {
                _t?.cancel();
                await CallService.to.decline(c);
                Get.back();
              }, label: 'Annuler'),
              const SizedBox(height: 44),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Appel entrant : répondre / refuser ; se ferme si l'appelant raccroche.
class IncomingCallPage extends StatefulWidget {
  final CallInfo call;
  const IncomingCallPage({super.key, required this.call});
  @override
  State<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage> {
  Timer? _t;
  final _ringer = Ringer();
  bool _answering = false;

  @override
  void initState() {
    super.initState();
    _ringer.start();
    _t = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_answering) return;
      final c = await CallService.to.fetch(widget.call.id);
      if (c != null && c.status != 'ringing' && mounted) Get.back();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _ringer.stop();
    super.dispose();
  }

  Future<void> _accept() async {
    _answering = true;
    _ringer.stop();
    final c = await CallService.to.answer(widget.call);
    if (c == null) {
      if (mounted) Get.back();
      return;
    }
    await CallService.to.join(c);
    if (mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.call;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: _bg,
          width: double.infinity,
          child: SafeArea(
            child: Column(children: [
              const SizedBox(height: 40),
              Text(c.group ? 'Vous êtes ajouté(e) à un appel' : (c.isVideo ? 'Appel vidéo entrant' : 'Appel vocal entrant'), style: const TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 8),
              Text(c.otherName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              const Spacer(),
              _PulseAvatar(call: c),
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _round(Icons.call_end_rounded, Colors.red, () async {
                  await CallService.to.decline(c);
                  if (mounted) Get.back();
                }, label: 'Refuser', size: 70),
                _round(c.isVideo ? Icons.videocam_rounded : Icons.call_rounded, const Color(0xFF22C55E), _accept, label: 'Répondre', size: 70),
              ]),
              const SizedBox(height: 56),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Appel en cours : audio (avatars) ou vidéo (grille), jusqu'à 4 personnes, avec « Ajouter ».
class InCallPage extends StatefulWidget {
  final CallSession session;
  const InCallPage({super.key, required this.session});
  @override
  State<InCallPage> createState() => _InCallPageState();
}

class _InCallPageState extends State<InCallPage> {
  Worker? _w;
  CallSession get s => widget.session;

  @override
  void initState() {
    super.initState();
    _w = ever(s.ended, (e) {
      if (e == true && mounted) Get.back();
    });
    s.start();
  }

  @override
  void dispose() {
    _w?.dispose();
    super.dispose();
  }

  Widget _avatarTile(String name, String? avatar, {bool ringing = false, bool live = false, double r = 44}) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: live ? const Color(0xFF22C55E) : Colors.white24, width: 2.5)),
          child: CircleAvatar(
            radius: r,
            backgroundColor: Colors.white12,
            backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar == null || avatar.isEmpty ? Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: TextStyle(fontSize: r * .8, color: Colors.white, fontWeight: FontWeight.w800)) : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(ringing ? '$name · sonnerie…' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ]);

  /// Zone centrale : vidéos (grille) ou avatars selon le type d'appel.
  Widget _stage() {
    final tiles = s.tiles.toList();
    final ringing = s.roster.where((p) => p['status'] == 'invited' && p['user_id'] != s.me).toList();
    if (s.video && tiles.isNotEmpty) {
      if (tiles.length == 1 && ringing.isEmpty) {
        return Positioned.fill(child: RTCVideoView(tiles.first.renderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover));
      }
      final cols = tiles.length + ringing.length <= 2 ? 1 : 2;
      return Positioned.fill(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 110, 6, 190),
          child: GridView.count(
            crossAxisCount: cols,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: cols == 1 ? 1.5 : 0.78,
            children: [
              for (final t in tiles)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(fit: StackFit.expand, children: [
                    RTCVideoView(t.renderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                    Positioned(left: 8, bottom: 6, child: Text(t.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, shadows: [Shadow(blurRadius: 6, color: Colors.black)]))),
                  ]),
                ),
              for (final p in ringing) Center(child: _avatarTile(p['name']?.toString() ?? '', p['avatar']?.toString(), ringing: true, r: 36)),
            ],
          ),
        ),
      );
    }
    // Audio (ou vidéo en attente de connexion) : avatars des participants.
    final others = s.roster.where((p) => p['user_id'] != s.me).toList();
    if (others.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.only(bottom: 60), child: _PulseAvatar(call: s.call, pulse: !s.connected.value)));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Wrap(
          spacing: 22,
          runSpacing: 22,
          alignment: WrapAlignment.center,
          children: [
            for (final p in others)
              _avatarTile(
                p['name']?.toString() ?? '',
                p['avatar']?.toString(),
                ringing: p['status'] == 'invited',
                live: tiles.any((t) => t.userId == p['user_id'] && t.connected.value),
                r: others.length == 1 ? 60 : 40,
              ),
          ],
        ),
      ),
    );
  }

  String get _title {
    final others = s.roster.where((p) => p['user_id'] != s.me).toList();
    if (others.length > 1) return 'Appel de groupe · ${others.length + 1}';
    return others.isNotEmpty ? (others.first['name']?.toString() ?? s.call.otherName) : s.call.otherName;
  }

  void _addPeople() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPeopleSheet(session: s),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Obx(() {
          final showLocal = s.video && s.camOn.value;
          s.roster.length; // dépendance réactive
          return Stack(children: [
            Container(decoration: _bg, width: double.infinity, height: double.infinity),
            _stage(),
            if (s.video && s.tiles.length == 1) Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black54, Colors.transparent, Colors.black54])))) ),
            SafeArea(
              child: Column(children: [
                const SizedBox(height: 24),
                Text(_title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(s.connected.value ? _fmt(s.seconds.value) : s.state.value, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 12,
                    children: [
                      _round(s.muted.value ? Icons.mic_off_rounded : Icons.mic_rounded, s.muted.value ? Colors.white : Colors.white24, s.toggleMute, fg: s.muted.value ? Colors.black : Colors.white, label: s.muted.value ? 'Muet' : 'Micro', size: 54),
                      _round(s.speaker.value ? Icons.volume_up_rounded : Icons.phone_in_talk_rounded, s.speaker.value ? Colors.white : Colors.white24, s.toggleSpeaker, fg: s.speaker.value ? Colors.black : Colors.white, label: 'Haut-parleur', size: 54),
                      if (s.video) _round(s.camOn.value ? Icons.videocam_rounded : Icons.videocam_off_rounded, s.camOn.value ? Colors.white24 : Colors.white, s.toggleCam, fg: s.camOn.value ? Colors.white : Colors.black, label: 'Caméra', size: 54),
                      if (s.video) _round(Icons.cameraswitch_rounded, Colors.white24, s.switchCamera, label: 'Retourner', size: 54),
                      _round(Icons.person_add_alt_1_rounded, Colors.white24, _addPeople, label: 'Ajouter', size: 54),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _round(Icons.call_end_rounded, Colors.red, s.hangup, size: 70),
                const SizedBox(height: 32),
              ]),
            ),
            if (showLocal)
              Positioned(
                right: 12,
                top: 96,
                width: 96,
                height: 136,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(border: Border.all(color: Colors.white30, width: 1.5), borderRadius: BorderRadius.circular(16)),
                    child: RTCVideoView(s.localR, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                  ),
                ),
              ),
          ]);
        }),
      ),
    );
  }
}

/// Sélecteur « ajouter à l'appel » (recherche d'utilisateurs, 4 personnes maximum).
class _AddPeopleSheet extends StatefulWidget {
  final CallSession session;
  const _AddPeopleSheet({required this.session});
  @override
  State<_AddPeopleSheet> createState() => _AddPeopleSheetState();
}

class _AddPeopleSheetState extends State<_AddPeopleSheet> {
  final _q = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  Timer? _deb;
  final Set<int> _sent = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _deb?.cancel();
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await RequestService().get('/social/users', queryParameters: {if (_q.text.trim().isNotEmpty) 'search': _q.text.trim()});
      _users = (r.data['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      _users = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  bool _inCall(int id) => widget.session.roster.any((p) => p['user_id'] == id) || _sent.contains(id);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).viewInsets.bottom + 12),
      decoration: BoxDecoration(color: dark ? const Color(0xFF1A1A1A) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: .4), borderRadius: BorderRadius.circular(4)))),
        const SizedBox(height: 12),
        const Text('Ajouter à l\'appel', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 10),
        TextField(
          controller: _q,
          onChanged: (_) {
            _deb?.cancel();
            _deb = Timer(const Duration(milliseconds: 350), _load);
          },
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: 'Rechercher une personne', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: GPTheme.primaryColor))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final u = _users[i];
                    final id = (u['id'] as num).toInt();
                    final done = _inCall(id);
                    final av = u['avatar_url']?.toString();
                    return ListTile(
                      leading: CircleAvatar(backgroundImage: av != null && av.isNotEmpty ? NetworkImage(av) : null, child: av == null || av.isEmpty ? Text((u['name'] ?? '?').toString()[0].toUpperCase()) : null),
                      title: Text(u['name']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(u['city']?.toString() ?? '', maxLines: 1),
                      trailing: done
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E))
                          : IconButton(
                              icon: Icon(Icons.person_add_alt_1_rounded, color: GPTheme.primaryColor),
                              onPressed: () async {
                                final err = await widget.session.invite(id);
                                if (err != null) {
                                  Get.snackbar('', err, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
                                } else {
                                  setState(() => _sent.add(id));
                                }
                              },
                            ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
