// Lecture Blowmusic en arrière-plan : pont entre le lecteur existant
// (VideoPlayerController, géré par BlowMusicController) et le système
// (notification média Android / centre de contrôle iOS / écran verrouillé).
// Le lecteur reste inchangé ; ce handler ne fait que refléter son état et
// relayer play / pause / suivant / précédent / seek / stop.
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;

class BmAudioHandler extends BaseAudioHandler with SeekHandler {
  VoidCallback? onPlayCb, onPauseCb, onNextCb, onPrevCb, onStopCb;
  ValueChanged<Duration>? onSeekCb;

  @override
  Future<void> play() async => onPlayCb?.call();
  @override
  Future<void> pause() async => onPauseCb?.call();
  @override
  Future<void> skipToNext() async => onNextCb?.call();
  @override
  Future<void> skipToPrevious() async => onPrevCb?.call();
  @override
  Future<void> seek(Duration position) async => onSeekCb?.call(position);
  @override
  Future<void> stop() async {
    onStopCb?.call();
    playbackState.add(playbackState.value.copyWith(processingState: AudioProcessingState.idle, playing: false));
    await super.stop();
  }
}

class BmAudioService {
  BmAudioService._();
  static BmAudioHandler? _handler;
  static Future<BmAudioHandler?>? _init;

  /// Initialisation paresseuse (au premier lancement d'un titre / du live).
  static Future<BmAudioHandler?> ensure() {
    return _init ??= () async {
      try {
        _handler = await AudioService.init(
          builder: () => BmAudioHandler(),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'com.maxafrica.gpbenin.blowmusic',
            androidNotificationChannelName: 'Blowmusic',
            androidNotificationIcon: 'drawable/ic_notification',
            androidNotificationOngoing: false,
            androidStopForegroundOnPause: false,
            notificationColor: Color(0xFFEB2040),
          ),
        );
      } catch (e) {
        debugPrint('BmAudioService.init: $e');
      }
      return _handler;
    }();
  }

  static void bind({
    required VoidCallback onPlay,
    required VoidCallback onPause,
    required VoidCallback onNext,
    required VoidCallback onPrev,
    required VoidCallback onStop,
    required ValueChanged<Duration> onSeek,
  }) {
    final h = _handler;
    if (h == null) return;
    h.onPlayCb = onPlay;
    h.onPauseCb = onPause;
    h.onNextCb = onNext;
    h.onPrevCb = onPrev;
    h.onStopCb = onStop;
    h.onSeekCb = onSeek;
  }

  static void setMedia({required String id, required String title, String? artist, String? cover, Duration? duration, bool live = false}) {
    _handler?.mediaItem.add(MediaItem(
      id: id,
      title: title,
      artist: artist ?? (live ? 'Direct' : null),
      artUri: (cover != null && cover.isNotEmpty) ? Uri.tryParse(cover) : null,
      duration: live ? null : duration,
      isLive: live,
    ));
  }

  static void setState({required bool playing, required bool loading, required Duration position, bool live = false, bool hasQueue = false}) {
    final h = _handler;
    if (h == null) return;
    h.playbackState.add(PlaybackState(
      controls: [
        if (hasQueue) MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        if (hasQueue) MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: live ? const {} : const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
      androidCompactActionIndices: hasQueue ? const [0, 1, 2] : const [0],
      processingState: loading ? AudioProcessingState.loading : AudioProcessingState.ready,
      playing: playing,
      updatePosition: position,
      speed: 1.0,
    ));
  }

  static void clear() {
    final h = _handler;
    if (h == null) return;
    h.playbackState.add(PlaybackState(processingState: AudioProcessingState.idle, playing: false));
  }
}
