import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/api_error_helper.dart';
import '../controllers/youwiiin_controller.dart';
import '../models/youwiiin_models.dart';
import '../widgets/youwiiin_style.dart';

/// Création d'un tournoi par un joueur : jeux, format, places, droit d'entrée, public ou privé + amis invités.
/// Retourne l'id du tournoi créé (ou null).
Future<int?> showCreateTournamentSheet(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CreateSheet(),
  );
}

/// Saisie d'un code d'invitation : renvoie l'id du tournoi trouvé.
Future<int?> askTournamentCode(BuildContext context) async {
  final c = TextEditingController();
  final st = YwStyle.of(context);
  final code = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: st.bg,
      title: Text('Code du tournoi', style: TextStyle(color: st.fg, fontWeight: FontWeight.w900)),
      content: TextField(controller: c, autofocus: true, textCapitalization: TextCapitalization.characters, maxLength: 12, style: TextStyle(color: st.fg), decoration: const InputDecoration(hintText: 'Ex. K7Q2ZP')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Chercher')),
      ],
    ),
  );
  Future.delayed(const Duration(milliseconds: 400), c.dispose);
  if (code == null || code.isEmpty) return null;
  try {
    final r = await RequestService().post('/gamez/tournaments/by-code', data: {'code': code});
    return (r.data['data']['id'] as num).toInt();
  } on DioException catch (e) {
    ApiErrorHelper.showError(e);
    return null;
  }
}

class _CreateSheet extends StatefulWidget {
  const _CreateSheet();
  @override
  State<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends State<_CreateSheet> {
  final _title = TextEditingController();
  final _fee = TextEditingController(text: '0');
  String _format = 'rounds';
  String _currency = 'free';
  bool _public = true;
  int _min = 4, _max = 8;
  final Set<int> _games = {};
  final Set<int> _invites = {};
  List<Map<String, dynamic>> _all = [];
  List<GzUserLite> _friends = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final r = await RequestService().get('/gamez/games');
      final d = r.data['data'];
      final list = d is Map ? d['games'] : d;
      _all = List<Map<String, dynamic>>.from((list as List).map((e) => Map<String, dynamic>.from(e)));
    } catch (_) {}
    try {
      if (Get.isRegistered<YouwiiinController>()) _friends = await Get.find<YouwiiinController>().fetchPlayerSuggestions();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final t = _title, f = _fee;
    Future.delayed(const Duration(milliseconds: 400), () {
      t.dispose();
      f.dispose();
    });
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().length < 3) {
      Get.snackbar('Tournoi', 'Donnez un nom au tournoi.');
      return;
    }
    if (_games.isEmpty) {
      Get.snackbar('Tournoi', 'Choisissez au moins un jeu.');
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await RequestService().post('/gamez/tournaments', data: {
        'title': _title.text.trim(),
        'format': _format,
        'currency': _currency,
        if (_currency != 'free') 'entry_fee': int.tryParse(_fee.text) ?? 0,
        'min_players': _min,
        'max_players': _max,
        'is_public': _public,
        'game_ids': _games.toList(),
        if (_invites.isNotEmpty) 'invite_ids': _invites.toList(),
      });
      if (mounted) Navigator.pop(context, (r.data['data']['id'] as num).toInt());
    } on DioException catch (e) {
      ApiErrorHelper.showError(e);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final st = YwStyle.of(context);
    Widget label(String t) => Padding(padding: const EdgeInsets.only(top: 16, bottom: 6), child: Text(t, style: TextStyle(color: st.fg, fontWeight: FontWeight.w800)));
    return DraggableScrollableSheet(
      initialChildSize: .92,
      minChildSize: .5,
      maxChildSize: .95,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(color: st.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(18, 14, 18, MediaQuery.of(context).viewInsets.bottom + 14),
        child: ListView(controller: sc, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: st.sub.withValues(alpha: .4), borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 12),
          Text('Organiser un tournoi', style: TextStyle(color: st.fg, fontSize: 20, fontWeight: FontWeight.w900)),
          label('Nom'),
          TextField(controller: _title, maxLength: 80, style: TextStyle(color: st.fg), decoration: const InputDecoration(hintText: 'Ex. Coupe du quartier')),
          label('Format'),
          Wrap(spacing: 8, children: [
            YwChoiceChip(label: 'Classement par tours', selected: _format == 'rounds', onTap: () => setState(() => _format = 'rounds')),
            YwChoiceChip(label: 'Élimination directe', selected: _format == 'bracket', onTap: () => setState(() => _format = 'bracket')),
          ]),
          label('Jeux (${_games.length})'),
          SizedBox(
            height: 46,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final g in _all)
                if (_format == 'rounds' || g['is_multiplayer'] == true || g['is_multiplayer'] == 1 || _games.contains(g['id']))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: YwChoiceChip(
                      label: '${g['name']}',
                      selected: _games.contains((g['id'] as num).toInt()),
                      onTap: () => setState(() {
                        final id = (g['id'] as num).toInt();
                        _games.contains(id) ? _games.remove(id) : _games.add(id);
                      }),
                    ),
                  ),
            ]),
          ),
          label('Places : $_min à $_max joueurs'),
          RangeSlider(
            values: RangeValues(_min.toDouble(), _max.toDouble()),
            min: 2,
            max: 64,
            divisions: 62,
            activeColor: st.accent,
            labels: RangeLabels('$_min', '$_max'),
            onChanged: (v) => setState(() {
              _min = v.start.round();
              _max = v.end.round();
            }),
          ),
          label("Droit d'entrée"),
          Wrap(spacing: 8, children: [
            for (final c in const [('free', 'Gratuit'), ('gcoin', 'GCoin'), ('cash', 'Argent réel')])
              YwChoiceChip(label: c.$2, selected: _currency == c.$1, onTap: () => setState(() => _currency = c.$1)),
          ]),
          if (_currency != 'free') ...[
            const SizedBox(height: 8),
            TextField(controller: _fee, keyboardType: TextInputType.number, style: TextStyle(color: st.fg), decoration: InputDecoration(suffixText: _currency == 'cash' ? 'F' : 'GCoin', hintText: 'Montant')),
          ],
          label('Visibilité'),
          Wrap(spacing: 8, children: [
            YwChoiceChip(label: 'Public', selected: _public, onTap: () => setState(() => _public = true)),
            YwChoiceChip(label: 'Privé (sur invitation)', selected: !_public, onTap: () => setState(() => _public = false)),
          ]),
          if (_friends.isNotEmpty) ...[
            label('Inviter des amis (${_invites.length})'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final f in _friends.take(20))
                YwChoiceChip(label: f.name, selected: _invites.contains(f.id), onTap: () => setState(() => _invites.contains(f.id) ? _invites.remove(f.id) : _invites.add(f.id))),
            ]),
          ],
          const SizedBox(height: 22),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: st.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Créer le tournoi', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }
}
