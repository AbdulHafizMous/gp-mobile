// lib/app/modules/space/controllers/space_controller.dart
//
// Architecture :
//   1. loadSpace()          → GET /spaces/{id} ou mock
//                             Récupère le SpaceModel avec ses catégories (sans médias)
//
//   2. loadCategoryMedias() → GET /media-categories/{categoryId}?per_page=50
//                             Appelé à chaque changement d'onglet (lazy loading)
//                             Les médias sont mis en cache dans _loadedCategoryIds
//                             pour éviter de re-fetcher à chaque retour sur un onglet

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/space_model.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

class SpaceController extends GetxController {
  // ── État ───────────────────────────────────────────────────────────────────
  final space = Rxn<SpaceModel>();
  final isLoading = true.obs;
  final selectedCategoryIndex = 0.obs;

  /// IDs des catégories dont les médias ont déjà été chargés (cache)
  final _loadedCategoryIds = <int>{};

  /// Loading par catégorie (id → true/false)
  final categoryLoading = <int, bool>{}.obs;

    final isSingleColumn = false.obs;
  void toggleLayout() => isSingleColumn.value = !isSingleColumn.value;

  // ── Paramètres de route ────────────────────────────────────────────────────
  late final int spaceId;

  int get initialCategoryIndex {
    final param = Get.parameters['categoryIndex'];
    return int.tryParse(param ?? '') ?? 0;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  INIT
  // ══════════════════════════════════════════════════════════════════════════

  @override
  void onInit() {
    super.onInit();
    final idParam = Get.parameters['id'] ?? '0';
    spaceId = int.tryParse(idParam) ?? 0;
    selectedCategoryIndex.value = initialCategoryIndex;
    loadSpace();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOAD SPACE (catégories seulement, pas de médias)
  //  Route : GET /spaces/{id}   ou   GET /spaces  selon l'API
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> loadSpace() async {
    isLoading.value = true;
    _loadedCategoryIds.clear();

    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
        space.value = _mockSpace();
      } else {
        // L'API /spaces renvoie tous les espaces avec catégories (sans médias).
        // On filtre celui qui correspond au spaceId.
        // Si tu as une route /spaces/{id}, utilise-la directement.
        final r = await RequestService().get('/spaces');
        final list = (r.data['data']['spaces'] as List<dynamic>? ?? [])
            .map((j) => SpaceModel.fromJson(j as Map<String, dynamic>))
            .toList();
        try {
          space.value = list.firstWhere((s) => s.id == spaceId);
        } catch (_) {
          // Si non trouvé, prendre le premier
          space.value = list.isNotEmpty ? list.first : null;
        }
      }

      // Charger les médias de la catégorie initiale dès l'ouverture
      if (space.value != null &&
          space.value!.categories.isNotEmpty) {
        final safeIndex = initialCategoryIndex.clamp(
            0, space.value!.categories.length - 1);
        selectedCategoryIndex.value = safeIndex;
        await loadCategoryMedias(
            space.value!.categories[safeIndex].id);
      }
    } catch (e) {
      debugPrint('SpaceController.loadSpace error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOAD CATEGORY MEDIAS (lazy, avec cache)
  //  Route : GET /media-categories/{categoryId}?per_page=50
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> loadCategoryMedias(int categoryId) async {
    // Déjà chargé → on ne re-fetche pas
    if (_loadedCategoryIds.contains(categoryId)) return;

    categoryLoading[categoryId] = true;

    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 350));
        final videos = _mockVideosForCategory(categoryId);
        _applyCategoryVideos(categoryId, videos);
      } else {
        final r = await RequestService()
            .get('/media-categories/$categoryId?per_page=50');

        final data = r.data['data'] as Map<String, dynamic>;
        final mediasJson = data['medias'] as List<dynamic>? ?? [];
        final videos = mediasJson
            .map((m) => SpaceVideo.fromJson(m as Map<String, dynamic>))
            .toList();

        _applyCategoryVideos(categoryId, videos);
      }

      _loadedCategoryIds.add(categoryId);
    } catch (e) {
      debugPrint('SpaceController.loadCategoryMedias error (cat=$categoryId): $e');
    } finally {
      categoryLoading[categoryId] = false;
    }
  }

  /// Applique les médias chargés dans la catégorie correspondante du SpaceModel
  void _applyCategoryVideos(int categoryId, List<SpaceVideo> videos) {
    final current = space.value;
    if (current == null) return;

    final catIndex =
        current.categories.indexWhere((c) => c.id == categoryId);
    if (catIndex == -1) return;

    final updatedCat =
        current.categories[catIndex].copyWithVideos(videos);
    space.value = current.withUpdatedCategory(updatedCat);
  }

  // ── Appelé par le TabController quand l'onglet change ─────────────────────
  void onCategorySelected(int tabIndex) {
    selectedCategoryIndex.value = tabIndex;
    final cats = space.value?.categories;
    if (cats == null || tabIndex >= cats.length) return;
    loadCategoryMedias(cats[tabIndex].id);
  }

  void selectCategory(int index) => onCategorySelected(index);

  // ── Forcer le rechargement d'une catégorie (pull-to-refresh) ──────────────
  Future<void> reloadCategory(int categoryId) async {
    _loadedCategoryIds.remove(categoryId);
    await loadCategoryMedias(categoryId);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MOCKS
  // ══════════════════════════════════════════════════════════════════════════

  SpaceModel _mockSpace() {
    return SpaceModel(
      id: spaceId > 0 ? spaceId : 1,
      title: 'Grand Public Bénin',
      description: 'Le meilleur des contenus vidéo du Bénin.',
      logoUrl: null,
      previewVideoUrl: null,
      isActive: true,
      categories: [
        SpaceCategory(
            id: 1, title: 'Portrait', description: 'Portraits inspirants'),
        SpaceCategory(
            id: 2, title: 'Event', description: 'Les grands événements'),
        SpaceCategory(
            id: 3, title: 'Music', description: 'Clips et concerts'),
      ],
    );
  }

  List<SpaceVideo> _mockVideosForCategory(int categoryId) {
    final data = {
      1: [
        SpaceVideo(
          id: 3,
          title: 'Mr Beast',
          description: 'fff',
          thumbnail: 'https://img.youtube.com/vi/3OFj6l2tQ9s/hqdefault.jpg',
          videoUrl: 'https://www.youtube.com/watch?v=3OFj6l2tQ9s',
          youtubeId: '3OFj6l2tQ9s',
          isPremium: false,
          canRead: true,
          isLive: true,
          liveStartsAt: DateTime.now().subtract(const Duration(hours: 1)),
          liveEndsAt: DateTime.now().add(const Duration(days: 6)),
          publicationDate: '2026-04-23 16:19:07',
        ),
        SpaceVideo(
          id: 2,
          title: 'Mari Oloiu',
          description: 'Mjduof',
          thumbnail: 'https://img.youtube.com/vi/eNG_hpiDYbA/hqdefault.jpg',
          videoUrl: 'https://www.youtube.com/watch?v=eNG_hpiDYbA',
          youtubeId: 'eNG_hpiDYbA',
          isPremium: false,
          canRead: true,
          publicationDate: '2026-04-23 16:17:08',
        ),
        SpaceVideo(
          id: 1,
          title: 'Intro a la Migratoui',
          description: 'Malkdui fjfhyfi fyfyfidd fbfhdyfgd dfgdfdd',
          thumbnail: 'https://img.youtube.com/vi/tvYSnXC6CfY/hqdefault.jpg',
          videoUrl: 'https://www.youtube.com/watch?v=tvYSnXC6CfY',
          youtubeId: 'tvYSnXC6CfY',
          isPremium: true,
          ppvPrice: 500,
          canRead: false,
          publicationDate: '2026-04-23 16:16:29',
        ),
      ],
      2: [
        SpaceVideo(
          id: 10,
          title: 'WELOVeya 2024 - Cotonou',
          description: 'Le concert de l\'année',
          thumbnail: 'https://img.youtube.com/vi/3shs6DYjXtY/hqdefault.jpg',
          videoUrl: 'https://www.youtube.com/watch?v=3shs6DYjXtY',
          youtubeId: '3shs6DYjXtY',
          isPremium: true,
          ppvPrice: 1000,
          canRead: true,
          publicationDate: '2026-04-20 10:00:00',
        ),
      ],
      3: [
        SpaceVideo(
          id: 20,
          title: 'Dadju - Live Performance',
          description: 'Clip officiel',
          thumbnail: 'https://img.youtube.com/vi/R_HVJUUtNMc/hqdefault.jpg',
          videoUrl: 'https://www.youtube.com/watch?v=R_HVJUUtNMc',
          youtubeId: 'R_HVJUUtNMc',
          isPremium: false,
          canRead: true,
          publicationDate: '2026-04-15 08:00:00',
        ),
      ],
    };
    return data[categoryId] ?? [];
  }
}