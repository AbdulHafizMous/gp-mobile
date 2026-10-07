import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:grand_public_v2/app/themes/app_theme.dart';

import '../controllers/blowmusic_controller.dart';

bool _dark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

/// Petite boîte de saisie (création / renommage de playlist).
Future<String?> bmAskName(
  BuildContext context, {
  required String title,
  String initial = '',
  String action = 'Valider',
}) {
  final ctl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: TextField(
        controller: ctl,
        autofocus: true,
        maxLength: 60,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: 'Nom de la playlist',
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: GPTheme.primaryColor),
          onPressed: () => Navigator.pop(ctx, ctl.text.trim()),
          child: Text(action),
        ),
      ],
    ),
  ).then((v) => (v == null || v.isEmpty) ? null : v);
}

Future<bool> bmConfirm(
  BuildContext context,
  String title,
  String text, {
  String action = 'Supprimer',
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return r == true;
}

void _toast(BuildContext c, String m) {
  ScaffoldMessenger.maybeOf(c)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(m),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}

/// Feuille « Ajouter à une playlist » : liste + création rapide.
Future<void> bmAddToPlaylistSheet(BuildContext context, BmTrack track) async {
  final ctrl = Get.find<BlowMusicController>();
  await ctrl.loadPlaylists(forTrack: track.id);
  if (!context.mounted) return;
  final accent = GPTheme.primaryColor;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: _dark(context) ? const Color(0xFF17121D) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * .7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ajouter à une playlist',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: accent.withOpacity(.15),
                child: Icon(Icons.add_rounded, color: accent),
              ),
              title: const Text(
                'Nouvelle playlist',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () async {
                final name = await bmAskName(
                  ctx,
                  title: 'Nouvelle playlist',
                  action: 'Créer',
                );
                if (name == null) return;
                final p = await ctrl.createPlaylist(name, trackId: track.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted)
                  _toast(
                    context,
                    p != null
                        ? 'Ajouté à « ${p.name} »'
                        : 'Création impossible',
                  );
              },
            ),
            Flexible(
              child: Obx(
                () => ListView(
                  shrinkWrap: true,
                  children: ctrl.playlists
                      .map(
                        (p) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: accent.withOpacity(.12),
                            child: Icon(
                              Icons.queue_music_rounded,
                              color: accent,
                            ),
                          ),
                          title: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${p.count} titre${p.count > 1 ? 's' : ''}',
                          ),
                          trailing: p.hasTrack
                              ? Icon(Icons.check_circle_rounded, color: accent)
                              : null,
                          onTap: p.hasTrack
                              ? null
                              : () async {
                                  final ok = await ctrl.addToPlaylist(p, track);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted)
                                    _toast(
                                      context,
                                      ok
                                          ? 'Ajouté à « ${p.name} »'
                                          : 'Ajout impossible',
                                    );
                                },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
  ctrl.loadPlaylists();
}

/// Détail d'une playlist : lecture, aléatoire, glisser pour réordonner,
/// balayer pour retirer, ajout de titres depuis la bibliothèque.
class BmPlaylistPage extends StatefulWidget {
  final BmPlaylistInfo playlist;
  const BmPlaylistPage({super.key, required this.playlist});

  @override
  State<BmPlaylistPage> createState() => _BmPlaylistPageState();
}

class _BmPlaylistPageState extends State<BmPlaylistPage> {
  final ctrl = Get.find<BlowMusicController>();
  List<BmTrack> tracks = [];
  bool loading = true;

  BmPlaylistInfo get p => widget.playlist;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await ctrl.fetchPlaylistTracks(p);
    if (!mounted) return;
    setState(() {
      tracks = t;
      loading = false;
      p.count = t.length;
    });
  }

  void _play({bool shuffle = false}) {
    if (tracks.isEmpty) return;
    ctrl.shuffle.value = shuffle;
    final start = shuffle ? (tracks.toList()..shuffle()).first : tracks.first;
    ctrl.playTrack(start, queue: tracks, label: p.name);
  }

  Future<void> _addTitles() async {
    final accent = GPTheme.primaryColor;
    await ctrl.loadLibrary(reset: true);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _dark(context) ? const Color(0xFF17121D) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final ids = tracks.map((t) => t.id).toSet();
        return StatefulBuilder(
          builder: (ctx, setM) => SafeArea(
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * .8,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: TextField(
                      onChanged: ctrl.searchLibrary,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un titre',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Obx(
                      () => ListView.builder(
                        itemCount: ctrl.libraryTracks.length,
                        itemBuilder: (_, i) {
                          final t = ctrl.libraryTracks[i];
                          final inside = ids.contains(t.id);
                          return ListTile(
                            leading: _Cover(
                              url: t.coverUrl,
                              size: 44,
                              accent: accent,
                            ),
                            title: Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              t.artistName ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Icon(
                              inside
                                  ? Icons.check_circle_rounded
                                  : Icons.add_circle_outline_rounded,
                              color: accent,
                            ),
                            onTap: inside
                                ? null
                                : () async {
                                    final ok = await ctrl.addToPlaylist(p, t);
                                    if (ok) {
                                      ids.add(t.id);
                                      setM(() {});
                                    }
                                  },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    _load();
  }

  Future<void> _menu(String v) async {
    if (v == 'rename') {
      final n = await bmAskName(context, title: 'Renommer', initial: p.name);
      if (n != null && await ctrl.renamePlaylist(p, n) && mounted)
        setState(() {});
    } else if (v == 'delete') {
      if (await bmConfirm(
        context,
        'Supprimer la playlist ?',
        '« ${p.name} » sera définitivement supprimée.',
      )) {
        if (await ctrl.deletePlaylist(p) && mounted) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = _dark(context);
    final accent = GPTheme.primaryColor;
    final bg = dark ? const Color(0xFF0E0B12) : const Color(0xFFF7F5F8);
    final fg = dark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: fg,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        elevation: 0,
        title: Text(
          p.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: fg, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Ajouter des titres',
            icon: Icon(Icons.playlist_add_rounded, color: fg),
            onPressed: _addTitles,
          ),
          PopupMenuButton<String>(
            iconColor: fg,
            onSelected: _menu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Renommer')),
              PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${tracks.length} titre${tracks.length > 1 ? 's' : ''} · maintenez et glissez pour réordonner',
                          style: TextStyle(
                            color: fg.withOpacity(.55),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: tracks.isEmpty ? null : () => _play(),
                        icon: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Lire',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: FilledButton.styleFrom(backgroundColor: accent),
                        tooltip: 'Lecture aléatoire',
                        onPressed: tracks.isEmpty
                            ? null
                            : () => _play(shuffle: true),
                        icon: const Icon(
                          Icons.shuffle_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: tracks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.queue_music_rounded,
                                size: 56,
                                color: accent.withOpacity(.5),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Playlist vide',
                                style: TextStyle(
                                  color: fg,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: accent,
                                ),
                                onPressed: _addTitles,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Ajouter des titres'),
                              ),
                            ],
                          ),
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          buildDefaultDragHandles: false,
                          itemCount: tracks.length,
                          onReorder: (o, n) {
                            if (n > o) n--;
                            setState(
                              () => tracks.insert(n, tracks.removeAt(o)),
                            );
                            ctrl.savePlaylistOrder(p, tracks);
                          },
                          itemBuilder: (_, i) {
                            final t = tracks[i];
                            return Dismissible(
                              key: ValueKey('pl${t.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red.shade600,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (_) {
                                setState(() => tracks.removeAt(i));
                                ctrl.removeFromPlaylist(p, t);
                              },
                              child: ListTile(
                                leading: _Cover(
                                  url: t.coverUrl,
                                  size: 48,
                                  accent: accent,
                                ),
                                title: Text(
                                  t.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: fg,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  t.artistName ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: fg.withOpacity(.5),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: ReorderableDragStartListener(
                                  index: i,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.drag_handle_rounded,
                                      color: fg.withOpacity(.45),
                                    ),
                                  ),
                                ),
                                onTap: () => ctrl.playTrack(
                                  t,
                                  queue: tracks,
                                  label: p.name,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _Cover extends StatelessWidget {
  final String? url;
  final double size;
  final Color accent;
  const _Cover({required this.url, required this.size, required this.accent});

  @override
  Widget build(BuildContext context) {
    final fb = Container(
      color: accent.withOpacity(.15),
      child: Icon(Icons.music_note_rounded, color: accent, size: size * .5),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: (url != null && url!.isNotEmpty)
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fb,
              )
            : fb,
      ),
    );
  }
}
