// Messagerie : sondages, médias à vue unique (anti-capture), thème & fond
// d'écran (stockés sur l'appareil) et réglages de confidentialité.
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/chat_models.dart';
import 'package:grand_public_v2/app/modules/social/controllers/chat_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:video_player/video_player.dart';

// ═════════════════════════════════════════════════════════════════════════════
// THÈME & FOND D'ÉCRAN
// ═════════════════════════════════════════════════════════════════════════════
const Map<String, List<Color>> kChatWallpapers = {
  'ocean': [Color(0xFF0F2027), Color(0xFF2C5364)],
  'sunset': [Color(0xFFFF9966), Color(0xFFFF5E62)],
  'forest': [Color(0xFF134E5E), Color(0xFF71B280)],
  'night': [Color(0xFF141E30), Color(0xFF243B55)],
  'rose': [Color(0xFFFFAFBD), Color(0xFFFFC3A0)],
  'sand': [Color(0xFFEDE5D0), Color(0xFFD9C9A3)],
  'violet': [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
};

const List<Color> kChatAccents = [
  Color(0xFFEB2040), Color(0xFF1E88E5), Color(0xFF00A884), Color(0xFF8E24AA),
  Color(0xFFFB8C00), Color(0xFF3949AB), Color(0xFF546E7A), Color(0xFFD81B60),
];

/// Décoration de fond de la discussion (assombrie en mode sombre pour la lisibilité).
Decoration? chatWallpaperDecoration(String key, bool dark) {
  if (key == 'none' || key.isEmpty) return null;
  final overlay = dark ? Colors.black.withValues(alpha: 0.45) : null;
  if (key.startsWith('file:')) {
    final f = File(key.substring(5));
    if (!f.existsSync()) return null;
    return BoxDecoration(
      image: DecorationImage(
        image: FileImage(f),
        fit: BoxFit.cover,
        colorFilter: overlay != null ? ColorFilter.mode(overlay, BlendMode.darken) : null,
      ),
    );
  }
  final c = kChatWallpapers[key];
  if (c == null) return null;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [for (final x in c) dark ? Color.alphaBlend(Colors.black.withValues(alpha: .35), x) : x],
    ),
  );
}

Future<void> showChatThemeSheet(BuildContext context, ChatController c) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ThemeSheet(c: c),
  );
}

class _ThemeSheet extends StatelessWidget {
  final ChatController c;
  const _ThemeSheet({required this.c});

  Future<void> _pickOwn() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
    if (x == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dest = '${dir.path}/chat_wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(x.path).copy(dest);
    c.wallpaper.value = 'file:$dest';
    c.saveTheme();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(18, 14, 18, MediaQuery.of(context).padding.bottom + 18),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Obx(() {
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: .4), borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 14),
            const Text('Couleur de mes bulles', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final a in kChatAccents)
                GestureDetector(
                  onTap: () {
                    c.myBubbleColor.value = a;
                    c.saveTheme();
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: a,
                    child: c.myBubbleColor.value == a ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                ),
              GestureDetector(
                onTap: () {
                  c.myBubbleColor.value = null;
                  c.saveTheme();
                },
                child: CircleAvatar(radius: 18, backgroundColor: Colors.grey.withValues(alpha: .25), child: const Icon(Icons.restart_alt_rounded, size: 18)),
              ),
            ]),
            const SizedBox(height: 18),
            const Text('Fond d\'écran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 10),
            SizedBox(
              height: 86,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                _tile(context, 'none', null, label: 'Aucun'),
                for (final e in kChatWallpapers.entries) _tile(context, e.key, e.value),
                GestureDetector(
                  onTap: _pickOwn,
                  child: Container(
                    width: 64,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(14)),
                    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_photo_alternate_rounded),
                      SizedBox(height: 4),
                      Text('Galerie', style: TextStyle(fontSize: 10)),
                    ]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  c.saveTheme(asDefault: true);
                  Get.back();
                  Get.snackbar('', 'Thème appliqué par défaut aux autres discussions.', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
                },
                icon: const Icon(Icons.palette_outlined, size: 18),
                label: const Text('Utiliser pour toutes mes discussions'),
              ),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _tile(BuildContext context, String key, List<Color>? colors, {String? label}) {
    final selected = c.wallpaper.value == key;
    return GestureDetector(
      onTap: () {
        c.wallpaper.value = key;
        c.saveTheme();
      },
      child: Container(
        width: 64,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          gradient: colors != null ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors) : null,
          color: colors == null ? Colors.grey.withValues(alpha: .15) : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? GPTheme.primaryColor : Colors.transparent, width: 3),
        ),
        child: label != null ? Center(child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))) : null,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CONFIDENTIALITÉ
// ═════════════════════════════════════════════════════════════════════════════
Future<void> showChatPrivacySheet(BuildContext context, ChatController c) {
  final hideSeen = false.obs, hideRead = false.obs;
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) {
      final dark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(color: dark ? const Color(0xFF1A1A1A) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Obx(() => Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Confidentialité', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              SwitchListTile(
                activeColor: GPTheme.primaryColor,
                title: const Text('Masquer « vu à » et « en ligne »'),
                subtitle: const Text('Vous ne verrez plus non plus celui des autres.'),
                value: hideSeen.value,
                onChanged: (v) async {
                  hideSeen.value = v;
                  if (!await c.savePrivacy(hideLastSeen: v)) hideSeen.value = !v;
                },
              ),
              SwitchListTile(
                activeColor: GPTheme.primaryColor,
                title: const Text('Désactiver les accusés de lecture'),
                subtitle: const Text('Les ✓✓ bleus ne seront plus envoyés ni affichés.'),
                value: hideRead.value,
                onChanged: (v) async {
                  hideRead.value = v;
                  if (!await c.savePrivacy(hideReadReceipts: v)) hideRead.value = !v;
                },
              ),
            ])),
      );
    },
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// SONDAGES
// ═════════════════════════════════════════════════════════════════════════════
Future<void> showCreatePollSheet(BuildContext context, ChatController c, int convId) {
  final q = TextEditingController();
  final opts = [TextEditingController(), TextEditingController()];
  bool multiple = false, busy = false;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final dark = Theme.of(ctx).brightness == Brightness.dark;
      return Container(
        padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.of(ctx).viewInsets.bottom + 18),
        decoration: BoxDecoration(color: dark ? const Color(0xFF1A1A1A) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Créer un sondage', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(controller: q, maxLength: 200, decoration: const InputDecoration(labelText: 'Question', border: OutlineInputBorder())),
            const SizedBox(height: 6),
            for (var i = 0; i < opts.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: opts[i],
                  maxLength: 80,
                  decoration: InputDecoration(labelText: 'Option ${i + 1}', counterText: '', border: const OutlineInputBorder()),
                ),
              ),
            if (opts.length < 6)
              TextButton.icon(onPressed: () => setS(() => opts.add(TextEditingController())), icon: const Icon(Icons.add), label: const Text('Ajouter une option')),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: GPTheme.primaryColor,
              title: const Text('Autoriser plusieurs réponses'),
              value: multiple,
              onChanged: (v) => setS(() => multiple = v),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: GPTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              onPressed: busy
                  ? null
                  : () async {
                      final options = opts.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();
                      if (q.text.trim().isEmpty || options.length < 2) {
                        Get.snackbar('', 'Une question et au moins 2 options.', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
                        return;
                      }
                      setS(() => busy = true);
                      final ok = await c.sendPoll(convId, q.text.trim(), options, multiple: multiple);
                      if (ok && ctx.mounted) Navigator.of(ctx).pop();
                      setS(() => busy = false);
                    },
              child: const Text('Envoyer', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      );
    }),
  );
}

class PollBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final ChatController ctrl;
  const PollBubble({super.key, required this.message, required this.isMe, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final p = message.poll ?? {};
    final options = (p['options'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final multiple = p['multiple'] == true;
    final total = options.fold<int>(0, (a, o) => a + (o['count'] as int? ?? 0));
    final fg = isMe ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87);
    final bar = isMe ? Colors.white : GPTheme.primaryColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: SizedBox(
        width: 240,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.poll_rounded, size: 16, color: fg.withValues(alpha: .8)),
            const SizedBox(width: 6),
            Text(multiple ? 'Sondage · plusieurs choix' : 'Sondage', style: TextStyle(color: fg.withValues(alpha: .8), fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          Text(p['question']?.toString() ?? message.content, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 14.5)),
          const SizedBox(height: 8),
          for (var i = 0; i < options.length; i++)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: message.id <= 0
                  ? null
                  : () {
                      final mine = <int>{
                        for (var j = 0; j < options.length; j++)
                          if (options[j]['voted'] == true) j
                      };
                      if (multiple) {
                        mine.contains(i) ? mine.remove(i) : mine.add(i);
                        ctrl.votePoll(message, mine.toList());
                      } else {
                        ctrl.votePoll(message, mine.contains(i) ? <int>[] : [i]);
                      }
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: [
                  Row(children: [
                    Icon(options[i]['voted'] == true ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 18, color: fg),
                    const SizedBox(width: 8),
                    Expanded(child: Text(options[i]['text'].toString(), style: TextStyle(color: fg, fontSize: 13.5))),
                    Text('${options[i]['count'] ?? 0}', style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : (options[i]['count'] as int? ?? 0) / total,
                      minHeight: 5,
                      backgroundColor: fg.withValues(alpha: .2),
                      valueColor: AlwaysStoppedAnimation(bar),
                    ),
                  ),
                ]),
              ),
            ),
          const SizedBox(height: 4),
          Text('${p['total_voters'] ?? 0} vote(s)', style: TextStyle(color: fg.withValues(alpha: .7), fontSize: 10.5)),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VUE UNIQUE (anti-capture)
// ═════════════════════════════════════════════════════════════════════════════
class ViewOnceBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final ChatController ctrl;
  const ViewOnceBubble({super.key, required this.message, required this.isMe, required this.ctrl});

  IconData get _icon => message.type == MessageType.video
      ? Icons.videocam_rounded
      : message.type == MessageType.audio
          ? Icons.mic_rounded
          : Icons.photo_rounded;
  String get _noun => message.type == MessageType.video ? 'Vidéo' : message.type == MessageType.audio ? 'Vocal' : 'Photo';

  @override
  Widget build(BuildContext context) {
    final opened = message.viewOnceOpened;
    final fg = isMe ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87);
    final String label = isMe ? (opened ? '$_noun · Ouvert' : '$_noun · Vue unique') : (opened ? 'Ouvert' : 'Appuyer pour voir');
    return InkWell(
      onTap: (isMe || opened || message.id <= 0)
          ? null
          : () async {
              final bytes = await ctrl.openViewOnce(message);
              if (bytes == null || !context.mounted) return;
              await Navigator.of(context).push(MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => ViewOnceViewer(bytes: bytes, type: message.type),
              ));
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: fg.withValues(alpha: opened ? .4 : 1), width: 2, strokeAlign: BorderSide.strokeAlignInside),
            ),
            child: Icon(opened ? Icons.check_rounded : _icon, size: 18, color: fg.withValues(alpha: opened ? .5 : 1)),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isMe || opened ? label : _noun, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 14)),
            Text(isMe || opened ? 'Vue unique' : 'Appuyer pour voir · vue unique', style: TextStyle(color: fg.withValues(alpha: .7), fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}

class ViewOnceViewer extends StatefulWidget {
  final List<int> bytes;
  final MessageType type;
  const ViewOnceViewer({super.key, required this.bytes, required this.type});
  @override
  State<ViewOnceViewer> createState() => _ViewOnceViewerState();
}

class _ViewOnceViewerState extends State<ViewOnceViewer> {
  VideoPlayerController? _video;
  AudioPlayer? _audio;
  File? _tmp;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _protect(true);
    _prepare();
  }

  /// Bloque captures d'écran (Android FLAG_SECURE) et masque le contenu dans
  /// l'aperçu multitâche / enregistrement d'écran (iOS).
  Future<void> _protect(bool on) async {
    try {
      if (on) {
        await ScreenProtector.preventScreenshotOn();
        await ScreenProtector.protectDataLeakageWithBlur();
      } else {
        await ScreenProtector.preventScreenshotOff();
        await ScreenProtector.protectDataLeakageWithBlurOff();
      }
    } catch (_) {}
  }

  Future<void> _prepare() async {
    if (widget.type == MessageType.image) {
      setState(() => _ready = true);
      return;
    }
    final dir = await getTemporaryDirectory();
    _tmp = File('${dir.path}/vo_${DateTime.now().microsecondsSinceEpoch}.${widget.type == MessageType.video ? 'mp4' : 'm4a'}');
    await _tmp!.writeAsBytes(widget.bytes, flush: true);
    if (widget.type == MessageType.video) {
      _video = VideoPlayerController.file(_tmp!);
      await _video!.initialize();
      await _video!.play();
    } else {
      _audio = AudioPlayer();
      await _audio!.play(DeviceFileSource(_tmp!.path));
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _protect(false);
    _video?.dispose();
    _audio?.dispose();
    _tmp?.delete().catchError((_) => _tmp!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Vue unique', style: TextStyle(fontSize: 15)),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
      ),
      body: Center(
        child: !_ready
            ? const CircularProgressIndicator(color: Colors.white)
            : widget.type == MessageType.image
                ? InteractiveViewer(child: Image.memory(Uint8List.fromList(widget.bytes), fit: BoxFit.contain))
                : widget.type == MessageType.video
                    ? AspectRatio(aspectRatio: _video!.value.aspectRatio, child: VideoPlayer(_video!))
                    : const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 96),
      ),
    );
  }
}
