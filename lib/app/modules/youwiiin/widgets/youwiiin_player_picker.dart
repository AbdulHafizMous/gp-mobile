// lib/app/modules/youwiiin/widgets/youwiiin_player_picker.dart
//
// Sélecteur d'amis Youwiiin : vrai modal bottom sheet (recherche épinglée en haut,
// bouton « Inviter (N) » épinglé en bas, liste visible au-dessus du clavier).
// - showYouwiiinPlayerPicker(...) ouvre le modal et renvoie la sélection (null si fermé).
// - YouwiiinPlayerPicker : champ compact (même API publique qu'avant) qui ouvre le modal
//   et affiche les joueurs choisis ; utilisé par la création de salle.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/youwiiin_controller.dart';
import 'youwiiin_style.dart';

Widget gzAvatar(String name, String? url, {double size = 38, Color? color}) {
  final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
  final bg = color ?? Colors.grey.withValues(alpha: .35);
  final fallback = Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
    child: Text(letter, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * .42)),
  );
  if (url == null || url.isEmpty) return fallback;
  return ClipOval(
    child: Image.network(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback),
  );
}

/// Ouvre le sélecteur en modal. Renvoie la sélection validée, ou null si fermé sans valider.
Future<List<GzUserLite>?> showYouwiiinPlayerPicker(
  BuildContext context, {
  int? maxSelect,
  List<int> excludeIds = const [],
  List<GzUserLite> initial = const [],
  String title = 'Inviter des joueurs',
}) {
  final st = YwStyle.of(context);
  return showModalBottomSheet<List<GzUserLite>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: st.sheet,
    shape: YwStyle.sheetShape,
    builder: (ctx) => Padding(
      // Le contenu remonte avec le clavier : liste, recherche et bouton restent visibles.
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .88,
        minChildSize: .5,
        maxChildSize: .95,
        builder: (_, scroll) => _PickerBody(scroll: scroll, maxSelect: maxSelect, excludeIds: excludeIds, initial: initial, title: title),
      ),
    ),
  );
}

class _PickerBody extends StatefulWidget {
  final ScrollController scroll;
  final int? maxSelect;
  final List<int> excludeIds;
  final List<GzUserLite> initial;
  final String title;
  const _PickerBody({required this.scroll, required this.maxSelect, required this.excludeIds, required this.initial, required this.title});

  @override
  State<_PickerBody> createState() => _PickerBodyState();
}

class _PickerBodyState extends State<_PickerBody> with SingleTickerProviderStateMixin {
  final _ctrl = gzController;
  final _field = TextEditingController();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  Timer? _debounce;
  int _reqId = 0;

  List<GzUserLite> _suggestions = [];
  bool _sugLoading = true;
  List<GzUserLite> _remote = [];
  bool _searching = false;
  String _q = '';
  late final List<GzUserLite> _selected = List.of(widget.initial);

  bool get _full => widget.maxSelect != null && _selected.length >= widget.maxSelect!;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pulse.dispose();
    _field.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    final l = await _ctrl.fetchPlayerSuggestions();
    if (!mounted) return;
    setState(() {
      _suggestions = l.where((u) => !widget.excludeIds.contains(u.id)).toList();
      _sugLoading = false;
    });
  }

  void _onText(String raw) {
    final q = raw.trim();
    _debounce?.cancel();
    setState(() {
      _q = q;
      if (q.length < 2) {
        _remote = [];
        _searching = false;
        _reqId++;
      } else {
        _searching = true;
      }
    });
    if (q.length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final id = ++_reqId;
      final r = await _ctrl.searchPlayers(q);
      // Réponse périmée (frappe plus récente) : ignorée.
      if (!mounted || id != _reqId) return;
      setState(() {
        _remote = r.where((u) => !widget.excludeIds.contains(u.id)).toList();
        _searching = false;
      });
    });
  }

  bool _isSel(GzUserLite u) => _selected.any((x) => x.id == u.id);

  void _toggle(GzUserLite u) {
    final i = _selected.indexWhere((x) => x.id == u.id);
    if (i < 0 && _full) {
      HapticFeedback.lightImpact();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => i >= 0 ? _selected.removeAt(i) : _selected.add(u));
  }

  bool _matches(GzUserLite u) {
    final q = _q.toLowerCase();
    return u.name.toLowerCase().contains(q) || (u.username ?? '').toLowerCase().contains(q);
  }

  // ───────────────────────── UI ─────────────────────────
  Widget _searchBar(YwStyle st) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: TextField(
      controller: _field,
      onChanged: _onText,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: st.fg),
      cursorColor: st.accent,
      decoration: InputDecoration(
        hintText: 'Rechercher un joueur (nom ou pseudo)',
        hintStyle: TextStyle(color: st.fg.withValues(alpha: .4)),
        prefixIcon: Icon(Icons.search_rounded, color: st.fg.withValues(alpha: .5)),
        suffixIcon: _q.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: st.fg.withValues(alpha: .5)),
                onPressed: () {
                  _field.clear();
                  _onText('');
                },
              ),
        filled: true,
        fillColor: st.faint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(YwStyle.rBtn), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(YwStyle.rBtn), borderSide: BorderSide(color: st.accent.withValues(alpha: .6), width: 1.4)),
      ),
    ),
  );

  Widget _chips(YwStyle st) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: _selected.isEmpty && !_full
          ? const SizedBox(width: double.infinity)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selected.isNotEmpty)
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _selected.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final u = _selected[i];
                        return Material(
                          color: st.accent.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(30),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () => _toggle(u),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                gzAvatar(u.name, u.avatarUrl, size: 28, color: st.accent),
                                const SizedBox(width: 8),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 110),
                                  child: Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: st.fg, fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.close_rounded, size: 16, color: st.fg.withValues(alpha: .6)),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (_full)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: Row(children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: YwStyle.warn),
                      const SizedBox(width: 6),
                      Text('Maximum atteint', style: TextStyle(color: YwStyle.warn, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                const SizedBox(height: 6),
              ],
            ),
    );
  }

  Widget _sectionTitle(YwStyle st, String t) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
    child: Text(t.toUpperCase(), style: TextStyle(color: st.sub, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: .8)),
  );

  Widget _row(YwStyle st, GzUserLite u) {
    final sel = _isSel(u);
    final disabled = !sel && _full;
    return Opacity(
      opacity: disabled ? .4 : 1,
      child: InkWell(
        onTap: disabled ? null : () => _toggle(u),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(children: [
              gzAvatar(u.name, u.avatarUrl, size: 42, color: st.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: st.fg, fontWeight: FontWeight.w800, fontSize: 15)),
                  if ((u.username ?? '').isNotEmpty) Text('@${u.username}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: st.sub, fontSize: 12.5)),
                ]),
              ),
              if (u.played > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: st.accent.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
                  child: Text(u.played == 1 ? '1 partie' : '${u.played} parties', style: TextStyle(color: st.accent, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
              ],
              _Check(selected: sel, accent: st.accent, fg: st.fg),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _skeletonRow(YwStyle st) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
    child: Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: st.faint)),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 12, width: 140, decoration: BoxDecoration(color: st.faint, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 8),
          Container(height: 10, width: 90, decoration: BoxDecoration(color: st.faint, borderRadius: BorderRadius.circular(6))),
        ]),
      ),
    ]),
  );

  Widget _skeleton(YwStyle st) => FadeTransition(
    opacity: Tween(begin: .45, end: 1.0).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
    child: Column(children: [for (var i = 0; i < 6; i++) _skeletonRow(st)]),
  );

  Widget _empty(YwStyle st, bool searching) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
    child: Column(children: [
      Icon(searching ? Icons.person_search_rounded : Icons.group_outlined, size: 44, color: st.fg.withValues(alpha: .25)),
      const SizedBox(height: 12),
      Text(searching ? 'Aucun joueur trouvé' : 'Pas encore de suggestions', style: TextStyle(color: st.fg, fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 4),
      Text(
        searching ? 'Vérifiez l\'orthographe ou essayez un autre pseudo.' : 'Recherchez un joueur par son nom ou son pseudo pour l\'inviter.',
        textAlign: TextAlign.center,
        style: TextStyle(color: st.sub, fontSize: 13),
      ),
    ]),
  );

  List<Widget> _listItems(YwStyle st) {
    final searching = _q.isNotEmpty;
    if (!searching) {
      if (_sugLoading) return [_skeleton(st)];
      if (_suggestions.isEmpty) return [_empty(st, false)];
      final frequent = _suggestions.where((u) => u.played > 0).toList();
      final others = _suggestions.where((u) => u.played <= 0).toList();
      return [
        if (frequent.isNotEmpty) ...[_sectionTitle(st, 'Joueurs fréquents'), for (final u in frequent) _row(st, u)],
        if (others.isNotEmpty) ...[_sectionTitle(st, 'Suggérés'), for (final u in others) _row(st, u)],
      ];
    }
    // Recherche : filtre local instantané + résultats serveur (dédoublonnés).
    final local = _suggestions.where(_matches).toList();
    final ids = local.map((u) => u.id).toSet();
    final remote = _remote.where((u) => !ids.contains(u.id)).toList();
    final all = [...local, ...remote];
    if (all.isEmpty) return [if (_searching || (_q.length < 2 && _sugLoading)) _skeleton(st) else _empty(st, true)];
    return [
      _sectionTitle(st, 'Résultats'),
      for (final u in all) _row(st, u),
      if (_searching) const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final st = YwStyle.of(context);
    final n = _selected.length;
    return Column(
      children: [
        const SizedBox(height: 10),
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: st.fg.withValues(alpha: .2), borderRadius: BorderRadius.circular(4)))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Row(children: [
            Expanded(child: Text(widget.title, style: TextStyle(color: st.fg, fontSize: 21, fontWeight: FontWeight.w900))),
            if (widget.maxSelect != null) Text('$n / ${widget.maxSelect}', style: TextStyle(color: st.sub, fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
        ),
        _searchBar(st),
        _chips(st),
        Expanded(
          child: ListView(
            controller: widget.scroll,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: 12),
            children: _listItems(st),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          decoration: BoxDecoration(color: st.sheet, border: Border(top: BorderSide(color: st.faint))),
          child: SafeArea(
            top: false,
            child: YwButton(
              label: n > 0 ? 'Inviter ($n)' : 'Fermer',
              icon: n > 0 ? Icons.send_rounded : Icons.check_rounded,
              onTap: () => Navigator.pop(context, List<GzUserLite>.of(_selected)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Case ronde animée (primaire quand cochée).
class _Check extends StatelessWidget {
  final bool selected;
  final Color accent;
  final Color fg;
  const _Check({required this.selected, required this.accent, required this.fg});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? accent : Colors.transparent,
        border: Border.all(color: selected ? accent : fg.withValues(alpha: .3), width: 2),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: const Icon(Icons.check_rounded, size: 16, color: YwStyle.onAccent),
      ),
    );
  }
}

/// Champ compact qui ouvre le modal de sélection et affiche les joueurs choisis.
/// API inchangée : [onChanged] reçoit la liste à chaque validation.
class YouwiiinPlayerPicker extends StatefulWidget {
  final Color accent;
  final Color fg;

  /// Nombre maximum d'invités sélectionnables (null = illimité).
  final int? maxSelect;
  final List<int> excludeIds;
  final ValueChanged<List<GzUserLite>> onChanged;
  const YouwiiinPlayerPicker({
    super.key,
    required this.accent,
    required this.fg,
    required this.onChanged,
    this.maxSelect,
    this.excludeIds = const [],
  });

  @override
  State<YouwiiinPlayerPicker> createState() => _YouwiiinPlayerPickerState();
}

class _YouwiiinPlayerPickerState extends State<YouwiiinPlayerPicker> {
  List<GzUserLite> _selected = [];

  @override
  void didUpdateWidget(covariant YouwiiinPlayerPicker old) {
    super.didUpdateWidget(old);
    // Le nombre de joueurs a baissé : on ne garde que les premiers invités autorisés.
    final m = widget.maxSelect;
    if (m != null && _selected.length > m) {
      _selected = _selected.take(m < 0 ? 0 : m).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged(List.of(_selected)));
    }
  }

  Future<void> _open() async {
    final r = await showYouwiiinPlayerPicker(context, maxSelect: widget.maxSelect, excludeIds: widget.excludeIds, initial: _selected);
    if (r == null || !mounted) return;
    setState(() => _selected = r);
    widget.onChanged(List.of(r));
  }

  @override
  Widget build(BuildContext context) {
    final st = YwStyle.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: st.faint,
          borderRadius: BorderRadius.circular(YwStyle.rBtn),
          child: InkWell(
            borderRadius: BorderRadius.circular(YwStyle.rBtn),
            onTap: _open,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  Icon(Icons.person_add_alt_1_rounded, color: widget.accent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selected.isEmpty ? 'Choisir des amis à inviter' : '${_selected.length} joueur${_selected.length > 1 ? 's' : ''} invité${_selected.length > 1 ? 's' : ''}',
                      style: TextStyle(color: widget.fg, fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: widget.fg.withValues(alpha: .4)),
                ]),
              ),
            ),
          ),
        ),
        if (_selected.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final u in _selected)
                InputChip(
                  avatar: gzAvatar(u.name, u.avatarUrl, size: 22, color: widget.accent),
                  label: Text(u.name, style: const TextStyle(fontSize: 12)),
                  onDeleted: () {
                    setState(() => _selected = _selected.where((x) => x.id != u.id).toList());
                    widget.onChanged(List.of(_selected));
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}
