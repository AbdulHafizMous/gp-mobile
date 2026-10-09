// lib/app/modules/youwiiin/widgets/youwiiin_player_picker.dart
//
// Recherche d'utilisateurs (GET players?q=, debounce) + sélection multiple.
// Utilisé par la création de salle et par l'invitation depuis le lobby.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/youwiiin_controller.dart';

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
  final _ctrl = Get.find<YouwiiinController>();
  final _field = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  bool _searched = false;
  int _reqId = 0;
  List<GzUserLite> _results = [];
  final List<GzUserLite> _selected = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _field.dispose();
    super.dispose();
  }

  void _onText(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() {
        _results = [];
        _searched = false;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final id = ++_reqId;
      final r = await _ctrl.searchPlayers(q.trim());
      // On ignore les réponses périmées (frappe plus récente).
      if (!mounted || id != _reqId) return;
      setState(() {
        _results = r.where((u) => !widget.excludeIds.contains(u.id)).toList();
        _loading = false;
        _searched = true;
      });
    });
  }

  void _toggle(GzUserLite u) {
    final i = _selected.indexWhere((x) => x.id == u.id);
    setState(() {
      if (i >= 0) {
        _selected.removeAt(i);
      } else {
        if (widget.maxSelect != null && _selected.length >= widget.maxSelect!) return;
        _selected.add(u);
      }
    });
    widget.onChanged(List.of(_selected));
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.fg;
    final accent = widget.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _field,
          onChanged: _onText,
          style: TextStyle(color: fg),
          decoration: InputDecoration(
            hintText: 'Rechercher un joueur (nom ou pseudo)',
            hintStyle: TextStyle(color: fg.withValues(alpha: .4)),
            prefixIcon: Icon(Icons.search_rounded, color: fg.withValues(alpha: .5)),
            suffixIcon: _loading ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) : null,
            filled: true,
            fillColor: fg.withValues(alpha: .06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            isDense: true,
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
                  avatar: gzAvatar(u.name, u.avatarUrl, size: 22, color: accent),
                  label: Text(u.name, style: const TextStyle(fontSize: 12)),
                  onDeleted: () => _toggle(u),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        if (_searched && _results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text('Aucun joueur trouvé.', style: TextStyle(color: fg.withValues(alpha: .5))),
          ),
        for (final u in _results)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: gzAvatar(u.name, u.avatarUrl, color: accent),
            title: Text(u.name, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
            subtitle: (u.username ?? '').isEmpty ? null : Text('@${u.username}', style: TextStyle(color: fg.withValues(alpha: .5), fontSize: 12)),
            trailing: Icon(
              _selected.any((x) => x.id == u.id) ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
              color: _selected.any((x) => x.id == u.id) ? accent : fg.withValues(alpha: .4),
            ),
            onTap: () => _toggle(u),
          ),
      ],
    );
  }
}
