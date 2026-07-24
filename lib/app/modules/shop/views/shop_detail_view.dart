import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/shop/controllers/shop_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class ShopDetailView extends GetView<ShopController> {
  final int listingId;
  const ShopDetailView({super.key, required this.listingId});

  @override
  Widget build(BuildContext context) {
    controller.fetchListing(listingId);

    return Scaffold(
      body: Obx(() {
        if (controller.isLoadingDetail.value || controller.currentListing.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final listing = controller.currentListing.value!;

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: GPTheme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                background: listing.media.isNotEmpty
                    ? PageView(
                        children: listing.media.map((m) {
                          return m.type == 'image'
                              ? Image.network(m.url, fit: BoxFit.cover)
                              : Container(
                                  color: Colors.black,
                                  child: const Center(
                                    child: Icon(Icons.play_circle_fill, color: Colors.white, size: 56),
                                  ),
                                );
                        }).toList(),
                      )
                    : Container(color: Colors.grey.shade300),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      listing.price != null ? '${listing.price!.toStringAsFixed(0)} FCFA' : 'Prix à discuter',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GPTheme.primaryColor),
                    ),
                    if (listing.city != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        Text(listing.city!, style: const TextStyle(color: Colors.grey)),
                      ]),
                    ],
                    const Divider(height: 32),
                    Text(listing.description, style: const TextStyle(fontSize: 14, height: 1.4)),
                    const Divider(height: 32),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: listing.seller?.avatarUrl != null
                              ? NetworkImage(listing.seller!.avatarUrl!)
                              : null,
                          child: listing.seller?.avatarUrl == null ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 10),
                        Text(listing.seller?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _actionButton(
                          icon: listing.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: listing.isLiked ? Colors.red : Colors.grey.shade700,
                          label: '${listing.likesCount}',
                          onTap: () => controller.toggleLike(listing.id),
                        ),
                        const SizedBox(width: 20),
                        Icon(Icons.remove_red_eye, size: 20, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('${listing.viewsCount} vues', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                    if (!listing.isOwnListing) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: Obx(() => ElevatedButton.icon(
                              onPressed: controller.isContacting.value
                                  ? null
                                  : () => controller.contactSeller(context, listing),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: Text(controller.isContacting.value
                                  ? 'Ouverture...'
                                  : 'Contacter le vendeur'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GPTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            )),
                      ),
                    ],
                    const Divider(height: 32),
                    Text('Commentaires (${listing.commentsCount})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _commentInput(context, listing.id),
                    const SizedBox(height: 12),
                    Obx(() => Column(
                          children: controller.comments
                              .map((c) => _CommentTile(comment: c))
                              .toList(),
                        )),
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
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color)),
      ]),
    );
  }

  Widget _commentInput(BuildContext context, int listingId) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.commentController,
            decoration: InputDecoration(
              hintText: 'Ajouter un commentaire...',
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Obx(() => IconButton(
              icon: controller.isPostingComment.value
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.send, color: GPTheme.primaryColor),
              onPressed: controller.isPostingComment.value
                  ? null
                  : () => controller.postComment(listingId),
            )),
      ],
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
            backgroundImage: comment.user.avatarUrl != null ? NetworkImage(comment.user.avatarUrl!) : null,
            child: comment.user.avatarUrl == null ? const Icon(Icons.person, size: 16) : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(comment.content, style: const TextStyle(fontSize: 13)),
                Text(comment.createdAt, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
