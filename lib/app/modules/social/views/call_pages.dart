import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/services/call_service.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

Widget _avatar(CallInfo c) => CircleAvatar(
      radius: 64,
      backgroundColor: Colors.white12,
      backgroundImage: c.otherAvatar != null ? NetworkImage(c.otherAvatar!) : null,
      child: c.otherAvatar == null
          ? Text(c.otherName.isEmpty ? '?' : c.otherName[0].toUpperCase(), style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.w800))
          : null,
    );

Widget _round(IconData i, Color bg, VoidCallback onTap, String label) => Column(mainAxisSize: MainAxisSize.min, children: [
      InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: CircleAvatar(radius: 32, backgroundColor: bg, child: Icon(i, color: Colors.white, size: 30)),
      ),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);

const _bg = BoxDecoration(
  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF141E30), Color(0xFF0B0F18)]),
);

/// Appel sortant : sonnerie côté appelé, attente de réponse (45 s max).
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
    _t = Timer.periodic(const Duration(seconds: 2), (_) => _tick());
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
              const Spacer(),
              _avatar(c),
              const SizedBox(height: 20),
              Text(c.otherName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(c.isVideo ? 'Appel vidéo… ça sonne' : 'Appel vocal… ça sonne', style: const TextStyle(color: Colors.white60)),
              const Spacer(),
              _round(Icons.call_end_rounded, Colors.red, () async {
                _t?.cancel();
                await CallService.to.decline(c);
                Get.back();
              }, 'Annuler'),
              const SizedBox(height: 48),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Appel entrant : accepter / refuser, ferme tout seul si l'appelant raccroche.
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
              const Spacer(),
              _avatar(c),
              const SizedBox(height: 20),
              Text(c.otherName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(c.isVideo ? 'Appel vidéo entrant' : 'Appel vocal entrant', style: TextStyle(color: GPTheme.primaryColor == Colors.white ? Colors.white60 : Colors.white60)),
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _round(Icons.call_end_rounded, Colors.red, () async {
                  await CallService.to.decline(c);
                  if (mounted) Get.back();
                }, 'Refuser'),
                _round(c.isVideo ? Icons.videocam_rounded : Icons.call_rounded, Colors.green, _accept, 'Répondre'),
              ]),
              const SizedBox(height: 48),
            ]),
          ),
        ),
      ),
    );
  }
}
