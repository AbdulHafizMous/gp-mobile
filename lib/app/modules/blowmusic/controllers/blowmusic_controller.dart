// lib/app/modules/blowmusic/controllers/blowmusic_controller.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/fullscreen_ad_page.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

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
  BlowMusicTab('Bibliothèque', 'library'),
  BlowMusicTab('Playlists', 'playlist'),
];

class BlowMusicController extends GetxController {
  final currentTab = 0.obs;
  final isLoading = true.obs;
  final liveStream = Rxn<Map<String, dynamic>>();
  final latestTracks = <BmTrack>[].obs;
  final mostPlayed = <BmTrack>[].obs;
  final player = AudioPlayer();
  final currentTrack = Rxn<BmTrack>();
  final isPlaying = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadHome();
    WidgetsBinding.instance.addPostFrameCallback((_) => maybeShowFullscreenAd());
    player.onPlayerStateChanged.listen((s) => isPlaying.value = s == PlayerState.playing);
  }

  void changeTab(int i) => currentTab.value = i;

  Future<void> loadHome() async {
    isLoading.value = true;
    try {
      final res = await RequestService().get('/blowmusic/home');
      final data = res.data?['data'];
      liveStream.value = data?['live'];
      latestTracks.assignAll((data?['latest_tracks'] as List<dynamic>? ?? []).map((j) => BmTrack.fromJson(j)));
      mostPlayed.assignAll((data?['most_played'] as List<dynamic>? ?? []).map((j) => BmTrack.fromJson(j)));
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> playTrack(BmTrack track) async {
    currentTrack.value = track;
    await player.play(UrlSource(track.audioUrl));
    RequestService().post('/blowmusic/tracks/${track.id}/play');
  }

  Future<void> togglePlayPause() async {
    if (isPlaying.value) {
      await player.pause();
    } else if (currentTrack.value != null) {
      await player.resume();
    }
  }

  Future<void> playLive() async {
    final url = liveStream.value?['stream_url']?.toString();
    if (url == null) return;
    currentTrack.value = null;
    await player.play(UrlSource(url));
  }

  Future<void> switchToGrandPublic() async {
    await AppModeService.setMode(AppMode.grandPublic);
    Get.offAllNamed('/home');
  }

  @override
  void onClose() {
    player.dispose();
    super.onClose();
  }
}
