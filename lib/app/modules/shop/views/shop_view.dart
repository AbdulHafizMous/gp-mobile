import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/shop_models.dart';
import 'package:grand_public_v2/app/modules/shop/controllers/shop_controller.dart';
import 'package:grand_public_v2/app/modules/shop/views/shop_create_view.dart';
import 'package:grand_public_v2/app/modules/shop/views/shop_detail_view.dart';
// import 'package:grand_public_v2/app/modules/shop/views/shop_my_listings_view.dart';
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
  // Color get divider => Theme.of(this).dividerColor;
  // Color get appBarBg => isDark ? const Color(0xFF111111) : GPTheme.primaryColor;
}

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
      backgroundColor: context.bg,
      // appBar: AppBar(
      //   title: const Text('Shop — Bons plans'),
      //   backgroundColor: context.appBarBg,
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      //   actions: [
      // IconButton(
      //   icon: const Icon(Icons.list_alt_rounded),
      //   tooltip: 'Mes annonces',
      //   onPressed: () => Get.to(() => const ShopMyListingsView()),
      // ),
      //   ],
      // ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: GPTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Déposer'),
        onPressed: () => Get.to(() => const ShopCreateView()),
      ),
      body: RefreshIndicator(
        color: GPTheme.primaryColor,
        onRefresh: () => controller.fetchFeed(reset: true),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(child: _searchBar(context, controller)),
            SliverToBoxAdapter(child: _categoryChips(context, controller)),
            Obx(() {
              if (controller.isLoadingFeed.value) {
                return Center(
                  child: CircularProgressIndicator(color: GPTheme.primaryColor),
                ).let((w) => SliverFillRemaining(child: w));
              }
              if (controller.listings.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.handshake_outlined,
                          size: 48,
                          color: context.subtle,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucune annonce pour le moment.',
                          style: TextStyle(color: context.subtle),
                        ),
                      ],
                    ),
                  ),
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
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: GPTheme.primaryColor,
                          ),
                        ),
                      ),
                    )
                  : const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar(BuildContext context, ShopController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: TextStyle(color: context.primary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher une annonce...',
                hintStyle: TextStyle(color: context.subtle, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.subtle,
                  size: 20,
                ),
                filled: true,
                fillColor: context.inputBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: controller.search,
            ),
          ),
          // IconButton(
          //   icon: const Icon(Icons.list_alt_rounded),
          //   tooltip: 'Mes annonces',
          //   onPressed: () => Get.to(() => const ShopMyListingsView()),
          // ),
        ],
      ),
    );
  }

  Widget _categoryChips(BuildContext context, ShopController controller) {
    return Obx(() {
      final cats = controller.categories;
      // On récupère la valeur sélectionnée actuelle
      final selectedId = controller.selectedCategoryId.value;

      if (cats.isEmpty) return const SizedBox(height: 8);

      return SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: cats.length + 1,
          itemBuilder: (ctx, i) {
            if (i == 0) {
              final isSelected = selectedId == null;
              return _chip(
                context,
                'Toutes',
                isSelected,
                () => controller.selectCategory(null),
              );
            }

            final cat = cats[i - 1];
            final isSelected = selectedId == cat.id;

            return _chip(
              context,
              cat.name,
              isSelected,
              () => controller.selectCategory(cat.id),
            );
          },
        ),
      );
    });
  }

  Widget _chip(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: context.inputBg,
        iconTheme: IconThemeData(color: Colors.white),
        showCheckmark: false,
        selectedColor: GPTheme.primaryColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : context.primary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
        side: BorderSide.none,
      ),
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
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
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.06),
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
                      color: context.inputBg,
                      child: Icon(
                        Icons.image_not_supported,
                        color: context.subtle,
                      ),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: context.primary,
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
                      Icon(Icons.favorite, size: 13, color: context.subtle),
                      const SizedBox(width: 2),
                      Text(
                        '${listing.likesCount}',
                        style: TextStyle(fontSize: 11, color: context.subtle),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.remove_red_eye,
                        size: 13,
                        color: context.subtle,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${listing.viewsCount}',
                        style: TextStyle(fontSize: 11, color: context.subtle),
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
