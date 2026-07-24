import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/shop_models.dart';
import 'package:grand_public_v2/app/modules/shop/controllers/shop_controller.dart';
import 'package:grand_public_v2/app/modules/shop/views/shop_create_view.dart';
import 'package:grand_public_v2/app/modules/shop/views/shop_detail_view.dart';
import 'package:grand_public_v2/app/modules/shop/views/shop_my_listings_view.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class ShopView extends StatelessWidget {
  const ShopView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ShopController());
    final scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 400) {
        controller.loadMore();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop — Bons plans'),
        backgroundColor: GPTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'Mes annonces',
            onPressed: () => Get.to(() => const ShopMyListingsView()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: GPTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Déposer'),
        onPressed: () => Get.to(() => const ShopCreateView()),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchFeed(reset: true),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(child: _searchBar(context)),
            SliverToBoxAdapter(child: _categoryChips()),
            Obx(() {
              if (controller.isLoadingFeed.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.listings.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Aucune annonce pour le moment.')),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _ListingCard(listing: controller.listings[i]),
                    childCount: controller.listings.length,
                  ),
                ),
              );
            }),
            Obx(
              () => controller.isLoadingMore.value
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  : const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    final controller = Get.put(ShopController());
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher une annonce...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: controller.search,
      ),
    );
  }

  Widget _categoryChips() {
    final controller = Get.put(ShopController());
    return Obx(() {
      final cats = controller.categories;
      if (cats.isEmpty) return const SizedBox(height: 8);
      return SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: cats.length + 1,
          itemBuilder: (ctx, i) {
            if (i == 0) {
              final selected = controller.selectedCategoryId.value == null;
              return _chip(
                'Toutes',
                selected,
                () => controller.selectCategory(null),
              );
            }
            final cat = cats[i - 1];
            final selected = controller.selectedCategoryId.value == cat.id;
            return _chip(
              cat.name,
              selected,
              () => controller.selectCategory(cat.id),
            );
          },
        ),
      );
    });
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: GPTheme.primaryColor,
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final ShopListing listing;
  const _ListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => ShopDetailView(listingId: listing.id)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.1,
              child: listing.coverImageUrl.isNotEmpty
                  ? Image.network(listing.coverImageUrl, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.price != null
                        ? '${listing.price!.toStringAsFixed(0)} FCFA'
                        : 'À discuter',
                    style: TextStyle(
                      color: GPTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 13,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${listing.likesCount}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.remove_red_eye,
                        size: 13,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${listing.viewsCount}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
