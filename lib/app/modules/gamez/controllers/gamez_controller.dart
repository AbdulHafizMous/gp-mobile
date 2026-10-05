// lib/app/modules/gamez/controllers/gamez_controller.dart
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/fullscreen_ad_page.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/services/recent_history_service.dart';

int _i(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);

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

  GzGame.fromJson(Map<String, dynamic> j)
      : id = _i(j['id']),
        name = j['name']?.toString() ?? '',
        slug = j['slug']?.toString() ?? '',
        coverUrl = j['cover_url']?.toString(),
        entryUrl = (j['play_url'] ?? j['entry_url'])?.toString() ?? '',
        category = j['category']?.toString(),
        description = j['description']?.toString(),
        icon = j['icon']?.toString() ?? 'gamepad-2',
        accent = _hex(j['accent']?.toString()),
        isActive = j['is_active'] == null ? true : (j['is_active'] == true || j['is_active'] == 1),
        myBest = _i(j['my_best_score']),
        myPlays = _i(j['my_plays']);

  static Color _hex(String? h) {
    final c = (h ?? '#facc15').replaceFirst('#', '');
    return Color(int.tryParse('FF$c', radix: 16) ?? 0xFFFACC15);
  }
}

class GameZController extends GetxController {
  final currentTab = 0.obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final featured = <GzGame>[].obs;
  final catalog = <GzGame>[].obs;
  final recent = <Map<String, dynamic>>[].obs;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => maybeShowFullscreenAd());
  }

  void changeTab(int i) {
    currentTab.value = i;
    if (i == 0) loadRecent();
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
    } catch (_) {
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([loadHome(), loadRecent()]);
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

  Future<void> switchToGrandPublic() async {
    await AppModeService.setMode(AppMode.grandPublic);
    Get.offAllNamed('/home');
  }
}
