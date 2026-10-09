import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/components/live_fullscreen_page.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

import 'package:grand_public_v2/app/components/fullscreen_ad_page.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/services/recent_history_service.dart';

class BmTrack {
  final int id;
  final String title;
  final String? artistName;
  final String? coverUrl;
  final String audioUrl;

  BmTrack.fromJson(Map<String, dynamic> j)
    : id = j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      title = j['title']?.toString() ?? '',
      artistName = j['artist']?['name']?.toString(),
      coverUrl = j['cover_url']?.toString(),
      audioUrl = j['audio_url']?.toString() ?? '';
}

int _bmInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

class BmPlaylistInfo {
  final int id;
  String name;
  int count;
  bool isPublic;
  bool hasTrack;
  BmPlaylistInfo.fromJson(Map<String, dynamic> j)
    : id = _bmInt(j['id']),
      name = j['name']?.toString() ?? '',
      count = _bmInt(j['items_count']),
      isPublic = j['is_public'] == true || j['is_public'] == 1,
      hasTrack = j['has_track'] == true;
}

class BlowMusicTab {
  final String label;
  final String icon;
  const BlowMusicTab(this.label, this.icon);
}

const List<BlowMusicTab> kBlowMusicTabs = [
  BlowMusicTab('Accueil', 'home'),
  BlowMusicTab('Live', 'live'),
  BlowMusicTab('Biblio', 'library'),
  BlowMusicTab('Playlists', 'playlist'),
  BlowMusicTab('Favoris', 'favorite'),
];

enum BmPlaybackState { idle, loading, playing, paused, error }

class BlowMusicController extends GetxController {
  final currentTab = 0.obs;
  final isLoading = true.obs;
  final hasError = false.obs;

  final liveStream = Rxn<Map<String, dynamic>>();
  final latestTracks = <BmTrack>[].obs;
  final mostPlayed = <BmTrack>[].obs;

  // Lecteur universel VideoPlayer (Lecteur vidéo + audio HLS/MP3)
  VideoPlayerController? videoPlayerController;

  final currentTrack = Rxn<BmTrack>();
  final isPlayingLive = false.obs;
  final isPlaying = false.obs;
  final isVideo = false.obs; // Indique si le flux contient de la vidéo
  final isFullScreen = false.obs;
  final playbackState = BmPlaybackState.idle.obs;

  // Progression de lecture
  final position = Duration.zero.obs;
  final duration = Duration.zero.obs;

  // File de lecture, aléatoire, répétition (0 = off, 1 = tout, 2 = titre)
  final queue = <BmTrack>[].obs;
  final queueIndex = (-1).obs;
  final shuffle = false.obs;
  final repeatMode = 0.obs;
  String? queueLabel;
  final List<int> _history = [];
  bool _endHandled = false;

  // Favoris, playlists, bibliothèque paginée
  final favoriteIds = <int>{}.obs;
  // Titres favoris complets (onglet « Favoris »), du plus récent au plus ancien.
  final favoriteTracks = <BmTrack>[].obs;
  final favoritesLoading = false.obs;
  final playlists = <BmPlaylistInfo>[].obs;
  final playlistsLoading = false.obs;
  final libraryTracks = <BmTrack>[].obs;
  final libraryLoading = false.obs;
  int _libPage = 1;
  bool _libMore = true;
  String _libSearch = '';
  Timer? _libDebounce;

  @override
  void onInit() {
    super.onInit();
    loadHome();
    loadFavorites();
    loadPlaylists();
    loadLibrary(reset: true);
    // Ouverture depuis une notification : onglet demandé (live / library…).
    final args = Get.arguments;
    if (args is Map && args['tab'] != null) {
      final i = kBlowMusicTabs.indexWhere((t) => t.icon == args['tab']);
      if (i >= 0) currentTab.value = i;
    }
    // Réactivité du direct : l'admin peut activer/couper un flux à tout moment.
    _livePoll = Timer.periodic(const Duration(seconds: 15), (_) => refreshLive());
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => maybeShowFullscreenAd(),
    );
  }

  Timer? _livePoll;

  void changeTab(int i) {
    currentTab.value = i;
    // Onglet Favoris : rafraîchit la liste à chaque ouverture.
    if (i == 4) loadFavorites();
  }

  /// Interroge l'API (léger). Si le direct change (nouveau flux, ou coupé) :
  ///  - on met à jour l'écran immédiatement ;
  ///  - si l'utilisateur écoutait l'ancien direct → bascule AUTOMATIQUE sur
  ///    le nouveau (ou arrêt propre si plus aucun direct).
  Future<void> refreshLive() async {
    try {
      final res = await RequestService().get('/blowmusic/live');
      final raw = res.data?['data']?['live'];
      final next = raw is Map ? Map<String, dynamic>.from(raw) : null;
      final oldId = liveStream.value?['id'];
      final newId = next?['id'];
      if (oldId == newId) return;

      liveStream.value = next;
      if (isPlayingLive.value) {
        if (next == null) {
          await stopLive();
        } else {
          await playLive();
        }
      }
    } catch (_) {}
  }

  /// Détache d'abord le contrôleur de l'UI (VideoPlayer, plein écran), laisse
  /// l'arbre se reconstruire, PUIS seulement le détruit : évite l'erreur
  /// « used after being disposed » quand le flux change en pleine lecture.
  Future<void> _releasePlayer() async {
    final old = videoPlayerController;
    if (old == null) return;
    if (isFullScreen.value && (Get.key.currentState?.canPop() ?? false)) {
      Get.back();
      isFullScreen.value = false;
    }
    videoPlayerController = null;
    isVideo.value = false;
    isPlaying.value = false;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    await Future.delayed(const Duration(milliseconds: 120));
    try {
      await old.pause();
    } catch (_) {}
    try {
      await old.dispose();
    } catch (_) {}
  }

  Future<void> stopLive() async {
    await _releasePlayer();
    isPlayingLive.value = false;
    isPlaying.value = false;
    playbackState.value = BmPlaybackState.idle;
  }

  Future<void> loadHome() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final res = await RequestService().get('/blowmusic/home');
      final data = res.data?['data'];
      liveStream.value = data?['live'];
      latestTracks.assignAll(
        (data?['latest_tracks'] as List<dynamic>? ?? []).map(
          (j) => BmTrack.fromJson(j),
        ),
      );
      mostPlayed.assignAll(
        (data?['most_played'] as List<dynamic>? ?? []).map(
          (j) => BmTrack.fromJson(j),
        ),
      );
    } catch (_) {
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Analyse l'URL pour extraire un lien direct si c'est un fichier de playlist (.m3u / .pls)
  Future<String?> _resolveStreamUrl(String url) async {
    final lower = url.toLowerCase();
    if (!lower.endsWith('.m3u') && !lower.endsWith('.pls')) {
      return url; // Retourne directement si .m3u8, .mp3, .aac, .mp4, etc.
    }
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final lines = res.body.split(RegExp(r'[\r\n]+'));
      if (lower.endsWith('.pls')) {
        final fileLine = lines.firstWhere(
          (l) => l.trim().toLowerCase().startsWith('file1='),
          orElse: () => '',
        );
        if (fileLine.isEmpty) return null;
        return fileLine.split('=').skip(1).join('=').trim();
      }
      final firstUrl = lines
          .map((l) => l.trim())
          .firstWhere(
            (l) => l.isNotEmpty && !l.startsWith('#'),
            orElse: () => '',
          );
      return firstUrl.isEmpty ? null : firstUrl;
    } catch (_) {
      return null;
    }
  }

  /// Initialise le lecteur avec une URL
  Future<void> _initPlayer(String url, {required bool isLiveStream}) async {
    playbackState.value = BmPlaybackState.loading;

    // Arrêter et détruire l'ancien contrôleur (en douceur, voir _releasePlayer)
    await _releasePlayer();

    final resolvedUrl = await _resolveStreamUrl(url);
    if (resolvedUrl == null) {
      playbackState.value = BmPlaybackState.error;
      return;
    }

    // Déterminer si le flux est susceptible d'être une vidéo / HLS
    final lowerUrl = resolvedUrl.toLowerCase();
    final liveIsAudio = isLiveStream && liveStream.value?['media_type'] == 'audio';
    isVideo.value =
        !liveIsAudio &&
        (lowerUrl.contains('.m3u8') || lowerUrl.contains('.mp4') || isLiveStream);

    try {
      final ctl = VideoPlayerController.networkUrl(
        Uri.parse(resolvedUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      videoPlayerController = ctl;

      await ctl.initialize();
      if (videoPlayerController != ctl) {
        // Un autre flux a été lancé pendant l'initialisation.
        await ctl.dispose();
        return;
      }

      // Écouteurs d'états
      ctl.addListener(() {
        if (videoPlayerController != ctl) return;
        final v = ctl.value;
        isPlaying.value = v.isPlaying;
        position.value = v.position;
        duration.value = v.duration;

        if (!isPlayingLive.value &&
            !_endHandled &&
            v.duration > Duration.zero &&
            v.position >= v.duration - const Duration(milliseconds: 300)) {
          _endHandled = true;
          next(auto: true);
          return;
        }

        if (v.hasError) {
          playbackState.value = BmPlaybackState.error;
        } else if (v.isPlaying) {
          playbackState.value = BmPlaybackState.playing;
        } else if (!v.isPlaying && v.position > Duration.zero) {
          playbackState.value = BmPlaybackState.paused;
        }
      });

      await ctl.play();
      playbackState.value = BmPlaybackState.playing;
    } catch (e) {
      playbackState.value = BmPlaybackState.error;
    }
  }

  /// Lancer la lecture d'un morceau
  Future<void> playTrack(BmTrack track, {List<BmTrack>? queue, String? label}) async {
    if (queue != null) {
      this.queue.assignAll(queue);
      queueLabel = label;
      _history.clear();
    } else if (!this.queue.any((t) => t.id == track.id)) {
      this.queue.assignAll([track]);
      queueLabel = null;
    }
    queueIndex.value = this.queue.indexWhere((t) => t.id == track.id);
    _endHandled = false;
    currentTrack.value = track;
    isPlayingLive.value = false;

    await _initPlayer(track.audioUrl, isLiveStream: false);

    if (playbackState.value == BmPlaybackState.playing) {
      RecentHistoryService.addRecentTrack(
        id: track.id,
        title: track.title,
        artist: track.artistName,
        cover: track.coverUrl,
      );
      RequestService().post('/blowmusic/tracks/${track.id}/play');
    }
  }

  // ── File de lecture ──────────────────────────────────────────────────────
  Future<void> next({bool auto = false}) async {
    if (queue.isEmpty) return;
    if (auto && repeatMode.value == 2) {
      _endHandled = false;
      await seekTo(Duration.zero);
      await videoPlayerController?.play();
      return;
    }
    int n;
    if (shuffle.value && queue.length > 1) {
      final r = math.Random();
      do {
        n = r.nextInt(queue.length);
      } while (n == queueIndex.value);
    } else {
      n = queueIndex.value + 1;
      if (n >= queue.length) {
        if (repeatMode.value == 1 || !auto) {
          n = 0;
        } else {
          await videoPlayerController?.pause();
          await seekTo(Duration.zero);
          playbackState.value = BmPlaybackState.paused;
          return;
        }
      }
    }
    if (queueIndex.value >= 0) _history.add(queueIndex.value);
    await playTrack(queue[n]);
  }

  Future<void> previous() async {
    if (queue.length < 2 || position.value.inSeconds > 3) {
      await seekTo(Duration.zero);
      return;
    }
    final p = _history.isNotEmpty
        ? _history.removeLast()
        : (queueIndex.value - 1 + queue.length) % queue.length;
    await playTrack(queue[p]);
  }

  void toggleShuffle() => shuffle.value = !shuffle.value;
  void cycleRepeat() => repeatMode.value = (repeatMode.value + 1) % 3;

  void removeFromQueue(int i) {
    if (i < 0 || i >= queue.length || i == queueIndex.value) return;
    queue.removeAt(i);
    if (i < queueIndex.value) queueIndex.value--;
  }

  void reorderQueue(int oldI, int newI) {
    if (newI > oldI) newI--;
    final cur = currentTrack.value;
    final t = queue.removeAt(oldI);
    queue.insert(newI, t);
    if (cur != null) queueIndex.value = queue.indexWhere((x) => x.id == cur.id);
  }

  // ── Favoris ──────────────────────────────────────────────────────────────
  Future<void> loadFavorites() async {
    favoritesLoading.value = true;
    try {
      final res = await RequestService().get('/blowmusic/favorites');
      var list = res.data?['data'];
      // Tolère une réponse paginée {data: [...]}.
      if (list is Map && list['data'] is List) list = list['data'];
      if (list is List) {
        final tracks = <BmTrack>[];
        for (final j in list) {
          if (j is Map) tracks.add(BmTrack.fromJson(Map<String, dynamic>.from(j)));
        }
        favoriteTracks.assignAll(tracks);
        favoriteIds.assignAll(tracks.map((t) => t.id));
      }
    } catch (_) {
    } finally {
      favoritesLoading.value = false;
    }
  }

  Future<void> toggleFavorite(BmTrack t) async {
    final was = favoriteIds.contains(t.id);
    // Mise à jour optimiste des deux structures (ids + liste affichée).
    if (was) {
      favoriteIds.remove(t.id);
      favoriteTracks.removeWhere((x) => x.id == t.id);
    } else {
      favoriteIds.add(t.id);
      if (!favoriteTracks.any((x) => x.id == t.id)) favoriteTracks.insert(0, t);
    }
    try {
      await RequestService().post('/blowmusic/tracks/${t.id}/favorite');
    } catch (_) {
      if (was) {
        favoriteIds.add(t.id);
        favoriteTracks.insert(0, t);
      } else {
        favoriteIds.remove(t.id);
        favoriteTracks.removeWhere((x) => x.id == t.id);
      }
    }
  }

  // ── Bibliothèque (recherche + pagination) ────────────────────────────────
  void searchLibrary(String q) {
    _libDebounce?.cancel();
    _libDebounce = Timer(const Duration(milliseconds: 350), () {
      _libSearch = q.trim();
      loadLibrary(reset: true);
    });
  }

  Future<void> loadLibrary({bool reset = false}) async {
    if (libraryLoading.value) return;
    if (reset) {
      _libPage = 1;
      _libMore = true;
    }
    if (!_libMore) return;
    libraryLoading.value = true;
    try {
      final res = await RequestService().get(
        '/blowmusic/tracks',
        queryParameters: {'page': _libPage, if (_libSearch.isNotEmpty) 'search': _libSearch},
      );
      final d = res.data?['data'];
      final rows = (d?['data'] as List<dynamic>? ?? []).map((j) => BmTrack.fromJson(j)).toList();
      if (reset) libraryTracks.clear();
      libraryTracks.addAll(rows);
      _libMore = d?['next_page_url'] != null;
      _libPage++;
    } catch (_) {
    } finally {
      libraryLoading.value = false;
    }
  }

  // ── Playlists ────────────────────────────────────────────────────────────
  Future<void> loadPlaylists({int? forTrack}) async {
    playlistsLoading.value = true;
    try {
      final res = await RequestService().get(
        '/blowmusic/playlists',
        queryParameters: {if (forTrack != null) 'track_id': forTrack},
      );
      final list = res.data?['data'];
      if (list is List) {
        playlists.assignAll(list.map((j) => BmPlaylistInfo.fromJson(Map<String, dynamic>.from(j))));
      }
    } catch (_) {
    } finally {
      playlistsLoading.value = false;
    }
  }

  Future<BmPlaylistInfo?> createPlaylist(String name, {int? trackId}) async {
    try {
      final res = await RequestService().post(
        '/blowmusic/playlists',
        data: {'name': name, if (trackId != null) 'track_id': trackId},
      );
      final j = res.data?['data'];
      if (j is Map) {
        final p = BmPlaylistInfo.fromJson(Map<String, dynamic>.from(j));
        playlists.insert(0, p);
        return p;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> renamePlaylist(BmPlaylistInfo p, String name) async {
    try {
      await RequestService().put('/blowmusic/playlists/${p.id}', data: {'name': name});
      p.name = name;
      playlists.refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deletePlaylist(BmPlaylistInfo p) async {
    try {
      await RequestService().delete('/blowmusic/playlists/${p.id}');
      playlists.removeWhere((x) => x.id == p.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addToPlaylist(BmPlaylistInfo p, BmTrack t) async {
    try {
      await RequestService().post('/blowmusic/playlists/${p.id}/tracks', data: {'track_id': t.id});
      if (!p.hasTrack) p.count++;
      p.hasTrack = true;
      playlists.refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<BmTrack>> fetchPlaylistTracks(BmPlaylistInfo p) async {
    try {
      final res = await RequestService().get('/blowmusic/playlists/${p.id}/tracks');
      final list = res.data?['data'];
      if (list is List) return list.map((j) => BmTrack.fromJson(Map<String, dynamic>.from(j))).toList();
    } catch (_) {}
    return [];
  }

  Future<void> removeFromPlaylist(BmPlaylistInfo p, BmTrack t) async {
    try {
      await RequestService().delete('/blowmusic/playlists/${p.id}/tracks/${t.id}');
      if (p.count > 0) p.count--;
      playlists.refresh();
    } catch (_) {}
  }

  Future<void> savePlaylistOrder(BmPlaylistInfo p, List<BmTrack> tracks) async {
    try {
      await RequestService().put('/blowmusic/playlists/${p.id}/order', data: {'track_ids': tracks.map((t) => t.id).toList()});
    } catch (_) {}
  }

  /// Lancer la lecture du Live
  Future<void> playLive() async {
    final rawUrl = liveStream.value?['stream_url']?.toString();
    if (rawUrl == null || rawUrl.isEmpty) {
      playbackState.value = BmPlaybackState.error;
      return;
    }

    currentTrack.value = null;
    queueIndex.value = -1;
    isPlayingLive.value = true;

    await _initPlayer(rawUrl, isLiveStream: true);
  }

  /// Toggle Play / Pause
  Future<void> togglePlayPause() async {
    if (videoPlayerController == null) {
      if (isPlayingLive.value) {
        await playLive();
      } else if (currentTrack.value != null) {
        await playTrack(currentTrack.value!);
      }
      return;
    }

    if (videoPlayerController!.value.isPlaying) {
      await videoPlayerController!.pause();
      playbackState.value = BmPlaybackState.paused;
    } else {
      await videoPlayerController!.play();
      playbackState.value = BmPlaybackState.playing;
    }
  }

  /// Avancer/Reculer dans le morceau (Seek)
  Future<void> seekTo(Duration pos) async {
    if (videoPlayerController != null) {
      await videoPlayerController!.seekTo(pos);
    }
  }

  /// Plein écran : remplit tout l'écran (voir LiveFullscreenPage).
  void toggleFullScreen(BuildContext context) {
    final c = videoPlayerController;
    if (c == null || !c.value.isInitialized) return;
    isFullScreen.value = true;
    Get.to(
      () => LiveFullscreenPage(controller: c, title: liveStream.value?['title']?.toString() ?? 'Direct', isLive: isPlayingLive.value),
      transition: Transition.fade,
      fullscreenDialog: true,
    )?.then((_) => isFullScreen.value = false);
  }

  Future<void> switchToGrandPublic() async {
    await AppModeService.setMode(AppMode.grandPublic);
    Get.offAllNamed('/home');
  }

  @override
  void onClose() {
    _livePoll?.cancel();
    _libDebounce?.cancel();
    videoPlayerController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.onClose();
  }
}
