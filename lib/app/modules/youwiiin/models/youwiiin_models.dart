// lib/app/modules/youwiiin/models/youwiiin_models.dart
//
// Modèles Youwiiin : jeu du catalogue (GzGame), salle multijoueur (GzRoom),
// joueurs (GzRoomPlayer / GzUserLite). Formes JSON : voir le contrat API
// (/api/gamez/..., chemins conservés pour la compatibilité).

import 'package:flutter/widgets.dart';

int gzInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);

bool _b(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

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
      mpMode = j['mp_mode']?.toString();

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

  GzUserLite.fromJson(Map<String, dynamic> j)
    : id = gzInt(j['id'] ?? j['user_id']),
      name = j['name']?.toString() ?? '',
      username = j['username']?.toString(),
      avatarUrl = j['avatar_url']?.toString();
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
      playUrl = (j['play_url'] ?? (j['game'] is Map ? j['game']['play_url'] : null))?.toString() ?? '';

  bool get isWaiting => status == 'waiting';
  bool get isPlaying => status == 'playing';
  bool get isFinished => status == 'finished';
  bool get isCancelled => status == 'cancelled';
  bool get isOver => isFinished || isCancelled;
  bool get isScoreDuel => mode == 'score_duel';

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
