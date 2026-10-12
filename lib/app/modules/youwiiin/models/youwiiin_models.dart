// lib/app/modules/youwiiin/models/youwiiin_models.dart
//
// Modèles Youwiiin : jeu du catalogue (GzGame), salle multijoueur (GzRoom),
// joueurs (GzRoomPlayer / GzUserLite). Formes JSON : voir le contrat API
// (/api/gamez/..., chemins conservés pour la compatibilité).

import 'package:flutter/widgets.dart';

int gzInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);

bool _b(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

/// Une option d'un réglage de partie (ex. « Rapide » = 30).
class GzSettingOption {
  final dynamic value;
  final String label;
  const GzSettingOption(this.value, this.label);
}

/// Réglage de partie choisi par l'hôte (schéma `mp_settings` du catalogue).
class GzSetting {
  final String key;
  final String label;
  final dynamic defaultValue;
  final List<GzSettingOption> options;
  const GzSetting(this.key, this.label, this.defaultValue, this.options);

  /// Parsing tolérant : un réglage sans clé ou sans option est ignoré.
  static GzSetting? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final key = raw['key']?.toString() ?? '';
    final opts = <GzSettingOption>[];
    final rawOpts = raw['options'];
    if (rawOpts is List) {
      for (final o in rawOpts) {
        if (o is Map && o['value'] != null) {
          opts.add(GzSettingOption(o['value'], o['label']?.toString() ?? o['value'].toString()));
        } else if (o != null && o is! Map) {
          opts.add(GzSettingOption(o, o.toString()));
        }
      }
    }
    if (key.isEmpty || opts.isEmpty) return null;
    final def = raw['default'] ?? opts.first.value;
    return GzSetting(key, raw['label']?.toString() ?? key, def, opts);
  }

  /// Libellé lisible d'une valeur (retombe sur la valeur brute).
  String labelFor(dynamic v) {
    for (final o in options) {
      if ('${o.value}' == '$v') return o.label;
    }
    return '$v';
  }
}

String gzModeLabel(String? mode) => mode == 'score_duel' ? 'Chacun sa partie' : 'Même plateau';

String gzModeHint(String? mode) => mode == 'score_duel'
    ? 'Chacun joue sa partie, le meilleur score gagne.'
    : 'Vous jouez ensemble sur le même plateau.';

class GzGame {
  final int id;
  final String name;
  final String slug;
  final String? coverUrl;
  final String entryUrl;
  final String? category;
  final String? description;
  final String icon; // nom Lucide, converti en FontAwesome par l'UI
  final Color accent;
  final bool isActive;
  final int myBest;
  final int myPlays;

  // Favoris + multijoueur (catalogue enrichi)
  bool isFavorite;
  final bool isMultiplayer;
  final int minPlayers;
  final int maxPlayers;

  /// `realtime` (tour par tour via événements) | `score_duel` | null.
  final String? mpMode;

  /// Modes proposés à la création d'une salle (`realtime`, `score_duel`).
  final List<String> mpModes;

  /// Réglages de partie choisis par l'hôte (schéma du catalogue).
  final List<GzSetting> mpSettings;

  GzGame.fromJson(Map<String, dynamic> j)
    : id = gzInt(j['id']),
      name = j['name']?.toString() ?? '',
      slug = j['slug']?.toString() ?? '',
      coverUrl = j['cover_url']?.toString(),
      entryUrl = (j['play_url'] ?? j['entry_url'])?.toString() ?? '',
      category = j['category']?.toString(),
      description = j['description']?.toString(),
      icon = j['icon']?.toString() ?? 'gamepad-2',
      accent = _hex(j['accent']?.toString()),
      isActive = j['is_active'] == null ? true : _b(j['is_active']),
      myBest = gzInt(j['my_best_score']),
      myPlays = gzInt(j['my_plays']),
      isFavorite = _b(j['is_favorite']),
      isMultiplayer = _b(j['is_multiplayer']),
      minPlayers = j['min_players'] == null ? 2 : gzInt(j['min_players']),
      maxPlayers = j['max_players'] == null ? 2 : gzInt(j['max_players']),
      mpMode = j['mp_mode']?.toString(),
      mpModes = _modes(j['mp_modes'], j['mp_mode']?.toString()),
      mpSettings = j['mp_settings'] is List
          ? (j['mp_settings'] as List).map(GzSetting.tryParse).whereType<GzSetting>().toList()
          : const <GzSetting>[];

  static List<String> _modes(dynamic raw, String? fallback) {
    final l = raw is List ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toSet().toList() : <String>[];
    if (l.isEmpty && fallback != null && fallback.isNotEmpty) l.add(fallback);
    return l;
  }

  static Color _hex(String? h) {
    final c = (h ?? '#facc15').replaceFirst('#', '');
    return Color(int.tryParse('FF$c', radix: 16) ?? 0xFFFACC15);
  }
}

/// Utilisateur trouvé par la recherche de joueurs.
class GzUserLite {
  final int id;
  final String name;
  final String? username;
  final String? avatarUrl;

  /// Nombre de parties jouées ensemble (suggestions uniquement, 0 sinon).
  final int played;

  GzUserLite.fromJson(Map<String, dynamic> j)
    : id = gzInt(j['id'] ?? j['user_id']),
      name = j['name']?.toString() ?? '',
      username = j['username']?.toString(),
      avatarUrl = j['avatar_url']?.toString(),
      played = gzInt(j['played']);
}

class GzRoomPlayer {
  final int userId;
  final String name;
  final String? avatarUrl;

  /// invited | joined | declined | left
  final String status;
  final int? score;
  final bool isWinner;
  final bool reported;

  GzRoomPlayer.fromJson(Map<String, dynamic> j)
    : userId = gzInt(j['user_id'] ?? j['id']),
      name = j['name']?.toString() ?? '',
      avatarUrl = j['avatar_url']?.toString(),
      status = j['status']?.toString() ?? 'invited',
      score = j['score'] == null ? null : gzInt(j['score']),
      isWinner = _b(j['is_winner']),
      reported = _b(j['reported']);
}

class GzRoom {
  final int id;
  final String code;

  /// waiting | playing | finished | cancelled
  final String status;
  final String? mode; // realtime | score_duel
  final int stake;
  final int pot;
  final int minPlayers;
  final int maxPlayers;
  final String? seed;
  final int hostId;
  final Map<String, dynamic> gameJson;
  final List<GzRoomPlayer> players;
  final List<int> winnerIds;
  final String myStatus;
  final String playUrl;

  /// Réglages choisis par l'hôte (clé → valeur). Vide si absent.
  final Map<String, dynamic> settings;

  /// JSON brut (renvoyé tel quel au jeu via le pont : `YW._native`).
  final Map<String, dynamic> raw;

  GzRoom.fromJson(Map<String, dynamic> j)
    : raw = Map<String, dynamic>.from(j),
      id = gzInt(j['id']),
      code = j['code']?.toString() ?? '',
      status = j['status']?.toString() ?? 'waiting',
      mode = j['mode']?.toString(),
      stake = gzInt(j['stake']),
      pot = gzInt(j['pot']),
      minPlayers = j['min_players'] == null ? 2 : gzInt(j['min_players']),
      maxPlayers = j['max_players'] == null ? 2 : gzInt(j['max_players']),
      seed = j['seed']?.toString(),
      hostId = gzInt(j['host_id']),
      gameJson = j['game'] is Map ? Map<String, dynamic>.from(j['game']) : <String, dynamic>{},
      players = (j['players'] as List? ?? [])
          .whereType<Map>()
          .map((p) => GzRoomPlayer.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      winnerIds = (j['winner_ids'] as List? ?? []).map(gzInt).toList(),
      myStatus = j['my_status']?.toString() ?? '',
      settings = j['settings'] is Map ? Map<String, dynamic>.from(j['settings']) : <String, dynamic>{},
      playUrl = (j['play_url'] ?? (j['game'] is Map ? j['game']['play_url'] : null))?.toString() ?? '';

  bool get isWaiting => status == 'waiting';
  bool get isPlaying => status == 'playing';
  bool get isFinished => status == 'finished';
  bool get isCancelled => status == 'cancelled';
  bool get isOver => isFinished || isCancelled;
  bool get isScoreDuel => mode == 'score_duel';

  /// Lignes « Libellé : valeur » des réglages, libellés pris dans [schema] si connu.
  List<(String, String)> settingsLines(List<GzSetting> schema) {
    final out = <(String, String)>[];
    settings.forEach((k, v) {
      GzSetting? s;
      for (final x in schema) {
        if (x.key == k) s = x;
      }
      out.add((s?.label ?? k, s == null ? '$v' : s.labelFor(v)));
    });
    return out;
  }

  String get gameName => gameJson['name']?.toString() ?? 'Jeu';
  int get joinedCount => players.where((p) => p.status == 'joined').length;

  GzRoomPlayer? player(int userId) {
    for (final p in players) {
      if (p.userId == userId) return p;
    }
    return null;
  }

  /// Jeu (pour réutiliser la vue de jeu) reconstruit depuis `game`.
  GzGame toGame() => GzGame.fromJson({
    ...gameJson,
    'play_url': playUrl.isNotEmpty ? playUrl : gameJson['play_url'],
    'is_multiplayer': true,
    'mp_mode': mode,
    'mp_modes': mode == null ? null : [mode],
  });

  /// win | lose | draw pour le joueur [me], une fois la salle terminée.
  String outcomeFor(int me) {
    if (isCancelled) return 'draw'; // annulée / remboursée
    if (winnerIds.isEmpty) return 'draw';
    if (winnerIds.contains(me)) return winnerIds.length > 1 ? 'draw' : 'win';
    return 'lose';
  }

  /// GCoin gagnés (estimation côté client, sauf valeur `gained` fournie).
  int gainedFor(int me) {
    final g = raw['my_gain'] ?? raw['gained'];
    if (g != null) return gzInt(g);
    final o = outcomeFor(me);
    if (o == 'lose') return 0;
    if (isCancelled || o == 'draw') return stake; // remboursement
    return stake > 0 ? pot : 10; // mise 0 : bonus maison
  }
}
