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
  final suggestions = <DatingProfile>[].obs;   // pile de profils à swiper
  final likedProfiles = <DatingProfile>[].obs;  // profils aimés
  final matches = <DatingMatch>[].obs;           // matches mutuels
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final preferences = Rxn<DatingPreferences>();

  // Index actuel dans la pile
  final currentIndex = 0.obs;

  // Match dialog
  final newMatch = Rxn<DatingProfile>();

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
    _loadPreferencesFromStorage();
    loadSuggestions();
    loadLikedProfiles();
    loadMatches();
  }

  void _loadPreferencesFromStorage() {
    final stored = GetStorage().read<Map>('dating_prefs');
    if (stored != null) {
      preferences.value = DatingPreferences(
        lookingFor: stored['looking_for']?.toString(),
        minAge: stored['min_age'] as int?,
        maxAge: stored['max_age'] as int?,
      );
      selectedLookingFor.value = preferences.value?.lookingFor;
    }
  }

  bool get hasPreferences => preferences.value?.isConfigured ?? false;

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
      suggestions.value = list
          .map((e) => DatingProfile.fromJson(e as Map<String, dynamic>))
          .toList();
      currentIndex.value = 0;
    } on DioException catch (e) {
      _handleDioError(e);
    } finally {
      isLoading.value = false;
    }
  }

  DatingProfile? get currentProfile {
    if (suggestions.isEmpty || currentIndex.value >= suggestions.length) {
      return null;
    }
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
        // Simule un match aléatoire (1 chance sur 3)
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
      final r = await RequestService()
          .post('/dating/profiles/${profile.id}/like');
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
      likedProfiles.value = list
          .map((e) => DatingProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('loadLikedProfiles error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MATCHES
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadMatches() async {
    try {
      if (useMock) {
        // Mock: pas de matches initiaux (ils se créent via like)
        return;
      }
      final r = await RequestService().get('/dating/matches');
      final list = r.data['data'] as List<dynamic>;
      matches.value = list
          .map((e) => DatingMatch.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('loadMatches error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PREFERENCES
  // ─────────────────────────────────────────────────────────────────────────
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
        minAge: minAge.value,
        maxAge: maxAge.value,
      );
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        await RequestService().post('/dating/preferences', data: prefs.toJson());
      }
      preferences.value = prefs;
      GetStorage().write('dating_prefs', prefs.toJson());
      await loadSuggestions();
    } on DioException catch (e) {
      _handleDioError(e);
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOCKS
  // ─────────────────────────────────────────────────────────────────────────
  List<DatingProfile> _mockProfiles() {
    const data = [
      {'name': 'Kadidjath dld_01', 'age': 23, 'city': 'Cotonou, Akpakpa', 'gender': 'female'},
      {'name': 'Dorcas_01', 'age': 21, 'city': 'Cotonou', 'gender': 'female'},
      {'name': 'Aicha B.', 'age': 25, 'city': 'Porto-Novo', 'gender': 'female'},
      {'name': 'Rachelle D.', 'age': 22, 'city': 'Parakou', 'gender': 'female'},
      {'name': 'Fatou T.', 'age': 20, 'city': 'Cotonou, Fidjrossè', 'gender': 'female'},
      {'name': 'Marie K.', 'age': 24, 'city': 'Abomey-Calavi', 'gender': 'female'},
    ];
    // Photos de personnes africaines via randomuser
    final femalePhotos = List.generate(
      12,
      (i) => 'https://randomuser.me/api/portraits/women/${i + 20}.jpg',
    );
    final interests = [
      ['Musique', 'Voyage', 'Mode'],
      ['Sport', 'Cinéma', 'Cuisine'],
      ['Tech', 'Lecture', 'Danse'],
      ['Gaming', 'Art', 'Sorties'],
    ];

    return List.generate(data.length, (i) {
      final d = data[i];
      return DatingProfile(
        id: i + 1,
        name: d['name'] as String,
        age: d['age'] as int,
        city: d['city'] as String,
        bio: 'Passionnée de vie, j\'aime les rencontres sincères et les moments authentiques.',
        avatarUrl: femalePhotos[i % femalePhotos.length],
        photos: [
          femalePhotos[i % femalePhotos.length],
          femalePhotos[(i + 1) % femalePhotos.length],
        ],
        interests: interests[i % interests.length],
        gender: d['gender'] as String,
        distance: (i + 1) * 2.5,
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