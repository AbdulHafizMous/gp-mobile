import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/shop/controllers/shop_controller.dart';
import 'package:grand_public_v2/app/modules/shop/views/shop_detail_view.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _Tx on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? const Color(0xFF0D0D0D) : Colors.white;
  Color get cardBg => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get inputBg => isDark ? Colors.white10 : Colors.grey.shade100;
  Color get primary => Theme.of(this).textTheme.bodyLarge!.color!;
  Color get subtle => Theme.of(this).hintColor;
  Color get appBarBg =>
      isDark ? const Color(0xFF111111) : GPTheme.primaryColor;
}

class ShopMyListingsView extends GetView<ShopController> {
  const ShopMyListingsView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.fetchMyListings();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: const Text('Mes annonces'),
        backgroundColor: context.appBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoadingMyListings.value) {
          return Center(
            child: CircularProgressIndicator(color: GPTheme.primaryColor),
          );
        }
        if (controller.myListings.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 48,
                  color: context.subtle,
                ),
                const SizedBox(height: 12),
                Text(
                  "Vous n'avez pas encore publié d'annonce.",
                  style: TextStyle(color: context.subtle),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.myListings.length,
          itemBuilder: (ctx, i) {
            final listing = controller.myListings[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () => Get.to(() => ShopDetailView(listingId: listing.id)),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: listing.coverImageUrl.isNotEmpty
                      ? Image.network(
                          listing.coverImageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: context.inputBg,
                          child: Icon(
                            Icons.image_not_supported,
                            color: context.subtle,
                            size: 20,
                          ),
                        ),
                ),
                title: Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${listing.viewsCount} vues · ${listing.likesCount} likes · ${listing.contactsCount} contacts',
                  style: TextStyle(fontSize: 12, color: context.subtle),
                ),
                trailing: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: context.subtle),
                  color: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  onSelected: (value) {
                    if (value == 'sold') {
                      controller.updateListingStatus(listing.id, 'sold');
                    }
                    if (value == 'hidden') {
                      controller.updateListingStatus(listing.id, 'hidden');
                    }
                    if (value == 'active') {
                      controller.updateListingStatus(listing.id, 'active');
                    }
                    if (value == 'delete') controller.deleteListing(listing.id);
                  },
                  itemBuilder: (ctx) => [
                    if (listing.status != 'sold')
                      PopupMenuItem(
                        value: 'sold',
                        child: Text(
                          'Marquer comme vendue',
                          style: TextStyle(color: context.primary),
                        ),
                      ),
                    if (listing.status != 'hidden')
                      PopupMenuItem(
                        value: 'hidden',
                        child: Text(
                          'Masquer',
                          style: TextStyle(color: context.primary),
                        ),
                      ),
                    if (listing.status != 'active')
                      PopupMenuItem(
                        value: 'active',
                        child: Text(
                          'Republier',
                          style: TextStyle(color: context.primary),
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}