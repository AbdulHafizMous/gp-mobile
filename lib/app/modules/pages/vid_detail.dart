// lib/app/modules/pages/vid_detail.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:grand_public_v2/app/data/models/space_model.dart';
import 'package:grand_public_v2/app/data/models/video_comment.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';
import 'package:grand_public_v2/app/modules/videos/controllers/videos_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/share_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get surface =>
      isDark ? const Color(0xFF111111) : GPTheme.primaryColor.withOpacity(0.05);
  Color get surface2 =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
  Color get surface3 =>
      isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEDEDED);
  Color get primaryLabel => isDark ? Colors.white : const Color(0xFF111111);
  Color get secondaryLabel =>
      isDark ? const Color(0xFF9A9A9A) : const Color(0xFF6B6B6B);
  Color get separator =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEAEAEA);
}

// ─────────────────────────────────────────────────────────────────────────────
// VID DETAIL
// ─────────────────────────────────────────────────────────────────────────────
class VidDetail extends StatefulWidget {
  const VidDetail({super.key, required this.video});
  final SpaceVideo video;

  @override
  State<VidDetail> createState() => _VidDetailState();
}

class _VidDetailState extends State<VidDetail> {
  late final VideosController ctrl;
  YoutubePlayerController? _ytCtrl;
  VideoPlayerController? _nativeCtrl; // vidéo hébergée sur notre serveur
  bool _playerReady = false;
  bool _showControls = true;

  final List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    ctrl = Get.find<VideosController>();
    ctrl.fetchComments(widget.video.id);
    _maybeInitPlayer(ctrl.currentVideo.value ?? widget.video);
  }

  String? _extractYoutubeId(String url) {
    final id = YoutubePlayer.convertUrlToId(url);
    if (id != null && id.isNotEmpty) return id;
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) return url;
    return null;
  }

  void _maybeInitPlayer(SpaceVideo video) {
    if (!video.canRead) return;

    // ── Vidéo hébergée directement sur notre serveur ──────────────────────
    if (video.sourceType == 'upload' &&
        video.videoFileUrl != null &&
        video.videoFileUrl!.isNotEmpty) {
      _initNativePlayer(video.videoFileUrl!);
      return;
    }

    // ── Vidéo YouTube (comportement existant) ─────────────────────────────
    final ytId = _extractYoutubeId(
      video.youtubeId.isNotEmpty ? video.youtubeId : video.videoUrl,
    );
    if (ytId == null) return;
    _initPlayer(ytId);
  }

  void _initNativePlayer(String url) {
    _ytCtrl?.dispose();
    _ytCtrl = null;
    _nativeCtrl?.dispose();
    _nativeCtrl = VideoPlayerController.networkUrl(Uri.parse(url))
      ..addListener(_onNativePlayerUpdate)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _playerReady = true);
        ctrl.totalDuration.value = _nativeCtrl!.value.duration;
      });
  }

  void _onNativePlayerUpdate() {
    if (!mounted || _nativeCtrl == null) return;
    final v = _nativeCtrl!.value;
    ctrl.isPlaying.value = v.isPlaying;
    ctrl.currentPosition.value = v.position;
    ctrl.totalDuration.value = v.duration;
  }

  void _initPlayer(String ytId) {
    _ytCtrl?.dispose();
    _ytCtrl = YoutubePlayerController(
      initialVideoId: ytId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        hideControls: true,
        enableCaption: false,
        forceHD: false,
      ),
    )..addListener(_onPlayerUpdate);
    setState(() => _playerReady = true);
  }

  void _onPlayerUpdate() {
    if (!mounted || _ytCtrl == null) return;
    final v = _ytCtrl!.value;
    ctrl.isPlaying.value = v.isPlaying;
    ctrl.currentPosition.value = v.position;
    ctrl.totalDuration.value = v.metaData.duration;
  }

  @override
  void dispose() {
    _ytCtrl?.removeListener(_onPlayerUpdate);
    _ytCtrl?.dispose();
    _nativeCtrl?.removeListener(_onNativePlayerUpdate);
    _nativeCtrl?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _togglePlay() {
    if (_nativeCtrl != null) {
      _nativeCtrl!.value.isPlaying ? _nativeCtrl!.pause() : _nativeCtrl!.play();
      return;
    }
    if (_ytCtrl == null) return;
    _ytCtrl!.value.isPlaying ? _ytCtrl!.pause() : _ytCtrl!.play();
  }

  void _toggleMute() {
    final muted = !ctrl.isMuted.value;
    ctrl.isMuted.value = muted;
    if (_nativeCtrl != null) {
      _nativeCtrl!.setVolume(muted ? 0 : 1);
      return;
    }
    muted ? _ytCtrl!.mute() : _ytCtrl!.unMute();
  }

  void _toggleFullscreen() {
    ctrl.isFullscreen.value = !ctrl.isFullscreen.value;
    if (ctrl.isFullscreen.value) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String _fmtCount(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        '',
        'Jan',
        'Fév',
        'Mar',
        'Avr',
        'Mai',
        'Juin',
        'Juil',
        'Aoû',
        'Sep',
        'Oct',
        'Nov',
        'Déc',
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  void _goToPremium() {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().navigateTo('/social-premium');
    } else {
      Get.toNamed('/social-premium');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isFullscreen.value) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: _playerArea(context, fullscreen: true),
        );
      }

      return Scaffold(
        backgroundColor: context.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Player (ratio fixe 16:9)
              _playerArea(context, fullscreen: false),

              // Contenu scrollable
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _videoInfo(context),
                      _actionBar(context),
                      Divider(height: 1, color: context.separator),
                      _commentsSection(context),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PLAYER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _playerArea(BuildContext context, {required bool fullscreen}) {
    final video = ctrl.currentVideo.value ?? widget.video;
    final double h = fullscreen
        ? MediaQuery.of(context).size.height
        : MediaQuery.of(context).size.width * 9 / 16;

    return SizedBox(
      width: double.infinity,
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),

          // Contenu
          if (!video.canRead)
            _lockedLayer(video)
          else if (_playerReady && _nativeCtrl != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _nativeCtrl!.value.size.width,
                height: _nativeCtrl!.value.size.height,
                child: VideoPlayer(_nativeCtrl!),
              ),
            )
          else if (_playerReady && _ytCtrl != null)
            YoutubePlayer(
              controller: _ytCtrl!,
              showVideoProgressIndicator: false,
              topActions: const [],
              bottomActions: const [],
              onReady: () => _ytCtrl!.addListener(_onPlayerUpdate),
              onEnded: (_) => ctrl.isPlaying.value = false,
            )
          else
            Image.network(
              video.thumbnail,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(color: Colors.black87),
            ),

          // Overlay contrôles
          if (video.canRead && _playerReady)
            _controlsOverlay(context, fullscreen: fullscreen),

          // Overlay premium
          if (!video.canRead)
            _PremiumOverlay(
              video: video,
              onPayPerView: () => _handlePPV(context, video),
              onSubscribe: _goToPremium,
            ),

          // Bouton retour
          Positioned(
            top: 8,
            left: 8,
            child: _CircleBtn(
              icon: fullscreen
                  ? Icons.fullscreen_exit_rounded
                  : Icons.arrow_back_ios_new_rounded,
              onTap: fullscreen ? _toggleFullscreen : Get.back,
            ),
          ),

          // Bouton partage — permet d'envoyer ce média à un ami
          if (!fullscreen)
            Positioned(
              top: 8,
              right: 8,
              child: _CircleBtn(
                icon: Icons.share_outlined,
                onTap: () => ShareHelper.showShareSheet(
                  context,
                  title: video.title,
                  type: 'media',
                  id: '${video.id}',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _lockedLayer(SpaceVideo v) => Stack(
    fit: StackFit.expand,
    children: [
      Image.network(
        v.thumbnail,
        fit: BoxFit.cover,
        color: Colors.black.withOpacity(0.5),
        colorBlendMode: BlendMode.darken,
        errorBuilder: (_, __, ___) => Container(color: Colors.black87),
      ),
    ],
  );

  Widget _controlsOverlay(BuildContext context, {required bool fullscreen}) {
    return Obx(
      () => GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 220),
          child: Stack(
            children: [
              // Gradient bas
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                ),
              ),

              // Bouton play central
              Center(
                child: GestureDetector(
                  onTap: _togglePlay,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      ctrl.isPlaying.value
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),

              // Barre bas
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _bottomControls(context, fullscreen: fullscreen),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomControls(BuildContext context, {required bool fullscreen}) {
    return Obx(() {
      final pos = ctrl.currentPosition.value;
      final dur = ctrl.totalDuration.value;
      final progress = dur.inMilliseconds > 0
          ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
          : 0.0;

      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 2.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: GPTheme.primaryColor,
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
              ),
              child: Slider(
                value: progress,
                onChanged: (v) {
                  final target = Duration(
                    milliseconds: (v * dur.inMilliseconds).round(),
                  );
                  if (_nativeCtrl != null) {
                    _nativeCtrl!.seekTo(target);
                  } else {
                    _ytCtrl?.seekTo(target);
                  }
                },
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: _togglePlay,
                  child: Icon(
                    ctrl.isPlaying.value
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_fmt(pos)} / ${_fmt(dur)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleMute,
                  child: Icon(
                    ctrl.isMuted.value
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showSpeedSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${ctrl.playbackSpeed.value}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _toggleFullscreen,
                  child: Icon(
                    fullscreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _showSpeedSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.separator,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Vitesse de lecture',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: context.primaryLabel,
                ),
              ),
            ),
            Obx(
              () => Column(
                children: _speeds.map((s) {
                  final active = ctrl.playbackSpeed.value == s;
                  return ListTile(
                    title: Text(
                      '${s}x${s == 1.0 ? '  (Normale)' : ''}',
                      style: TextStyle(
                        color: active
                            ? GPTheme.primaryColor
                            : context.primaryLabel,
                        fontWeight: active
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: active
                        ? Icon(
                            Icons.check_rounded,
                            color: GPTheme.primaryColor,
                            size: 18,
                          )
                        : null,
                    onTap: () {
                      ctrl.playbackSpeed.value = s;
                      if (_nativeCtrl != null) {
                        _nativeCtrl!.setPlaybackSpeed(s);
                      } else {
                        _ytCtrl?.setPlaybackRate(s);
                      }
                      Navigator.of(ctx).pop();
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  VIDEO INFO
  // ─────────────────────────────────────────────────────────────────────────

  Widget _videoInfo(BuildContext context) {
    return Obx(() {
      final v = ctrl.currentVideo.value ?? widget.video;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Titre ───────────────────────────────────────────────
            Text(
              v.title,
              style: TextStyle(
                color: context.primaryLabel,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1.3,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 10),

            // ── Ligne méta : espace · catégorie · date · LIVE/PREMIUM ─
            Wrap(
              spacing: 6,
              runSpacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Espace pill
                if (v.spaceName != null && v.spaceName!.isNotEmpty)
                  _TagPill(
                    label: v.spaceName!,
                    icon: Icons.dashboard_customize_outlined,
                    bgColor: GPTheme.primaryColor.withOpacity(0.10),
                    textColor: GPTheme.primaryColor,
                    borderColor: GPTheme.primaryColor.withOpacity(0.25),
                  ),

                // Catégorie pill
                if (v.categoryName != null && v.categoryName!.isNotEmpty)
                  _TagPill(
                    label: v.categoryName!,
                    icon: Icons.folder_outlined,
                    bgColor: context.surface3,
                    textColor: context.secondaryLabel,
                    borderColor: context.separator,
                  ),

                // LIVE pill
                if (v.isLiveNow)
                  _TagPill(
                    label: 'EN DIRECT',
                    icon: Icons.circle,
                    iconSize: 7,
                    bgColor: Colors.red.shade600,
                    textColor: Colors.white,
                    borderColor: Colors.transparent,
                    bold: true,
                  ),

                // PREMIUM pill
                if (v.isPremium && !v.isLiveNow)
                  _TagPill(
                    label: 'PREMIUM',
                    bgColor: Colors.amber.shade600,
                    textColor: Colors.white,
                    borderColor: Colors.transparent,
                    bold: true,
                  ),

                // Date
                if (v.publicationDate.isNotEmpty)
                  Text(
                    _fmtDate(v.publicationDate),
                    style: TextStyle(
                      color: context.secondaryLabel,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),

            // ── Description ──────────────────────────────────────────
            if (v.description != null && v.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ExpandableText(text: v.description!),
            ],

            const SizedBox(height: 4),
          ],
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ACTION BAR
  //  Canal logo + nom | spacer | views | like | dislike | save
  // ─────────────────────────────────────────────────────────────────────────

  Widget _actionBar(BuildContext context) {
    return Obx(() {
      final v = ctrl.currentVideo.value ?? widget.video;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            // Canal
            CircleAvatar(
              radius: 17,
              backgroundColor: GPTheme.primaryColor,
              backgroundImage:
                  (v.spaceLogoUrl != null && v.spaceLogoUrl!.isNotEmpty)
                  ? NetworkImage(v.spaceLogoUrl!)
                  : null,
              child: (v.spaceLogoUrl == null || v.spaceLogoUrl!.isEmpty)
                  ? const Text(
                      'GP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),

            // const SizedBox(width: 6),
            // Flexible(
            //   child: Text(
            //     v.spaceName ?? 'grandpublic',
            //     overflow: TextOverflow.ellipsis,
            //     maxLines: 2,
            //     style: TextStyle(
            //       color: GPTheme.primaryColor,
            //       fontWeight: FontWeight.w700,
            //       fontSize: 13,
            //     ),
            //   ),
            // ),
            const Spacer(),
            // Vues
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 15,
                  color: context.secondaryLabel,
                ),
                const SizedBox(width: 4),
                Text(
                  _fmtCount(v.views),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.secondaryLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            _Divider(),

            // Like
            _ActionChip(
              icon: v.isLiked
                  ? Icons.thumb_up_rounded
                  : Icons.thumb_up_alt_outlined,
              label: _fmtCount(v.likesCount),
              active: v.isLiked,
              onTap: () => ctrl.toggleLike(v.id),
            ),
            const SizedBox(width: 6),

            // Dislike
            _ActionChip(
              icon: v.isDisliked
                  ? Icons.thumb_down_rounded
                  : Icons.thumb_down_alt_outlined,
              label: _fmtCount(v.dislikesCount),
              active: v.isDisliked,
              activeColor: Colors.red,
              onTap: () => ctrl.toggleDislike(v.id),
            ),
            const SizedBox(width: 6),

            // Save
            _ActionChip(
              icon: v.isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_outline_rounded,
              label: 'Sauv.',
              showLabel: false,
              active: v.isSaved,
              onTap: () => ctrl.toggleSave(v.id),
            ),
          ],
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  COMMENTAIRES
  // ─────────────────────────────────────────────────────────────────────────

  Widget _commentsSection(BuildContext context) {
    return Obx(() {
      final v = ctrl.currentVideo.value ?? widget.video;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Row(
              children: [
                Text(
                  'Commentaires',
                  style: TextStyle(
                    color: context.primaryLabel,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: GPTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${ctrl.comments.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Indicateur réponse ────────────────────────────────────
          if (ctrl.replyingTo.value != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: GPTheme.primaryColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: GPTheme.primaryColor.withOpacity(0.22),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply_rounded,
                      size: 15,
                      color: GPTheme.primaryColor,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Répondre à ${ctrl.replyingTo.value!.userName}',
                        style: TextStyle(
                          color: GPTheme.primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ctrl.setReplyingTo(null),
                      child: Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: context.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Zone de saisie ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: context.surface2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.separator, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TextField
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: TextField(
                      controller: ctrl.commentController,
                      maxLines: 4,
                      minLines: 2,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.primaryLabel,
                        height: 1.45,
                      ),
                      decoration:
                          InputDecoration.collapsed(
                            hintText: 'Laissez un commentaire…',
                            hintStyle: TextStyle(
                              color: context.secondaryLabel,
                              fontSize: 14,
                            ),
                          ).copyWith(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: GPTheme.primaryColor.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: GPTheme.primaryColor.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: GPTheme.primaryColor.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: GPTheme.primaryColor.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                          ),
                    ),
                  ),

                  // Séparateur + bouton envoyer
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Annuler (si réponse active)
                        if (ctrl.replyingTo.value != null) ...[
                          GestureDetector(
                            onTap: () {
                              ctrl.setReplyingTo(null);
                              ctrl.commentController.clear();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                'Annuler',
                                style: TextStyle(
                                  color: context.secondaryLabel,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Bouton publier
                        Obx(
                          () => GestureDetector(
                            onTap: ctrl.isPostingComment.value
                                ? null
                                : () => ctrl.postComment(v.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: ctrl.isPostingComment.value
                                    ? context.separator
                                    : GPTheme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ctrl.isPostingComment.value
                                  ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: context.secondaryLabel,
                                      ),
                                    )
                                  : Row(
                                      // mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Commenter',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: context.separator),

          // ── Liste ─────────────────────────────────────────────────
          if (ctrl.isLoadingComments.value)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(
                  color: GPTheme.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (ctrl.comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 38,
                      color: context.secondaryLabel,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Aucun commentaire.\nSoyez le premier !',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.secondaryLabel,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: ctrl.comments.length,
              separatorBuilder: (_, __) =>
                  Divider(color: context.separator, height: 1),
              itemBuilder: (ctx, i) =>
                  _CommentTile(comment: ctrl.comments[i], ctrl: ctrl),
            ),
        ],
      );
    });
  }

  void _handlePPV(BuildContext context, SpaceVideo video) {
    ctrl.handlePayPerView(
      context: context,
      video: video,
      onPurchaseSuccess: () {
        final ytId = _extractYoutubeId(
          video.youtubeId.isNotEmpty ? video.youtubeId : video.videoUrl,
        );
        if (ytId != null && mounted) _initPlayer(ytId);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAG PILL — générique
// ─────────────────────────────────────────────────────────────────────────────
class _TagPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final double iconSize;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;
  final bool bold;

  const _TagPill({
    required this.label,
    this.icon,
    this.iconSize = 11,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != Colors.transparent
            ? Border.all(color: borderColor, width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: bold ? 0.4 : 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool
  showLabel; // optionnel pour n'afficher que l'icône (ex: dans le player)
  final Color? activeColor;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.showLabel = true,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? (activeColor ?? GPTheme.primaryColor)
        : context.secondaryLabel;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.10) : context.surface2,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? color.withOpacity(0.3) : context.separator,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            if (showLabel) const SizedBox(width: 4),
            if (showLabel)
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Séparateur vertical inline
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Container(width: 1, height: 16, color: context.separator),
  );
}

// Bouton cercle dans le player
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.42),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM OVERLAY
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumOverlay extends StatelessWidget {
  final SpaceVideo video;
  final VoidCallback onPayPerView;
  final VoidCallback onSubscribe;

  const _PremiumOverlay({
    required this.video,
    required this.onPayPerView,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Contenu Premium — Appuyer pour accéder',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: GPTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Contenu Premium',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Accédez à cette vidéo en vous abonnant'
                '${video.ppvPrice != null ? ' ou avec un accès unique.' : '.'}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF9A9A9A)
                      : const Color(0xFF6B6B6B),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (video.ppvPrice != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Accès unique : ${video.ppvPrice!.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    color: GPTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (video.ppvPrice != null) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: BorderSide(color: GPTheme.primaryColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onPayPerView();
                  },
                  child: Text(
                    'Accès unique — ${video.ppvPrice!.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      color: GPTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GPTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(ctx).pop();
                  Navigator.of(ctx).pop();
                  onSubscribe();
                },
                child: const Text(
                  "S'abonner au Premium",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMENT TILE
// ─────────────────────────────────────────────────────────────────────────────
class _CommentTile extends StatefulWidget {
  final VideoComment comment;
  final VideosController ctrl;
  const _CommentTile({required this.comment, required this.ctrl});

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _showReplies = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 17,
            backgroundColor: GPTheme.primaryColor.withOpacity(0.12),
            backgroundImage: c.userAvatar != null
                ? NetworkImage(c.userAvatar!)
                : null,
            child: c.userAvatar == null
                ? Text(
                    c.userName.isNotEmpty ? c.userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: GPTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Auteur + date
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        c.userName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: context.primaryLabel,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      c.createdAt,
                      style: TextStyle(
                        color: context.secondaryLabel,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Contenu
                Text(
                  c.content,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: context.primaryLabel,
                  ),
                ),
                const SizedBox(height: 9),

                // Actions
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => widget.ctrl.toggleCommentLike(c.id),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            c.isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 15,
                            color: c.isLiked
                                ? Colors.red
                                : context.secondaryLabel,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${c.likesCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.secondaryLabel,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    GestureDetector(
                      onTap: () => widget.ctrl.setReplyingTo(c),
                      child: Text(
                        'Répondre',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.secondaryLabel,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (c.replies.isNotEmpty) ...[
                      const SizedBox(width: 18),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showReplies = !_showReplies),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showReplies
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 15,
                              color: GPTheme.primaryColor,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _showReplies
                                  ? 'Masquer'
                                  : '${c.replies.length} réponse(s)',
                              style: TextStyle(
                                fontSize: 12,
                                color: GPTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                if (_showReplies && c.replies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: c.replies
                          .map((r) => _ReplyTile(reply: r, ctrl: widget.ctrl))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REPLY TILE
// ─────────────────────────────────────────────────────────────────────────────
class _ReplyTile extends StatelessWidget {
  final VideoComment reply;
  final VideosController ctrl;
  const _ReplyTile({required this.reply, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 1.5,
            height: 34,
            color: context.separator,
            margin: const EdgeInsets.only(right: 10),
          ),
          CircleAvatar(
            radius: 12,
            backgroundColor: GPTheme.primaryColor.withOpacity(0.1),
            child: Text(
              reply.userName.isNotEmpty ? reply.userName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: GPTheme.primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        reply.userName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: context.primaryLabel,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      reply.createdAt,
                      style: TextStyle(
                        color: context.secondaryLabel,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  reply.content,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: context.primaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPANDABLE TEXT
// ─────────────────────────────────────────────────────────────────────────────
class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.text,
            maxLines: _expanded ? null : 2,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              color: context.secondaryLabel,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _expanded ? 'Voir moins' : 'Voir plus',
            style: TextStyle(
              color: GPTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
