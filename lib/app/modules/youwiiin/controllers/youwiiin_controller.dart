// lib/app/modules/youwiiin/controllers/youwiiin_controller.dart
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart' hide Response;
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/utils/api_error_helper.dart';
import 'package:grand_public_v2/app/components/fullscreen_ad_page.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/services/recent_history_service.dart';
import '../models/youwiiin_models.dart';

// Les vues importent GzGame / GzRoom… via ce contrôleur.
export '../models/youwiiin_models.dart';

/// Résultat d'un appel réseau : données OU message d'erreur lisible.
class GzResult<T> {
  final T? data;
  final String? error;
  const GzResult.ok(this.data) : error = null;
  const GzResult.fail(this.error) : data = null;
  bool get ok => error == null;
}

int _i(dynamic v) => gzInt(v);

class YouwiiinController extends GetxController {
  final currentTab = 0.obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final featured = <GzGame>[].obs;
  final catalog = <GzGame>[].obs;
  final recent = <Map<String, dynamic>>[].obs;

  // Favoris (ids pour le cœur réactif + liste pour le filtre « Favoris »)
  final favoriteIds = <int>{}.obs;
  final favorites = <GzGame>[].obs;
  final favoritesLoading = false.obs;
  final showFavoritesOnly = false.obs;

  // Invitations multijoueur reçues (salles en attente où je suis invité)
  final invitations = <GzRoom>[].obs;

  // GCoin
  final gcoinBalance = 0.obs;
  final gcoinHistory = <Map<String, dynamic>>[].obs;
  final gcoinPerGame = <Map<String, dynamic>>[].obs;
  final totalEarned = 0.obs;
  final totalSpent = 0.obs;
  final historyType = ''.obs; // '' | earned | spent
  final historyLoading = false.obs;

  // Classement
  final lbGame = ''.obs; // '' = général
  final lbPeriod = 'all'.obs;
  final lbRows = <Map<String, dynamic>>[].obs;
  final lbMe = Rxn<Map<String, dynamic>>();
  final lbLoading = false.obs;
  final lbTotal = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['tab'] is int) currentTab.value = args['tab'];
    loadHome();
    loadRecent();
    loadInvitations();
    loadMe();
    WidgetsBinding.instance.addPostFrameCallback((_) => maybeShowFullscreenAd());
  }

  void changeTab(int i) {
    currentTab.value = i;
    if (i == 0) {
      loadRecent();
      loadInvitations();
    }
    if (i == 1) loadGcoin();
    if (i == 2) loadLeaderboard();
  }

  Future<void> loadHome() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final res = await RequestService().get('/gamez/home');
      final data = res.data?['data'];
      featured.assignAll((data?['featured'] as List<dynamic>? ?? []).map((j) => GzGame.fromJson(j)));
      catalog.assignAll((data?['catalog'] as List<dynamic>? ?? []).map((j) => GzGame.fromJson(j)));
      // Cœurs : l'état serveur (is_favorite) fait foi.
      favoriteIds
        ..clear()
        ..addAll([...featured, ...catalog].where((g) => g.isFavorite).map((g) => g.id));
    } catch (_) {
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([loadHome(), loadRecent(), loadInvitations(), if (showFavoritesOnly.value) loadFavorites()]);
  }

  /// Parties récentes : un jeu = une ligne (dernier score, record, durée…).
  Future<void> loadRecent() async {
    try {
      final res = await RequestService().get('/gamez/recent');
      recent.assignAll(List<Map<String, dynamic>>.from(res.data?['data'] ?? []));
    } catch (_) {}
  }

  Future<void> loadMe() async {
    try {
      final res = await RequestService().get('/gamez/me');
      gcoinBalance.value = _i(res.data?['data']?['gcoin_balance']);
    } catch (_) {}
  }

  Future<void> loadGcoin() async {
    historyLoading.value = true;
    try {
      final res = await RequestService().get('/gamez/gcoin/history', queryParameters: {
        if (historyType.value.isNotEmpty) 'type': historyType.value,
        'per_page': 50,
      });
      final d = res.data?['data'];
      gcoinBalance.value = _i(d?['balance']);
      totalEarned.value = _i(d?['total_earned']);
      totalSpent.value = _i(d?['total_spent']);
      gcoinPerGame.assignAll(List<Map<String, dynamic>>.from(d?['per_game'] ?? []));
      gcoinHistory.assignAll(List<Map<String, dynamic>>.from(d?['items'] ?? []));
    } catch (_) {
    } finally {
      historyLoading.value = false;
    }
  }

  void setHistoryType(String t) {
    historyType.value = t;
    loadGcoin();
  }

  Future<void> loadLeaderboard() async {
    lbLoading.value = true;
    try {
      final res = await RequestService().get('/gamez/leaderboard', queryParameters: {
        if (lbGame.value.isNotEmpty) 'game': lbGame.value,
        'period': lbPeriod.value,
      });
      final d = res.data?['data'];
      lbRows.assignAll(List<Map<String, dynamic>>.from(d?['rows'] ?? []));
      lbMe.value = d?['me'] is Map ? Map<String, dynamic>.from(d['me']) : null;
      lbTotal.value = _i(d?['total_players']);
    } catch (_) {
    } finally {
      lbLoading.value = false;
    }
  }

  void setLbGame(String slug) {
    lbGame.value = slug;
    loadLeaderboard();
  }

  void setLbPeriod(String p) {
    lbPeriod.value = p;
    loadLeaderboard();
  }

  Future<Map<String, dynamic>?> gameStats(GzGame g) async {
    try {
      final res = await RequestService().get('/gamez/games/${g.id}/stats');
      return Map<String, dynamic>.from(res.data?['data'] ?? {});
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>?> startSession(GzGame game) async {
    try {
      final res = await RequestService().post('/gamez/games/${game.id}/session');
      final data = res.data?['data'];
      RecentHistoryService.addRecentGame(id: game.id, name: game.name, cover: game.coverUrl);
      return {
        'session_token': data['session_token']?.toString() ?? '',
        'entry_url': data['entry_url']?.toString() ?? game.entryUrl,
      };
    } catch (_) {
      return null;
    }
  }

  /// Retourne {gcoin_awarded, is_new_best, best_score} ou null en cas d'échec.
  Future<Map<String, dynamic>?> submitScore(
    String sessionToken,
    int score, {
    int? duration,
    String? level,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final res = await RequestService().post('/gamez/sessions/$sessionToken/score', data: {
        'score': score,
        if (duration != null) 'duration': duration,
        if (level != null) 'level': level,
        if (metadata != null) 'metadata': metadata,
      });
      final d = Map<String, dynamic>.from(res.data?['data'] ?? {});
      final gained = _i(d['gcoin_awarded']);
      if (gained > 0) gcoinBalance.value += gained;
      loadRecent();
      return d;
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // FAVORIS
  // ══════════════════════════════════════════════════════════════════════
  bool isFav(GzGame g) => favoriteIds.contains(g.id);

  Future<void> loadFavorites() async {
    favoritesLoading.value = true;
    try {
      final res = await RequestService().get('/gamez/favorites');
      var raw = res.data?['data'];
      if (raw is Map && raw['data'] is List) raw = raw['data'];
      final list = (raw as List? ?? []).whereType<Map>().map((j) => GzGame.fromJson(Map<String, dynamic>.from(j))).toList();
      favorites.assignAll(list);
      favoriteIds.addAll(list.map((g) => g.id));
    } catch (_) {
    } finally {
      favoritesLoading.value = false;
    }
  }

  /// Bascule le favori (mise à jour optimiste, annulée en cas d'échec).
  Future<void> toggleFavorite(GzGame g) async {
    final was = favoriteIds.contains(g.id);
    _applyFav(g, !was);
    try {
      final res = await RequestService().post('/gamez/games/${g.id}/favorite');
      final server = res.data?['data']?['is_favorite'] ?? res.data?['is_favorite'];
      if (server is bool && server != !was) _applyFav(g, server);
    } catch (_) {
      _applyFav(g, was);
    }
  }

  void _applyFav(GzGame g, bool fav) {
    g.isFavorite = fav;
    if (fav) {
      favoriteIds.add(g.id);
      if (!favorites.any((x) => x.id == g.id)) favorites.insert(0, g);
    } else {
      favoriteIds.remove(g.id);
      favorites.removeWhere((x) => x.id == g.id);
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // MULTIJOUEUR : joueurs, invitations, salles
  // ══════════════════════════════════════════════════════════════════════
  int get myId => activeUser.value.id;
  String get activeName => activeUser.value.name;

  Map<String, dynamic>? _unwrap(Response res) {
    final d = res.data;
    if (d is Map) {
      final inner = d['data'];
      if (inner is Map) return Map<String, dynamic>.from(inner);
      return Map<String, dynamic>.from(d);
    }
    return null;
  }

  GzResult<GzRoom> _room(Response res) {
    final m = _unwrap(res);
    final r = m == null ? null : (m['room'] is Map ? Map<String, dynamic>.from(m['room']) : m);
    if (r == null || r['code'] == null) return const GzResult.fail('Réponse inattendue du serveur.');
    return GzResult.ok(GzRoom.fromJson(r));
  }

  Future<GzResult<T>> _safe<T>(Future<GzResult<T>> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      return GzResult.fail(ApiErrorHelper.messageFor(e));
    } catch (_) {
      return const GzResult.fail('Une erreur est survenue. Réessayez.');
    }
  }

  /// Recherche d'utilisateurs à inviter (≤ 20, hors moi / bloqués).
  Future<List<GzUserLite>> searchPlayers(String q) async {
    try {
      final res = await RequestService().get('/gamez/players', queryParameters: {'q': q});
      var raw = res.data is Map ? res.data['data'] : res.data;
      if (raw is Map && raw['data'] is List) raw = raw['data'];
      return (raw as List? ?? []).whereType<Map>().map((j) => GzUserLite.fromJson(Map<String, dynamic>.from(j))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> loadInvitations() async {
    try {
      final res = await RequestService().get('/gamez/invitations');
      var raw = res.data is Map ? res.data['data'] : res.data;
      if (raw is Map && raw['data'] is List) raw = raw['data'];
      invitations.assignAll((raw as List? ?? []).whereType<Map>().map((j) => GzRoom.fromJson(Map<String, dynamic>.from(j))));
    } catch (_) {}
  }

  Future<GzResult<GzRoom>> createRoom(GzGame game, {required int stake, required int maxPlayers, required List<int> inviteUserIds}) {
    return _safe(() async {
      final res = await RequestService().post('/gamez/rooms', data: {
        'game_id': game.id,
        'stake': stake,
        'max_players': maxPlayers,
        'invite_user_ids': inviteUserIds,
      });
      return _room(res);
    });
  }

  Future<GzResult<GzRoom>> fetchRoom(String code) => _safe(() async => _room(await RequestService().get('/gamez/rooms/$code')));

  Future<GzResult<GzRoom>> joinRoom(String code) => _safe(() async => _room(await RequestService().post('/gamez/rooms/$code/join')));

  Future<GzResult<GzRoom>> declineRoom(String code) async {
    final r = await _safe(() async => _room(await RequestService().post('/gamez/rooms/$code/decline')));
    invitations.removeWhere((x) => x.code == code);
    return r;
  }

  Future<GzResult<GzRoom>> startRoom(String code) => _safe(() async => _room(await RequestService().post('/gamez/rooms/$code/start')));

  Future<GzResult<GzRoom>> leaveRoom(String code) async {
    final r = await _safe(() async => _room(await RequestService().post('/gamez/rooms/$code/leave')));
    invitations.removeWhere((x) => x.code == code);
    return r;
  }

  Future<GzResult<bool>> inviteToRoom(String code, List<int> userIds) => _safe(() async {
    await RequestService().post('/gamez/rooms/$code/invite', data: {'user_ids': userIds});
    return const GzResult.ok(true);
  });

  Future<GzResult<int>> postRoomEvent(String code, String type, Map<String, dynamic> payload) => _safe(() async {
    final res = await RequestService().post('/gamez/rooms/$code/events', data: {'type': type, 'payload': payload});
    return GzResult.ok(_i(_unwrap(res)?['id']));
  });

  /// Événements après [after] + état de la salle (polling ~1,2 s).
  Future<GzResult<({List<Map<String, dynamic>> events, GzRoom? room})>> fetchRoomEvents(String code, int after) => _safe(() async {
    final res = await RequestService().get('/gamez/rooms/$code/events', queryParameters: {'after': after});
    final m = _unwrap(res) ?? {};
    final events = (m['events'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final room = m['room'] is Map ? GzRoom.fromJson(Map<String, dynamic>.from(m['room'])) : null;
    return GzResult.ok((events: events, room: room));
  });

  Future<GzResult<bool>> postRoomResult(String code, {int? score, int? winnerUserId, bool? draw}) => _safe(() async {
    await RequestService().post('/gamez/rooms/$code/result', data: {
      if (score != null) 'score': score,
      if (winnerUserId != null) 'winner_user_id': winnerUserId,
      if (draw != null) 'draw': draw,
    });
    return const GzResult.ok(true);
  });

  Future<void> switchToGrandPublic() async {
    await AppModeService.setMode(AppMode.grandPublic);
    Get.offAllNamed('/home');
  }
}
