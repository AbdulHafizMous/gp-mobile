// lib/app/services/recent_history_service.dart
//
// Historique local (JSON stocké sur le téléphone via GetStorage) des
// morceaux/jeux récemment consultés — pas besoin d'appel serveur, purement
// pour le confort de navigation de l'utilisateur.

import 'package:get_storage/get_storage.dart';

class RecentHistoryService {
  static const _maxItems = 15;

  static void _push(String key, Map<String, dynamic> item, String idField) {
    final box = GetStorage();
    final list = List<Map<String, dynamic>>.from(
      (box.read<List>(key) ?? []).map((e) => Map<String, dynamic>.from(e)),
    );
    list.removeWhere((e) => e[idField] == item[idField]);
    list.insert(0, item);
    if (list.length > _maxItems) list.removeRange(_maxItems, list.length);
    box.write(key, list);
  }

  static List<Map<String, dynamic>> _read(String key) {
    final box = GetStorage();
    return List<Map<String, dynamic>>.from(
      (box.read<List>(key) ?? []).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  // ── Blowmusic ───────────────────────────────────────────────────────────
  static void addRecentTrack({
    required int id,
    required String title,
    String? artist,
    String? cover,
  }) => _push('bm_recent_tracks', {
    'id': id,
    'title': title,
    'artist': artist,
    'cover': cover,
  }, 'id');
  static List<Map<String, dynamic>> get recentTracks =>
      _read('bm_recent_tracks');

  // ── GameZ ────────────────────────────────────────────────────────────────
  static void addRecentGame({
    required int id,
    required String name,
    String? cover,
  }) =>
      _push('gz_recent_games', {'id': id, 'name': name, 'cover': cover}, 'id');
  static List<Map<String, dynamic>> get recentGames => _read('gz_recent_games');
}
