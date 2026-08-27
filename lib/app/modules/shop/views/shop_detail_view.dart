import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/shop/controllers/shop_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/share_helper.dart';
import 'package:video_player/video_player.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _Tx on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? const Color(0xFF0D0D0D) : Colors.white;
  Color get inputBg => isDark ? Colors.white10 : Colors.grey.shade100;
  Color get primary => Theme.of(this).textTheme.bodyLarge!.color!;
  Color get subtle => Theme.of(this).hintColor;
  Color get divider => Theme.of(this).dividerColor;
  Color get appBarBg => isDark ? const Color(0xFF111111) : GPTheme.socialColor;
}

class ShopDetailView extends GetView<ShopController> {
  final int listingId;
  const ShopDetailView({super.key, required this.listingId});

  @override
  Widget build(BuildContext context) {
    controller.fetchListing(listingId);

    return Scaffold(
      backgroundColor: context.bg,
      body: Obx(() {
        if (controller.isLoadingDetail.value ||
            controller.currentListing.value == null) {
          return Center(
            child: CircularProgressIndicator(color: GPTheme.socialColor),
          );
        }
        final listing = controller.currentListing.value!;

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: context.appBarBg,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => ShareHelper.showShareSheet(
                    context,
                    title: listing.title,
                    subtitle: listing.price != null ? '${listing.price} FCFA' : null,
                    type: 'listing',
                    id: '${listing.id}',
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: listing.media.isNotEmpty
                    ? PageView(
  children: listing.media.map((m) {
    if (m.type == 'image') {
      return GestureDetector(
        onTap: () {
          Get.to(
            () => FullscreenImageViewer(url: m.url),
            transition: Transition.fadeIn,
          );
        },
        child: Hero(
          tag: m.url,
          child: Image.network(
            m.url,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Get.to(
          () => FullscreenVideoPlayer(url: m.url),
          transition: Transition.fadeIn,
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ListingVideoPlayer(url: m.url),

          IgnorePointer(
            child: Center(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(14),
                child: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }).toList(),
)
                    : Container(color: context.inputBg),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      listing.price != null
                          ? '${listing.price!.toStringAsFixed(0)} FCFA'
                          : 'Prix à discuter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: GPTheme.socialColor,
                      ),
                    ),
                    if (listing.city != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: context.subtle,
                          ),
                          Text(
                            listing.city!,
                            style: TextStyle(color: context.subtle),
                          ),
                        ],
                      ),
                    ],
                    Divider(height: 32, color: context.divider),
                    Text(
                      listing.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: context.primary,
                      ),
                    ),
                    Divider(height: 32, color: context.divider),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: context.inputBg,
                          backgroundImage: listing.seller?.avatarUrl != null
                              ? NetworkImage(listing.seller!.avatarUrl!)
                              : null,
                          child: listing.seller?.avatarUrl == null
                              ? Icon(Icons.person, color: context.subtle)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          listing.seller?.name ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _actionButton(
                          icon: listing.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: listing.isLiked ? Colors.red : context.subtle,
                          label: '${listing.likesCount}',
                          onTap: () => controller.toggleLike(listing.id),
                        ),
                        const SizedBox(width: 20),
                        Icon(
                          Icons.remove_red_eye,
                          size: 20,
                          color: context.subtle,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${listing.viewsCount} vues',
                          style: TextStyle(color: context.subtle),
                        ),
                      ],
                    ),
                    if (!listing.isOwnListing) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: Obx(
                          () => ElevatedButton.icon(
                            onPressed: controller.isContacting.value
                                ? null
                                : () => controller.contactSeller(
                                    context,
                                    listing,
                                  ),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: Text(
                              controller.isContacting.value
                                  ? 'Ouverture...'
                                  : 'Contacter le vendeur',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GPTheme.socialColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    Divider(height: 32, color: context.divider),
                    Text(
                      'Commentaires (${listing.commentsCount})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: context.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _commentInput(context, listing.id),
                    const SizedBox(height: 12),
                    Obx(
                      () => Column(
                        children: controller.comments
                            .map((c) => _CommentTile(comment: c))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _commentInput(BuildContext context, int listingId) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.commentController,
            style: TextStyle(color: context.primary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ajouter un commentaire...',
              hintStyle: TextStyle(color: context.subtle, fontSize: 14),
              filled: true,
              fillColor: context.inputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Obx(
          () => IconButton(
            icon: controller.isPostingComment.value
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: GPTheme.socialColor,
                    ),
                  )
                : Icon(Icons.send, color: GPTheme.socialColor),
            onPressed: controller.isPostingComment.value
                ? null
                : () => controller.postComment(listingId),
          ),
        ),
      ],
    );
  }
}

class _ListingVideoPlayer extends StatefulWidget {
  final String url;

  const _ListingVideoPlayer({required this.url});

  @override
  State<_ListingVideoPlayer> createState() => _ListingVideoPlayerState();
}

class _ListingVideoPlayerState extends State<_ListingVideoPlayer> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        _controller
          ..setLooping(true)
          ..play();

        if (mounted) {
          setState(() => _ready = true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final dynamic comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: context.inputBg,
            backgroundImage: comment.user.avatarUrl != null
                ? NetworkImage(comment.user.avatarUrl!)
                : null,
            child: comment.user.avatarUrl == null
                ? Icon(Icons.person, size: 16, color: context.subtle)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.user.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: context.primary,
                  ),
                ),
                Text(
                  comment.content,
                  style: TextStyle(fontSize: 13, color: context.primary),
                ),
                Text(
                  comment.createdAt,
                  style: TextStyle(fontSize: 11, color: context.subtle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
