import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/space_model.dart';
import 'package:grand_public_v2/app/services/ad_service.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

/// Fil vertical de shorts (portrait) d'une chaîne, façon TikTok / Reels :
/// on glisse vers le haut pour passer au short suivant, de la MÊME chaîne.
class ShortsFeedController extends GetxController {
  final int channelId;
  final int? initialVideoId;
  final List<SpaceVideo> seed;

  ShortsFeedController({required this.channelId, this.initialVideoId, this.seed = const []});

  final items = <SpaceVideo>[].obs;
  final isLoading = true.obs;
  final current = 0.obs;

  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;
  int _swipes = 0;
  int _adEvery = 6;

  @override
  void onInit() {
    super.onInit();
    if (seed.isNotEmpty) items.assignAll(seed.where((v) => v.isPortrait));
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Fréquence des interstitiels définie dans l'admin (par annonce).
    AdService.fetch('interstitial', channelId: channelId, screen: 'shorts', limit: 1).then((l) {
      if (l.isNotEmpty) _adEvery = l.first.frequencyEvery;
    });
    await loadMore(reset: true);
    final idx = initialVideoId == null ? -1 : items.indexWhere((v) => v.id == initialVideoId);
    current.value = idx < 0 ? 0 : idx;
    isLoading.value = false;
  }

  /// Index initial de la PageView.
  int get startIndex => current.value;

  Future<void> loadMore({bool reset = false}) async {
    if (_loadingMore || (!_hasMore && !reset)) return;
    _loadingMore = true;
    try {
      if (reset) {
        _page = 0;
        _hasMore = true;
      }
      final r = await RequestService().get('/channels/$channelId/shorts', queryParameters: {'page': _page + 1, 'per_page': 12});
      final data = r.data['data'] as Map<String, dynamic>;
      final fresh = (data['medias'] as List<dynamic>? ?? [])
          .map((m) => SpaceVideo.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList();
      _page = (data['current_page'] as num?)?.toInt() ?? _page + 1;
      _hasMore = data['has_more_pages'] == true;

      if (reset) {
        items.assignAll(fresh);
      } else {
        final known = items.map((e) => e.id).toSet();
        items.addAll(fresh.where((v) => !known.contains(v.id)));
      }
    } catch (e) {
      debugPrint('ShortsFeedController.loadMore: $e');
    } finally {
      _loadingMore = false;
    }
  }

  /// Retourne true quand un interstitiel doit être affiché après ce swipe.
  bool onPageChanged(int index) {
    current.value = index;
    if (index >= items.length - 3) loadMore();
    _swipes++;
    return _adEvery > 0 && _swipes % _adEvery == 0;
  }

  void updateVideo(SpaceVideo v) {
    final i = items.indexWhere((e) => e.id == v.id);
    if (i != -1) items[i] = v;
  }

  Future<void> toggleLike(SpaceVideo v) async {
    final liked = v.isLiked;
    updateVideo(v.copyWith(
      isLiked: !liked,
      isDisliked: false,
      likesCount: liked ? v.likesCount - 1 : v.likesCount + 1,
    ));
    try {
      await RequestService().post('/videos/${v.id}/like');
    } catch (_) {
      updateVideo(v); // rollback
    }
  }
}
