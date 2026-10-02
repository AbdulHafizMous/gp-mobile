// lib/app/modules/gamez/views/gamez_home_view.dart
//
// Coquille GameZ : or (GPTheme.clubColor), drawer partagé, 3 onglets
// (Jeux, Mon profil GCoin, Classement). Theme-aware, états vides gérés.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/empty_state_widget.dart';
import 'package:grand_public_v2/app/components/module_drawer.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/services/recent_history_service.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

import '../controllers/gamez_controller.dart';
import 'gamez_game_view.dart';

class GameZHomeView extends GetView<GameZController> {
  const GameZHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = GPTheme.clubColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111014) : const Color(0xFFF7F5F0);
    final fg = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bg,
      drawer: ModuleDrawer(
        accentColor: accent,
        moduleName: 'GameZ',
        moduleLogo: LOGO_GAMEZ,
        variableItems: [
          ModuleDrawerNavItem(title: 'Jeux', icon: Icons.grid_view_rounded, onTap: () => controller.changeTab(0)),
          ModuleDrawerNavItem(title: 'GCoin', icon: Icons.monetization_on_outlined, onTap: () => controller.changeTab(1)),
          ModuleDrawerNavItem(title: 'Classement', icon: Icons.leaderboard_rounded, onTap: () => controller.changeTab(2)),
        ],
      ),
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              LOGO_GAMEZ_NAV,
              width: 30,
              height: 30,
              errorBuilder: (_, __, ___) => Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'GameZ',
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.currentTab.value == 0) {
          return const Center(child: CircularProgressIndicator());
        }
        switch (controller.currentTab.value) {
          case 1:
            return _ProfileTab(accent: accent, fg: fg);
          case 2:
            return _LeaderboardTab(accent: accent, fg: fg);
          default:
            return _CatalogTab(accent: accent, fg: fg);
        }
      }),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          backgroundColor: bg,
          selectedItemColor: accent,
          unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
          currentIndex: controller.currentTab.value,
          onTap: controller.changeTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Jeux',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monetization_on_outlined),
              label: 'GCoin',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_rounded),
              label: 'Classement',
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogTab extends StatelessWidget {
  final Color accent;
  final Color fg;
  const _CatalogTab({required this.accent, required this.fg});
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<GameZController>();
    return RefreshIndicator(
      onRefresh: ctrl.loadHome,
      child: Obx(() {
        if (ctrl.hasError.value) {
          return ListView(
            children: const [
              EmptyStateWidget(
                icon: Icons.wifi_off_rounded,
                message: 'Connexion impossible. Tirez pour réessayer.',
              ),
            ],
          );
        }
        if (ctrl.catalog.isEmpty) {
          return ListView(
            children: const [
              EmptyStateWidget(
                icon: Icons.videogame_asset_off_rounded,
                message: 'Aucun jeu disponible pour le moment.',
              ),
            ],
          );
        }
        final recent = RecentHistoryService.recentGames;
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            if (recent.isNotEmpty) ...[
              Text(
                'Repris récemment',
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recent.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Chip(
                    label: Text(
                      recent[i]['name'] ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: ctrl.catalog.length,
              itemBuilder: (_, i) {
                final g = ctrl.catalog[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Get.to(() => GameZGameView(game: g)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: fg == Colors.white
                          ? const Color(0xFF1B1A20)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: g.coverUrl != null
                                ? Image.network(
                                    g.coverUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: accent.withOpacity(0.2),
                                      child: Icon(
                                        Icons.videogame_asset_rounded,
                                        color: accent,
                                        size: 40,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: double.infinity,
                                    color: accent.withOpacity(0.2),
                                    child: Icon(
                                      Icons.videogame_asset_rounded,
                                      color: accent,
                                      size: 40,
                                    ),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            g.name,
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      }),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final Color accent;
  final Color fg;
  const _ProfileTab({required this.accent, required this.fg});
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<GameZController>();
    return Center(
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🪙', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              '${ctrl.gcoinBalance.value} GCoin',
              style: TextStyle(
                color: fg,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gagnez des GCoin en jouant, utilisez-les plus tard\npour des promos et récompenses.',
              textAlign: TextAlign.center,
              style: TextStyle(color: fg.withOpacity(0.5), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final Color accent;
  final Color fg;
  const _LeaderboardTab({required this.accent, required this.fg});
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<GameZController>();
    return Obx(() {
      if (ctrl.leaderboard.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.leaderboard_outlined,
          message: 'Aucun score enregistré pour le moment.',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: ctrl.leaderboard.length,
        itemBuilder: (_, i) {
          final row = ctrl.leaderboard[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: accent.withOpacity(0.2),
              child: Text(
                '${i + 1}',
                style: TextStyle(color: accent, fontWeight: FontWeight.w800),
              ),
            ),
            title: Text(
              row['user']?['name']?.toString() ?? '—',
              style: TextStyle(color: fg),
            ),
            trailing: Text(
              '${row['score']}',
              style: TextStyle(color: accent, fontWeight: FontWeight.w800),
            ),
          );
        },
      );
    });
  }
}
