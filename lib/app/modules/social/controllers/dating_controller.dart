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
  final suggestions    = <DatingProfile>[].obs;
  final likedProfiles  = <DatingProfile>[].obs;    // profils que j'ai likés (sans doublons)
  final matches        = <DatingMatch>[].obs;
  final isLoading      = false.obs;
  final isSubmitting   = false.obs;
  final isPrefsLoading = false.obs;
  final preferences    = Rxn<DatingPreferences>();

  final currentIndex = 0.obs;
  final newMatch     = Rxn<DatingProfile>();

  // IDs déjà swipés localement pour éviter les doublons avant sync backend
  final _swipedIds = <int>{};
  // IDs déjà dans likedProfiles pour éviter les doublons
  final _likedIds  = <int>{};

  // Prefs form
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
    _loadPreferencesFromStorage();
    await loadPreferencesFromBackend();
    if (hasPreferences) {
      await loadSuggestions();
      await loadLikedProfiles();
      await loadMatches();
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
  // PREFERENCES
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadPreferencesFromBackend() async {
    isPrefsLoading.value = true;
    try {
      if (useMock) { await Future.delayed(const Duration(milliseconds: 300)); return; }
      final r = await RequestService().get('/dating/preferences');
      final data = r.data['data'];
      if (data != null) {
        final prefs = DatingPreferences.fromJson(data as Map<String, dynamic>);
        preferences.value = prefs;
        _syncFormFromPrefs(prefs);
        GetStorage().write('dating_prefs', prefs.toJson());
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) debugPrint('loadPrefs error: $e');
    } finally { isPrefsLoading.value = false; }
  }

  void _syncFormFromPrefs(DatingPreferences prefs) {
    selectedLookingFor.value = prefs.lookingFor;
    minAge.value = prefs.minAge ?? 18;
    maxAge.value = prefs.maxAge ?? 40;
  }

  Future<void> savePreferences() async {
    if (selectedLookingFor.value == null) {
      ToastHelper.showToast('Veuillez sélectionner une préférence',
          backgroundColor: Colors.orange, textColor: Colors.white);
      return;
    }
    isSubmitting.value = true;
    try {
      final prefs = DatingPreferences(
        lookingFor: selectedLookingFor.value,
        minAge: minAge.value, maxAge: maxAge.value, isActive: true);
      if (!useMock) {
        await RequestService().post('/dating/preferences', data: prefs.toJson());
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      preferences.value = prefs;
      GetStorage().write('dating_prefs', prefs.toJson());
      ToastHelper.showToast('Préférences enregistrées !', backgroundColor: Colors.green, textColor: Colors.white);
      await loadSuggestions();
    } on DioException catch (e) { _handleDioError(e); }
    finally { isSubmitting.value = false; }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUGGESTIONS
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadSuggestions() async {
    isLoading.value = true;
    _swipedIds.clear(); // reset local swipe tracking
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 700));
        suggestions.value = _mockProfiles();
        currentIndex.value = 0;
        return;
      }
      final r = await RequestService().get('/dating/suggestions');
      final list = r.data['data'] as List<dynamic>;
      suggestions.value = list.map((e) => DatingProfile.fromJson(e as Map<String, dynamic>)).toList();
      currentIndex.value = 0;
    } on DioException catch (e) { _handleDioError(e); }
    finally { isLoading.value = false; }
  }

  DatingProfile? get currentProfile {
    if (suggestions.isEmpty || currentIndex.value >= suggestions.length) return null;
    return suggestions[currentIndex.value];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SWIPE — ANTI-DOUBLON
  // ─────────────────────────────────────────────────────────────────────────

  /// Like un profil. Ignore si déjà swipé localement.
  Future<void> likeProfile(DatingProfile profile) async {
    // Guard anti-doublon côté client
    if (_swipedIds.contains(profile.id)) return;
    _swipedIds.add(profile.id);

    _nextProfile();

    // Optimisme : ajouter aux likés sans doublon
    if (!_likedIds.contains(profile.id)) {
      _likedIds.add(profile.id);
      likedProfiles.add(profile);
    }

    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      // Simulation match (1 sur 3)
      if (profile.id % 3 == 0) {
        newMatch.value = profile;
        final match = DatingMatch(
          id: DateTime.now().millisecondsSinceEpoch,
          profile: profile,
          matchedAt: DateTime.now(),
        );
        if (!matches.any((m) => m.profile.id == profile.id)) {
          matches.add(match);
        }
      }
      return;
    }

    try {
      final r = await RequestService().post('/dating/profiles/${profile.id}/like');
      final isMatchResult = r.data['data']?['is_match'] == true;
      if (isMatchResult) {
        newMatch.value = profile;
        // Reload matches depuis le backend
        await loadMatches();
        // Retirer des "likés" car c'est un match
        likedProfiles.removeWhere((p) => p.id == profile.id);
        _likedIds.remove(profile.id);
      }
    } on DioException catch (e) {
      // En cas d'erreur, retirer l'optimisme
      likedProfiles.removeWhere((p) => p.id == profile.id);
      _likedIds.remove(profile.id);
      _swipedIds.remove(profile.id);
      _handleDioError(e);
    }
  }

  Future<void> skipProfile(DatingProfile profile) async {
    if (_swipedIds.contains(profile.id)) return;
    _swipedIds.add(profile.id);
    _nextProfile();
    if (useMock) return;
    try { await RequestService().post('/dating/profiles/${profile.id}/skip'); } catch (_) {}
  }

  void _nextProfile() {
    if (currentIndex.value < suggestions.length - 1) {
      currentIndex.value++;
    } else {
      suggestions.clear();
      currentIndex.value = 0;
    }
  }

  void dismissMatch() => newMatch.value = null;

  // ─────────────────────────────────────────────────────────────────────────
  // LIKED PROFILES — chargement backend avec déduplication
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadLikedProfiles() async {
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 500));
        final profiles = _mockProfiles().take(4).toList();
        _likedIds.clear();
        for (final p in profiles) { _likedIds.add(p.id); }
        likedProfiles.value = profiles;
        return;
      }
      final r = await RequestService().get('/dating/likes');
      final list = r.data['data'] as List<dynamic>;
      final profiles = list.map((e) => DatingProfile.fromJson(e as Map<String, dynamic>)).toList();
      // Déduplication
      final seen = <int>{};
      final deduped = <DatingProfile>[];
      for (final p in profiles) {
        if (!seen.contains(p.id)) { seen.add(p.id); deduped.add(p); }
      }
      _likedIds.clear();
      _likedIds.addAll(seen);
      likedProfiles.value = deduped;
    } catch (e) { debugPrint('loadLikedProfiles error: $e'); }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MATCHES
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadMatches() async {
    try {
      if (useMock) return;
      final r = await RequestService().get('/dating/matches');
      final list = r.data['data'] as List<dynamic>;
      matches.value = list.map((e) => DatingMatch.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) { debugPrint('loadMatches error: $e'); }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOCKS
  // ─────────────────────────────────────────────────────────────────────────
  List<DatingProfile> _mockProfiles() {
    const data = [
      {'id':1, 'name': 'Kadidjath D.', 'age': 23, 'city': 'Cotonou, Akpakpa', 'gender': 'female',
        'bio': 'Passionnée de mode et de musique. Aime les sorties culturelles.'},
      {'id':2, 'name': 'Dorcas K.',    'age': 21, 'city': 'Cotonou',          'gender': 'female',
        'bio': 'Étudiante en droit. Amour de la lecture et des voyages.'},
      {'id':3, 'name': 'Aicha B.',     'age': 25, 'city': 'Porto-Novo',       'gender': 'female',
        'bio': 'Chef cuisinière. Fan de gastronomie africaine.'},
      {'id':4, 'name': 'Rachelle D.', 'age': 22, 'city': 'Parakou',          'gender': 'female',
        'bio': 'Sportive et dynamique. Football et danse.'},
      {'id':5, 'name': 'Fatou T.',     'age': 20, 'city': 'Fidjrossè',        'gender': 'female',
        'bio': 'Artiste peintre. Adore les musées.'},
      {'id':6, 'name': 'Marie K.',     'age': 24, 'city': 'Abomey-Calavi',    'gender': 'female',
        'bio': 'Entrepreneuse. Tech et innovation.'},
    ];
    final photos = List.generate(12, (i) => 'https://randomuser.me/api/portraits/women/${i+20}.jpg');
    final interests = [
      ['Musique', 'Voyage', 'Mode'],
      ['Sport', 'Cinéma', 'Cuisine'],
      ['Tech', 'Lecture', 'Danse'],
      ['Gaming', 'Art', 'Sorties'],
    ];
    return List.generate(data.length, (i) {
      final d = data[i];
      return DatingProfile(
        id:        d['id'] as int,
        name:      d['name'] as String,
        age:       d['age'] as int,
        city:      d['city'] as String,
        bio:       d['bio'] as String,
        avatarUrl: photos[i % photos.length],
        photos:    [photos[i % photos.length], photos[(i+1) % photos.length]],
        interests: interests[i % interests.length],
        gender:    d['gender'] as String,
        distance:  (i + 1) * 2.5,
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ANNUAIRE DES UTILISATEURS — remplace l'onglet "Likés"
  // ─────────────────────────────────────────────────────────────────────────
  final directoryUsers = <Map<String, dynamic>>[].obs;
  final isDirectoryLoading = false.obs;
  final directorySearchCtrl = TextEditingController();

  Future<void> loadDirectoryUsers({String? search}) async {
    isDirectoryLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
        directoryUsers.value = [];
        return;
      }
      final r = await RequestService().get(
        '/social/users',
        queryParameters: (search != null && search.isNotEmpty) ? {'search': search} : null,
      );
      directoryUsers.value = List<Map<String, dynamic>>.from(r.data['data'] as List);
    } catch (e) {
      debugPrint('loadDirectoryUsers error: $e');
    } finally {
      isDirectoryLoading.value = false;
    }
  }

  void _handleDioError(DioException e) {
    final msg = e.response != null ? 'Erreur ${e.response?.statusCode}' : e.message ?? 'Erreur réseau';
    ToastHelper.showToast(msg, backgroundColor: Colors.red, textColor: Colors.white);
  }
}