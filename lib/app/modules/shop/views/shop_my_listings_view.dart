import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/shop/controllers/shop_controller.dart';
import 'package:grand_public_v2/app/modules/shop/views/shop_detail_view.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class ShopMyListingsView extends GetView<ShopController> {
  const ShopMyListingsView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.fetchMyListings();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes annonces'),
        backgroundColor: GPTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoadingMyListings.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.myListings.isEmpty) {
          return const Center(child: Text("Vous n'avez pas encore publié d'annonce."));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.myListings.length,
          itemBuilder: (ctx, i) {
            final listing = controller.myListings[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                onTap: () => Get.to(() => ShopDetailView(listingId: listing.id)),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: listing.coverImageUrl.isNotEmpty
                      ? Image.network(listing.coverImageUrl, width: 56, height: 56, fit: BoxFit.cover)
                      : Container(width: 56, height: 56, color: Colors.grey.shade200),
                ),
                title: Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${listing.viewsCount} vues · ${listing.likesCount} likes · ${listing.contactsCount} contacts',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'sold') controller.updateListingStatus(listing.id, 'sold');
                    if (value == 'hidden') controller.updateListingStatus(listing.id, 'hidden');
                    if (value == 'active') controller.updateListingStatus(listing.id, 'active');
                    if (value == 'delete') controller.deleteListing(listing.id);
                  },
                  itemBuilder: (ctx) => [
                    if (listing.status != 'sold')
                      const PopupMenuItem(value: 'sold', child: Text('Marquer comme vendue')),
                    if (listing.status != 'hidden')
                      const PopupMenuItem(value: 'hidden', child: Text('Masquer')),
                    if (listing.status != 'active')
                      const PopupMenuItem(value: 'active', child: Text('Republier')),
                    const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
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
