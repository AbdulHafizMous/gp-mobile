// lib/app/modules/social/controllers/dating_controller.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/models/dating_models.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

class DatingController extends GetxController {
  // ── State ──────────────────────────────────────────────────────────────────
  final suggestions   = <DatingProfile>[].obs;
  final likedProfiles = <DatingProfile>[].obs;
  final matches       = <DatingMatch>[].obs;
  final isLoading     = false.obs;
  final isSubmitting  = false.obs;
  final isPrefsLoading = false.obs;
  final preferences   = Rxn<DatingPreferences>();

  final currentIndex = 0.obs;
  final newMatch     = Rxn<DatingProfile>();

  // Préférences form
  final selectedLookingFor = RxnString();
  final minAge = 18.obs;
  final maxAge = 40.obs;

  // ─────────────────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    // 1. Charger d'abord le cache local pour UX immédiate
    _loadPreferencesFromStorage();
    // 2. Charger depuis le backend (source de vérité)
    await loadPreferencesFromBackend();
    // 3. Si prefs configurées, charger les suggestions
    if (hasPreferences) {
      loadSuggestions();
      loadLikedProfiles();
      loadMatches();
    }
  }

  void _loadPreferencesFromStorage() {
    final stored = GetStorage().read<Map>('dating_prefs');
    if (stored != null) {
      final prefs = DatingPreferences(
        lookingFor: stored['looking_for']?.toString(),
        minAge:     stored['min_age'] as int?,
        maxAge:     stored['max_age'] as int?,
        isActive:   stored['is_active'] as bool? ?? true,
      );
      preferences.value = prefs;
      _syncFormFromPrefs(prefs);
    }
  }

  bool get hasPreferences => preferences.value?.isConfigured ?? false;

  // ─────────────────────────────────────────────────────────────────────────
  // PREFERENCES — BACKEND
  // ─────────────────────────────────────────────────────────────────────────

  /// Charge les préférences depuis le backend et met à jour le cache local
  Future<void> loadPreferencesFromBackend() async {
    isPrefsLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 300));
        return;
      }
      final r = await RequestService().get('/dating/preferences');
      final data = r.data['data'];
      if (data != null) {
        final prefs = DatingPreferences.fromJson(data as Map<String, dynamic>);
        preferences.value = prefs;
        _syncFormFromPrefs(prefs);
        // Mettre à jour le cache local
        GetStorage().write('dating_prefs', prefs.toJson());
      }
    } on DioException catch (e) {
      // 404 = pas encore de prefs — pas une erreur
      if (e.response?.statusCode != 404) {
        debugPrint('loadPreferences error: $e');
      }
    } finally {
      isPrefsLoading.value = false;
    }
  }

  void _syncFormFromPrefs(DatingPreferences prefs) {
    selectedLookingFor.value = prefs.lookingFor;
    minAge.value = prefs.minAge ?? 18;
    maxAge.value = prefs.maxAge ?? 40;
  }

  /// Sauvegarde les préférences côté backend ET dans le cache local
  Future<void> savePreferences() async {
    if (selectedLookingFor.value == null) {
      await ToastHelper.showToast(
        'Veuillez sélectionner une préférence',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }
    isSubmitting.value = true;
    try {
      final prefs = DatingPreferences(
        lookingFor: selectedLookingFor.value,
        minAge:     minAge.value,
        maxAge:     maxAge.value,
        isActive:   true,
      );

      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        // POST ou PUT selon l'existence
        final endpoint = '/dating/preferences';
        await RequestService().post(endpoint, data: prefs.toJson());
      }

      preferences.value = prefs;
      // Toujours sauvegarder en local aussi (cache)
      GetStorage().write('dating_prefs', prefs.toJson());

      await ToastHelper.showToast(
        'Préférences enregistrées !',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      // Recharger les suggestions avec les nouvelles prefs
      await loadSuggestions();
    } on DioException catch (e) {
      _handleDioError(e);
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUGGESTIONS
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadSuggestions() async {
    isLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 700));
        suggestions.value = _mockProfiles();
        currentIndex.value = 0;
        return;
      }
      final r = await RequestService().get('/dating/suggestions');
      final list = r.data['data'] as List<dynamic>;
      suggestions.value =
          list.map((e) => DatingProfile.fromJson(e as Map<String, dynamic>)).toList();
      currentIndex.value = 0;
    } on DioException catch (e) {
      _handleDioError(e);
    } finally {
      isLoading.value = false;
    }
  }

  DatingProfile? get currentProfile {
    if (suggestions.isEmpty || currentIndex.value >= suggestions.length) return null;
    return suggestions[currentIndex.value];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SWIPE ACTIONS
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> likeProfile(DatingProfile profile) async {
    _nextProfile();
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (profile.id % 3 == 0) {
          newMatch.value = profile;
          matches.add(DatingMatch(
            id: DateTime.now().millisecondsSinceEpoch,
            profile: profile,
            matchedAt: DateTime.now(),
          ));
        } else {
          likedProfiles.add(profile);
        }
        return;
      }
      final r = await RequestService().post('/dating/profiles/${profile.id}/like');
      final isMatch = r.data['data']?['is_match'] == true;
      if (isMatch) {
        newMatch.value = profile;
        await loadMatches();
      } else {
        likedProfiles.add(profile);
      }
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<void> skipProfile(DatingProfile profile) async {
    _nextProfile();
    if (useMock) return;
    try {
      await RequestService().post('/dating/profiles/${profile.id}/skip');
    } catch (_) {}
  }

  void _nextProfile() {
    if (currentIndex.value < suggestions.length - 1) {
      currentIndex.value++;
    } else {
      suggestions.clear();
    }
  }

  void dismissMatch() => newMatch.value = null;

  // ─────────────────────────────────────────────────────────────────────────
  // LIKED PROFILES
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadLikedProfiles() async {
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 500));
        likedProfiles.value = _mockProfiles().take(6).toList();
        return;
      }
      final r = await RequestService().get('/dating/likes');
      final list = r.data['data'] as List<dynamic>;
      likedProfiles.value =
          list.map((e) => DatingProfile.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('loadLikedProfiles error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MATCHES
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadMatches() async {
    try {
      if (useMock) return;
      final r = await RequestService().get('/dating/matches');
      final list = r.data['data'] as List<dynamic>;
      matches.value =
          list.map((e) => DatingMatch.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('loadMatches error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOCKS
  // ─────────────────────────────────────────────────────────────────────────
  List<DatingProfile> _mockProfiles() {
    const data = [
      {'name': 'Kadidjath dld_01', 'age': 23, 'city': 'Cotonou, Akpakpa', 'gender': 'female'},
      {'name': 'Dorcas_01',        'age': 21, 'city': 'Cotonou',          'gender': 'female'},
      {'name': 'Aicha B.',         'age': 25, 'city': 'Porto-Novo',        'gender': 'female'},
      {'name': 'Rachelle D.',      'age': 22, 'city': 'Parakou',           'gender': 'female'},
      {'name': 'Fatou T.',         'age': 20, 'city': 'Cotonou, Fidjrossè','gender': 'female'},
      {'name': 'Marie K.',         'age': 24, 'city': 'Abomey-Calavi',     'gender': 'female'},
    ];
    final femalePhotos = List.generate(12, (i) =>
        'https://randomuser.me/api/portraits/women/${i + 20}.jpg');
    final interests = [
      ['Musique', 'Voyage', 'Mode'],
      ['Sport', 'Cinéma', 'Cuisine'],
      ['Tech', 'Lecture', 'Danse'],
      ['Gaming', 'Art', 'Sorties'],
    ];

    return List.generate(data.length, (i) {
      final d = data[i];
      return DatingProfile(
        id:         i + 1,
        name:       d['name'] as String,
        age:        d['age'] as int,
        city:       d['city'] as String,
        bio:        'Passionnée de vie, j\'aime les rencontres sincères.',
        avatarUrl:  femalePhotos[i % femalePhotos.length],
        photos:     [femalePhotos[i % femalePhotos.length],
                     femalePhotos[(i + 1) % femalePhotos.length]],
        interests:  interests[i % interests.length],
        gender:     d['gender'] as String,
        distance:   (i + 1) * 2.5,
      );
    });
  }

  void _handleDioError(DioException e) {
    final msg = e.response != null
        ? 'Erreur ${e.response?.statusCode}'
        : e.message ?? 'Erreur réseau';
    ToastHelper.showToast(msg,
        backgroundColor: Colors.red, textColor: Colors.white);
  }
}