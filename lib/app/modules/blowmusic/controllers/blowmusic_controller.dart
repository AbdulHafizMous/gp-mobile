import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/blowmusic/widgets/fullscreen_video_page.dart';
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

  @override
  void onInit() {
    super.onInit();
    loadHome();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => maybeShowFullscreenAd(),
    );
  }

  void changeTab(int i) => currentTab.value = i;

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

    // Arrêter et détruire l'ancien contrôleur
    if (videoPlayerController != null) {
      await videoPlayerController!.pause();
      await videoPlayerController!.dispose();
      videoPlayerController = null;
    }

    final resolvedUrl = await _resolveStreamUrl(url);
    if (resolvedUrl == null) {
      playbackState.value = BmPlaybackState.error;
      return;
    }

    // Déterminer si le flux est susceptible d'être une vidéo / HLS
    final lowerUrl = resolvedUrl.toLowerCase();
    isVideo.value =
        lowerUrl.contains('.m3u8') ||
        lowerUrl.contains('.mp4') ||
        isLiveStream; // Les Lives sont traités comme potentiellement vidéo

    try {
      videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(resolvedUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await videoPlayerController!.initialize();

      // Écouteurs d'états
      videoPlayerController!.addListener(() {
        if (videoPlayerController == null) return;
        final v = videoPlayerController!.value;
        isPlaying.value = v.isPlaying;
        position.value = v.position;
        duration.value = v.duration;

        if (v.hasError) {
          playbackState.value = BmPlaybackState.error;
        } else if (v.isPlaying) {
          playbackState.value = BmPlaybackState.playing;
        } else if (!v.isPlaying && v.position > Duration.zero) {
          playbackState.value = BmPlaybackState.paused;
        }
      });

      await videoPlayerController!.play();
      playbackState.value = BmPlaybackState.playing;
    } catch (e) {
      playbackState.value = BmPlaybackState.error;
    }
  }

  /// Lancer la lecture d'un morceau
  Future<void> playTrack(BmTrack track) async {
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

  /// Lancer la lecture du Live
  Future<void> playLive() async {
    final rawUrl = liveStream.value?['stream_url']?.toString();
    if (rawUrl == null || rawUrl.isEmpty) {
      playbackState.value = BmPlaybackState.error;
      return;
    }

    currentTrack.value = null;
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

  /// Passer/Quitter le plein écran
  void toggleFullScreen(BuildContext context) {
    if (videoPlayerController == null ||
        !videoPlayerController!.value.isInitialized)
      return;

    isFullScreen.value = !isFullScreen.value;

    if (isFullScreen.value) {
      Get.to(
        () => const FullscreenVideoPage(),
        transition: Transition.fade,
        fullscreenDialog: true,
      );
    } else {
      if (Get.isDialogOpen == true ||
          Get.currentRoute.contains('FullscreenVideoPage')) {
        Get.back();
      }
    }
  }

  Future<void> switchToGrandPublic() async {
    await AppModeService.setMode(AppMode.grandPublic);
    Get.offAllNamed('/home');
  }

  @override
  void onClose() {
    videoPlayerController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.onClose();
  }
}
