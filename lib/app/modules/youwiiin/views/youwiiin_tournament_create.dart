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
  List<GzGame> _all = [];
  bool _gamesLoading = true;
  List<GzUserLite> _friends = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Les jeux viennent du catalogue déjà chargé par l'accueil (même source que la grille des jeux).
    try {
      final c = gzController;
      if (c.catalog.isEmpty && c.featured.isEmpty) await c.loadHome();
      final byId = <int, GzGame>{for (final g in [...c.featured, ...c.catalog]) g.id: g};
      _all = byId.values.where((g) => g.isActive).toList();
    } catch (_) {}
    _gamesLoading = false;
    if (mounted) setState(() {});
    try {
      _friends = await gzController.fetchPlayerSuggestions();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _retryGames() async {
    setState(() => _gamesLoading = true);
    await _loadData();
  }

  void _setFormat(String f) => setState(() {
        _format = f;
        // Élimination directe : seuls les jeux multijoueurs sont possibles.
        if (f == 'bracket') _games.removeWhere((id) => !(_all.firstWhereOrNull((g) => g.id == id)?.isMultiplayer ?? false));
      });

  void _toggleGame(GzGame g) {
    if (_games.contains(g.id)) {
      setState(() => _games.remove(g.id));
    } else if (_games.length >= 6) {
      Get.snackbar('Tournoi', '6 jeux maximum par tournoi.');
    } else {
      setState(() => _games.add(g.id));
    }
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
    Widget label(String t, {String? hint}) => Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(t, style: TextStyle(color: st.fg, fontWeight: FontWeight.w900, fontSize: 15)),
            if (hint != null) ...[const SizedBox(width: 8), Flexible(child: Text(hint, style: TextStyle(color: st.sub, fontSize: 12)))],
          ]),
        );
    final shown = _all.where((g) => _format == 'rounds' || g.isMultiplayer).toList();
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
          label('Format', hint: _format == 'rounds' ? 'Chaque jeu = un tour, classement cumulé' : 'Duels, le perdant est éliminé'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            YwChoiceChip(label: 'Classement par tours', selected: _format == 'rounds', onTap: () => _setFormat('rounds')),
            YwChoiceChip(label: 'Élimination directe', selected: _format == 'bracket', onTap: () => _setFormat('bracket')),
          ]),
          label('Jeux', hint: _games.isEmpty ? '1 à 6 jeux' : '${_games.length} choisi${_games.length > 1 ? 's' : ''} sur 6'),
          if (_gamesLoading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: Center(child: CircularProgressIndicator()))
          else if (shown.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: st.faint, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Text(_all.isEmpty ? 'Impossible de charger les jeux.' : 'Aucun jeu multijoueur disponible pour ce format.', textAlign: TextAlign.center, style: TextStyle(color: st.sub)),
                const SizedBox(height: 8),
                TextButton.icon(onPressed: _retryGames, icon: const Icon(Icons.refresh_rounded), label: const Text('Réessayer')),
              ]),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shown.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .82),
              itemBuilder: (_, i) => _GameTile(g: shown[i], selected: _games.contains(shown[i].id), onTap: () => _toggleGame(shown[i]), st: st),
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
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in const [('free', 'Gratuit'), ('gcoin', 'GCoin'), ('cash', 'Argent réel')])
              YwChoiceChip(label: c.$2, selected: _currency == c.$1, onTap: () => setState(() => _currency = c.$1)),
          ]),
          if (_currency != 'free') ...[
            const SizedBox(height: 8),
            TextField(controller: _fee, keyboardType: TextInputType.number, style: TextStyle(color: st.fg), decoration: InputDecoration(suffixText: _currency == 'cash' ? 'F' : 'GCoin', hintText: 'Montant')),
          ],
          label('Visibilité'),
          Wrap(spacing: 8, runSpacing: 8, children: [
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


/// Carte d'un jeu sélectionnable : visuel, nom, pastille multijoueur et coche.
class _GameTile extends StatelessWidget {
  final GzGame g;
  final bool selected;
  final VoidCallback onTap;
  final YwStyle st;
  const _GameTile({required this.g, required this.selected, required this.onTap, required this.st});

  @override
  Widget build(BuildContext context) {
    final img = (g.iconUrl != null && g.iconUrl!.isNotEmpty) ? g.iconUrl : g.coverUrl;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? st.accent.withValues(alpha: .12) : st.faint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? st.accent : Colors.transparent, width: 2),
        ),
        child: Column(children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: img != null
                      ? Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback())
                      : _fallback(),
                ),
              ),
              if (g.isMultiplayer)
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: .65), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Multi', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
                  ),
                ),
              if (selected)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(color: st.accent, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 6),
          Text(g.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: st.fg, fontWeight: FontWeight.w800, fontSize: 11.5, height: 1.15)),
        ]),
      ),
    );
  }

  Widget _fallback() => Container(color: g.accent.withValues(alpha: .25), alignment: Alignment.center, child: Icon(Icons.sports_esports_rounded, color: g.accent, size: 30));
}
