// lib/app/modules/youwiiin/widgets/youwiiin_create_room_sheet.dart
//
// « Jouer avec des amis » : création de salle par l'hôte (mode, réglages de partie,
// mise, nombre de joueurs, invités) puis ouverture du lobby. Les invités ne choisissent
// rien : ils voient mode et réglages en lecture seule dans le lobby.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

import '../controllers/youwiiin_controller.dart';
import 'youwiiin_player_picker.dart';
import 'youwiiin_style.dart';

Future<void> showYouwiiinCreateRoomSheet(BuildContext context, GzGame game) {
  final st = YwStyle.of(context);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: st.sheet,
    shape: YwStyle.sheetShape,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _CreateRoomBody(game: game),
    ),
  );
}

class _CreateRoomBody extends StatefulWidget {
  final GzGame game;
  const _CreateRoomBody({required this.game});

  @override
  State<_CreateRoomBody> createState() => _CreateRoomBodyState();
}

class _CreateRoomBodyState extends State<_CreateRoomBody> {
  static const _stakes = [0, 10, 25, 50, 100];
  final _c = gzController;
  int _stake = 0;
  late int _max = widget.game.maxPlayers.clamp(widget.game.minPlayers, 99);
  List<GzUserLite> _invited = [];
  bool _busy = false;

  late String? _mode = _initialMode();
  late final Map<String, dynamic> _settings = {for (final s in widget.game.mpSettings) s.key: s.defaultValue};

  String? _initialMode() {
    final g = widget.game;
    if (g.mpModes.isEmpty) return g.mpMode;
    return g.mpMode != null && g.mpModes.contains(g.mpMode) ? g.mpMode : g.mpModes.first;
  }

  @override
  void initState() {
    super.initState();
    _c.loadMe(); // solde à jour pour griser les mises trop élevées
  }

  Future<void> _create() async {
    if (_busy) return;
    setState(() => _busy = true);
    final r = await _c.createRoom(
      widget.game,
      stake: _stake,
      maxPlayers: _max,
      inviteUserIds: _invited.map((u) => u.id).toList(),
      mode: _mode,
      settings: _settings,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      ToastHelper.showToast(r.error ?? 'Création impossible.', backgroundColor: YwStyle.danger);
      return;
    }
    Navigator.pop(context);
    Get.toNamed('/youwiiin/room/${r.data!.code}');
  }

  Widget _label(YwStyle st, String t, {String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t, style: TextStyle(color: st.fg, fontWeight: FontWeight.w800, fontSize: 15)),
        if (hint != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(hint, style: TextStyle(color: st.sub, fontSize: 12))),
      ],
    ),
  );

  Widget _modePicker(YwStyle st) {
    final modes = widget.game.mpModes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(st, 'Mode de jeu'),
        Row(
          children: [
            for (var i = 0; i < modes.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _modeTile(st, modes[i])),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(gzModeHint(_mode), style: TextStyle(color: st.sub, fontSize: 12)),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _modeTile(YwStyle st, String m) {
    final on = _mode == m;
    final fgc = on ? YwStyle.onAccent : st.fg;
    return Material(
      color: on ? st.accent : st.faint,
      borderRadius: BorderRadius.circular(YwStyle.rBtn),
      child: InkWell(
        borderRadius: BorderRadius.circular(YwStyle.rBtn),
        onTap: () => setState(() => _mode = m),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(m == 'score_duel' ? Icons.emoji_events_outlined : Icons.grid_view_rounded, color: fgc, size: 22),
                const SizedBox(height: 4),
                Text(gzModeLabel(m), textAlign: TextAlign.center, maxLines: 2, style: TextStyle(color: fgc, fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingsBlock(YwStyle st) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in widget.game.mpSettings) ...[
          _label(st, s.label),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in s.options)
                YwChoiceChip(
                  label: o.label,
                  selected: '${_settings[s.key]}' == '${o.value}',
                  onTap: () => setState(() => _settings[s.key] = o.value),
                ),
            ],
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  Widget _stepBtn(YwStyle st, IconData icon, VoidCallback? onTap) => SizedBox(
    width: YwStyle.minTap,
    height: YwStyle.minTap,
    child: IconButton(onPressed: onTap, icon: Icon(icon, color: onTap == null ? st.fg.withValues(alpha: .25) : st.accent)),
  );

  @override
  Widget build(BuildContext context) {
    final st = YwStyle.of(context);
    final g = widget.game;
    final fixed = g.minPlayers >= g.maxPlayers;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .85,
      maxChildSize: .95,
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: st.fg.withValues(alpha: .2), borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 16),
          Text('Jouer avec des amis', style: TextStyle(color: st.fg, fontSize: 21, fontWeight: FontWeight.w900)),
          Text(g.name, style: TextStyle(color: st.sub)),
          const SizedBox(height: 18),
          if (g.mpModes.length > 1) _modePicker(st),
          if (g.mpSettings.isNotEmpty) _settingsBlock(st),
          Obx(
            () => Row(children: [
              Expanded(child: Text('Mise par joueur', style: TextStyle(color: st.fg, fontWeight: FontWeight.w800, fontSize: 15))),
              Icon(Icons.toll_rounded, size: 16, color: st.accent),
              const SizedBox(width: 4),
              Text('Solde : ${_c.gcoinBalance.value} GCoin', style: TextStyle(color: st.sub, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _stakes)
                  YwChoiceChip(
                    label: s == 0 ? 'Gratuit' : '$s',
                    selected: _stake == s,
                    // Mise > solde : désactivée.
                    onTap: s > _c.gcoinBalance.value ? null : () => setState(() => _stake = s),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _stake == 0 ? 'Sans mise : le gagnant reçoit un bonus maison.' : 'Le gagnant remporte le pot (mises cumulées).',
            style: TextStyle(color: st.sub, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: Text('Nombre de joueurs', style: TextStyle(color: st.fg, fontWeight: FontWeight.w800, fontSize: 15))),
            if (fixed)
              Text('${g.maxPlayers} joueurs', style: TextStyle(color: st.sub, fontWeight: FontWeight.w700))
            else ...[
              _stepBtn(st, Icons.remove_circle_outline_rounded, _max > g.minPlayers ? () => setState(() => _max--) : null),
              Text('$_max', style: TextStyle(color: st.fg, fontWeight: FontWeight.w900, fontSize: 18)),
              _stepBtn(st, Icons.add_circle_outline_rounded, _max < g.maxPlayers ? () => setState(() => _max++) : null),
            ],
          ]),
          if (!fixed) Text('De ${g.minPlayers} à ${g.maxPlayers} joueurs (vous inclus).', style: TextStyle(color: st.sub, fontSize: 12)),
          const SizedBox(height: 16),
          Text('Inviter des joueurs', style: TextStyle(color: st.fg, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          YouwiiinPlayerPicker(accent: st.accent, fg: st.fg, maxSelect: _max - 1, onChanged: (l) => _invited = l),
          const SizedBox(height: 20),
          YwButton(label: _invited.isEmpty ? 'Créer la salle' : 'Créer et inviter', icon: Icons.send_rounded, busy: _busy, onTap: _create),
        ],
      ),
    );
  }
}
