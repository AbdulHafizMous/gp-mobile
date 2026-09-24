// lib/app/modules/gamez/controllers/gamez_controller.dart
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/fullscreen_ad_page.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/services/recent_history_service.dart';

class GzGame {
  final int id;
  final String name;
  final String slug;
  final String? coverUrl;
  final String entryUrl;
  final String? category;
  GzGame.fromJson(Map<String, dynamic> j)
      : id = j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
        name = j['name']?.toString() ?? '',
        slug = j['slug']?.toString() ?? '',
        coverUrl = j['cover_url']?.toString(),
        entryUrl = (j['play_url'] ?? j['entry_url'])?.toString() ?? '',
        category = j['category']?.toString();
}

class GameZController extends GetxController {
  final currentTab = 0.obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final featured = <GzGame>[].obs;
  final catalog = <GzGame>[].obs;
  final gcoinBalance = 0.obs;
  final leaderboard = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadHome();
    WidgetsBinding.instance.addPostFrameCallback((_) => maybeShowFullscreenAd());
  }

  void changeTab(int i) {
    currentTab.value = i;
    if (i == 2) loadLeaderboard();
    if (i == 1) loadMe();
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

  Future<void> loadMe() async {
    try {
      final res = await RequestService().get('/gamez/me');
      gcoinBalance.value = res.data?['data']?['gcoin_balance'] ?? 0;
    } catch (_) {}
  }

  Future<void> loadLeaderboard() async {
    try {
      final res = await RequestService().get('/gamez/leaderboard');
      leaderboard.assignAll(List<Map<String, dynamic>>.from(res.data?['data'] ?? []));
    } catch (_) {}
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

  Future<int> submitScore(String sessionToken, int score) async {
    try {
      final res = await RequestService().post('/gamez/sessions/$sessionToken/score', data: {'score': score});
      final gained = res.data?['data']?['gcoin_awarded'] ?? 0;
      if (gained > 0) gcoinBalance.value += (gained as int);
      return gained;
    } catch (_) {
      return 0;
    }
  }

  Future<void> switchToGrandPublic() async {
    await AppModeService.setMode(AppMode.grandPublic);
    Get.offAllNamed('/home');
  }
}
