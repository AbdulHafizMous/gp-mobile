// Lecteur de SHORTS plein écran en portrait : défilement vertical d'un short
// à l'autre (swipe haut/bas) au sein de la même chaîne, comme TikTok / Reels.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/moneroo_webview_payment_page.dart';
import 'package:grand_public_v2/app/data/models/channel_model.dart';
import 'package:grand_public_v2/app/data/models/space_model.dart';
import 'package:grand_public_v2/app/modules/channels/controllers/shorts_feed_controller.dart';
import 'package:grand_public_v2/app/modules/channels/views/channel_subscribe_sheet.dart';
import 'package:grand_public_v2/app/modules/videos/views/videos_view.dart';
import 'package:grand_public_v2/app/services/ad_service.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Ouvre le bon lecteur : short vertical → fil plein écran, sinon page vidéo.
Future<void> openVideoSmart(SpaceVideo video, {List<SpaceVideo> siblings = const []}) async {
  if (video.isPortrait && video.channelId != null) {
    Get.to(() => ShortsFeedView(channelId: video.channelId!, initialVideoId: video.id, seed: siblings));
    return;
  }
  // Pré-roll (si une pub `preroll` cible ce module / cette chaîne) avant une
  // vidéo lisible ; jamais avant un contenu verrouillé.
  final ctx = Get.context;
  if (ctx != null && video.canRead) {
    await AdService.showFullscreen(ctx, 'preroll', channelId: video.channelId, screen: 'video');
  }
  Get.to(() => VideosView(videoId: video.id));
}

class ShortsFeedView extends StatefulWidget {
  final int channelId;
  final int? initialVideoId;
  final List<SpaceVideo> seed;
  const ShortsFeedView({super.key, required this.channelId, this.initialVideoId, this.seed = const []});

  @override
  State<ShortsFeedView> createState() => _ShortsFeedViewState();
}

class _ShortsFeedViewState extends State<ShortsFeedView> {
  late final ShortsFeedController c;
  PageController? _page;
  final _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    c = Get.put(
      ShortsFeedController(channelId: widget.channelId, initialVideoId: widget.initialVideoId, seed: widget.seed),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    _page?.dispose();
    Get.delete<ShortsFeedController>(tag: _tag);
    super.dispose();
  }

  Future<void> _onChanged(int i) async {
    final showAd = c.onPageChanged(i);
    if (showAd && mounted) {
      await AdService.showFullscreen(context, 'interstitial', channelId: widget.channelId, screen: 'shorts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (c.isLoading.value && c.items.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (c.items.isEmpty) {
          return Stack(children: [
            const Center(child: Text('Aucun short pour le moment.', style: TextStyle(color: Colors.white70))),
            _backButton(),
          ]);
        }
        _page ??= PageController(initialPage: c.startIndex);
        return Stack(children: [
          PageView.builder(
            controller: _page,
            scrollDirection: Axis.vertical,
            itemCount: c.items.length,
            onPageChanged: _onChanged,
            itemBuilder: (_, i) => Obx(() => _ShortPage(
                  key: ValueKey(c.items[i].id),
                  video: c.items[i],
                  active: c.current.value == i,
                  ctrl: c,
                  channelId: widget.channelId,
                )),
          ),
          _backButton(),
        ]);
      }),
    );
  }

  Widget _backButton() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton(
            style: IconButton.styleFrom(backgroundColor: Colors.black38),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: Get.back,
          ),
        ),
      );
}

class _ShortPage extends StatefulWidget {
  final SpaceVideo video;
  final bool active;
  final ShortsFeedController ctrl;
  final int channelId;
  const _ShortPage({super.key, required this.video, required this.active, required this.ctrl, required this.channelId});

  @override
  State<_ShortPage> createState() => _ShortPageState();
}

class _ShortPageState extends State<_ShortPage> {
  VideoPlayerController? _vp;
  YoutubePlayerController? _yt;
  bool _paused = false;
  bool _busy = false;

  SpaceVideo get v => widget.video;
  bool get _locked => !v.canRead;
  bool get _isUpload => v.sourceType == 'upload' && (v.videoFileUrl ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.active) _startPlayer();
  }

  @override
  void didUpdateWidget(covariant _ShortPage old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _startPlayer();
    } else if (!widget.active && old.active) {
      _stopPlayer();
    }
    // Déblocage : on démarre la lecture dès que canRead passe à vrai.
    if (widget.active && old.video.canRead == false && widget.video.canRead) _startPlayer();
  }

  Future<void> _startPlayer() async {
    if (_locked) return;
    if (_isUpload) {
      if (_vp != null) {
        _vp!.play();
        return;
      }
      final vp = VideoPlayerController.networkUrl(Uri.parse(v.videoFileUrl!));
      _vp = vp;
      await vp.initialize();
      if (!mounted || _vp != vp) return;
      vp
        ..setLooping(true)
        ..play();
      setState(() => _paused = false);
    } else if (v.youtubeId.isNotEmpty) {
      _yt ??= YoutubePlayerController(
        initialVideoId: v.youtubeId,
        flags: const YoutubePlayerFlags(autoPlay: true, loop: true, hideControls: true, disableDragSeek: true, forceHD: false),
      );
      _yt!.play();
      if (mounted) setState(() {});
    }
  }

  void _stopPlayer() {
    _vp?.pause();
    _yt?.pause();
    _vp?.dispose();
    _vp = null;
    _yt?.dispose();
    _yt = null;
    if (mounted) setState(() => _paused = false);
  }

  @override
  void dispose() {
    _vp?.dispose();
    _yt?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_vp != null) {
      _vp!.value.isPlaying ? _vp!.pause() : _vp!.play();
      setState(() => _paused = !_vp!.value.isPlaying);
    } else if (_yt != null) {
      _yt!.value.isPlaying ? _yt!.pause() : _yt!.play();
      setState(() => _paused = !_yt!.value.isPlaying);
    }
  }

  // ── Déblocage ─────────────────────────────────────────────────────────
  Future<void> _openSubscribe() async {
    setState(() => _busy = true);
    try {
      final r = await RequestService().get('/channels/${widget.channelId}');
      final ch = ChannelModel.fromJson(Map<String, dynamic>.from(r.data['data']['channel'] as Map));
      if (!mounted) return;
      await ChannelSubscribeSheet.show(context, ch, () async => widget.ctrl.loadMore(reset: true));
    } catch (_) {
      ToastHelper.showToast('Impossible de charger la chaîne.', backgroundColor: Colors.red, textColor: Colors.white);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buy() async {
    setState(() => _busy = true);
    try {
      final res = await RequestService().post('/videos/${v.id}/pay');
      final d = res.data?['data'];
      final checkout = d?['checkout_url']?.toString();
      final prefix = d?['return_url_prefix']?.toString();
      final confirm = d?['confirm_endpoint']?.toString();
      if (checkout == null || prefix == null || confirm == null || !mounted) return;
      final pid = await openMonerooWebviewPayment(context, checkoutUrl: checkout, returnUrlPrefix: prefix);
      if (pid == null) return;
      await RequestService().post(confirm, data: {'payment_id': pid});
      await widget.ctrl.loadMore(reset: true);
      ToastHelper.showToast('Short débloqué ✅', backgroundColor: Colors.green, textColor: Colors.white);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message']?.toString() : null;
      ToastHelper.showToast(msg ?? 'Le paiement a échoué.', backgroundColor: Colors.red, textColor: Colors.white);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      // Fond / miniature
      if (v.thumbnail.isNotEmpty) Image.network(v.thumbnail, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
      if (_locked) BackdropFilterBlur(),
      if (!_locked) GestureDetector(onTap: _togglePlay, behavior: HitTestBehavior.opaque, child: _player()),
      const IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black45, Colors.transparent, Colors.transparent, Colors.black87], stops: [0, 0.2, 0.6, 1]),
          ),
        ),
      ),
      if (_paused && !_locked) const Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 90)),
      if (_locked) _lockOverlay(),
      _rightRail(),
      _bottomInfo(),
    ]);
  }

  Widget _player() {
    if (_vp != null && _vp!.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(width: _vp!.value.size.width, height: _vp!.value.size.height, child: VideoPlayer(_vp!)),
      );
    }
    if (_yt != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: YoutubePlayer(controller: _yt!, aspectRatio: 9 / 16, showVideoProgressIndicator: false),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2));
  }

  Widget _lockOverlay() {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_rounded, color: Colors.white, size: 54),
          const SizedBox(height: 12),
          const Text('Contenu réservé aux abonnés', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _busy ? null : _openSubscribe,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
              child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('S\'abonner à la chaîne', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          if (v.ppvPrice != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: _busy ? null : _buy,
              child: Text('ou débloquer ce short · ${v.ppvPrice!.round()} F', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _rightRail() {
    Widget btn(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: GestureDetector(
            onTap: onTap,
            child: Column(children: [
              Icon(icon, color: color, size: 34),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        );
    return Positioned(
      right: 10,
      bottom: 110,
      child: Column(children: [
        btn(v.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, '${v.likesCount}', () => widget.ctrl.toggleLike(v), color: v.isLiked ? Colors.redAccent : Colors.white),
        btn(Icons.chat_bubble_outline_rounded, '${v.commentsCount}', () => Get.to(() => VideosView(videoId: v.id))),
        btn(Icons.share_rounded, 'Partager', () => SharePlus.instance.share(ShareParams(text: v.title))),
      ]),
    );
  }

  Widget _bottomInfo() {
    return Positioned(
      left: 16,
      right: 84,
      bottom: 28,
      child: SafeArea(
        top: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            if ((v.spaceLogoUrl ?? '').isNotEmpty) CircleAvatar(radius: 14, backgroundImage: NetworkImage(v.spaceLogoUrl!)),
            if ((v.spaceLogoUrl ?? '').isNotEmpty) const SizedBox(width: 8),
            Flexible(child: Text(v.spaceName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))),
            if (v.isPremium) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                child: const Text('PREMIUM', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900)),
              ),
            ],
          ]),
          const SizedBox(height: 8),
          Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

/// Voile flouté pour les shorts verrouillés.
class BackdropFilterBlur extends StatelessWidget {
  const BackdropFilterBlur({super.key});
  @override
  Widget build(BuildContext context) => Container(color: Colors.black.withValues(alpha: 0.35));
}
