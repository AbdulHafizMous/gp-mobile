// lib/app/modules/youwiiin/widgets/youwiiin_create_room_sheet.dart
//
// « Jouer avec des amis » : création de salle (mise, nombre de joueurs,
// recherche + sélection d'invités) puis ouverture du lobby.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

import '../controllers/youwiiin_controller.dart';
import 'youwiiin_player_picker.dart';

Future<void> showYouwiiinCreateRoomSheet(BuildContext context, GzGame game) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF16151C) : Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _CreateRoomBody(game: game, isDark: isDark),
    ),
  );
}

class _CreateRoomBody extends StatefulWidget {
  final GzGame game;
  final bool isDark;
  const _CreateRoomBody({required this.game, required this.isDark});

  @override
  State<_CreateRoomBody> createState() => _CreateRoomBodyState();
}

class _CreateRoomBodyState extends State<_CreateRoomBody> {
  static const _stakes = [0, 10, 25, 50, 100];
  final _c = Get.find<YouwiiinController>();
  int _stake = 0;
  late int _max = widget.game.maxPlayers.clamp(widget.game.minPlayers, 99);
  List<GzUserLite> _invited = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _c.loadMe(); // solde à jour pour griser les mises trop élevées
  }

  Future<void> _create() async {
    if (_busy) return;
    setState(() => _busy = true);
    final r = await _c.createRoom(widget.game, stake: _stake, maxPlayers: _max, inviteUserIds: _invited.map((u) => u.id).toList());
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      ToastHelper.showToast(r.error ?? 'Création impossible.', backgroundColor: Colors.red);
      return;
    }
    Navigator.pop(context);
    Get.toNamed('/youwiiin/room/${r.data!.code}');
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isDark ? Colors.white : Colors.black87;
    final accent = GPTheme.primaryColor;
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
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: .4), borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 16),
          Text('Jouer avec des amis', style: TextStyle(color: fg, fontSize: 21, fontWeight: FontWeight.w900)),
          Text(g.name, style: TextStyle(color: fg.withValues(alpha: .55))),
          const SizedBox(height: 18),
          Obx(
            () => Row(children: [
              Text('Mise par joueur', style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
              const Spacer(),
              const Icon(Icons.toll_rounded, size: 16, color: Color(0xFFFFC600)),
              const SizedBox(width: 4),
              Text('Solde : ${_c.gcoinBalance.value} GCoin', style: TextStyle(color: fg.withValues(alpha: .6), fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _stakes)
                  ChoiceChip(
                    label: Text(s == 0 ? 'Gratuit' : '$s'),
                    selected: _stake == s,
                    selectedColor: accent,
                    labelStyle: TextStyle(color: _stake == s ? Colors.white : fg, fontWeight: FontWeight.w800),
                    // Mise > solde : désactivée.
                    onSelected: s > _c.gcoinBalance.value ? null : (_) => setState(() => _stake = s),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _stake == 0 ? 'Sans mise : le gagnant reçoit un bonus maison.' : 'Le gagnant remporte le pot (mises cumulées).',
            style: TextStyle(color: fg.withValues(alpha: .5), fontSize: 12),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Text('Nombre de joueurs', style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
            const Spacer(),
            if (fixed)
              Text('${g.maxPlayers} joueurs', style: TextStyle(color: fg.withValues(alpha: .7), fontWeight: FontWeight.w700))
            else ...[
              IconButton(onPressed: _max > g.minPlayers ? () => setState(() => _max--) : null, icon: const Icon(Icons.remove_circle_outline_rounded)),
              Text('$_max', style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 18)),
              IconButton(onPressed: _max < g.maxPlayers ? () => setState(() => _max++) : null, icon: const Icon(Icons.add_circle_outline_rounded)),
            ],
          ]),
          if (!fixed) Text('De ${g.minPlayers} à ${g.maxPlayers} joueurs (vous inclus).', style: TextStyle(color: fg.withValues(alpha: .5), fontSize: 12)),
          const SizedBox(height: 16),
          Text('Inviter des joueurs', style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          YouwiiinPlayerPicker(accent: accent, fg: fg, maxSelect: _max - 1, onChanged: (l) => _invited = l),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _create,
              style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
              label: const Text('Inviter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
