// lib/app/modules/gamez/views/gamez_home_view.dart
//
// Coquille GameZ : couleur d'accent or (GPTheme.clubColor, comme demandé —
// même couleur que le Club de Grand Public), drawer partagé (ModuleDrawer),
// 3 onglets (Jeux, Mon profil, Classement).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/module_drawer.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

import '../controllers/gamez_controller.dart';
import 'gamez_game_view.dart';

class GameZHomeView extends GetView<GameZController> {
  const GameZHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = GPTheme.clubColor;
    return Scaffold(
      backgroundColor: const Color(0xFF111014),
      drawer: ModuleDrawer(accentColor: accent, moduleName: 'GameZ'),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111014),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.sports_esports_rounded, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('GameZ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.currentTab.value == 0) {
          return const Center(child: CircularProgressIndicator());
        }
        switch (controller.currentTab.value) {
          case 1:
            return _ProfileTab(accent: accent);
          case 2:
            return _LeaderboardTab(accent: accent);
          default:
            return _CatalogTab(accent: accent);
        }
      }),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        backgroundColor: const Color(0xFF111014),
        selectedItemColor: accent,
        unselectedItemColor: Colors.white38,
        currentIndex: controller.currentTab.value,
        onTap: controller.changeTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Jeux'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard_rounded), label: 'Classement'),
        ],
      )),
    );
  }
}

class _CatalogTab extends StatelessWidget {
  final Color accent;
  const _CatalogTab({required this.accent});
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<GameZController>();
    return RefreshIndicator(
      onRefresh: ctrl.loadHome,
      child: Obx(() => GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
        itemCount: ctrl.catalog.length,
        itemBuilder: (_, i) {
          final g = ctrl.catalog[i];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Get.to(() => GameZGameView(game: g)),
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFF1B1A20), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: g.coverUrl != null
                          ? Image.network(g.coverUrl!, fit: BoxFit.cover, width: double.infinity)
                          : Container(color: accent.withOpacity(0.2), child: Icon(Icons.videogame_asset_rounded, color: accent, size: 40)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(g.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          );
        },
      )),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final Color accent;
  const _ProfileTab({required this.accent});
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<GameZController>();
    return Center(
      child: Obx(() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, color: accent, size: 56),
          const SizedBox(height: 12),
          Text('${ctrl.totalPoints.value} points', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      )),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final Color accent;
  const _LeaderboardTab({required this.accent});
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<GameZController>();
    return Obx(() => ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: ctrl.leaderboard.length,
      itemBuilder: (_, i) {
        final row = ctrl.leaderboard[i];
        return ListTile(
          leading: CircleAvatar(backgroundColor: accent.withOpacity(0.2), child: Text('${i + 1}', style: TextStyle(color: accent, fontWeight: FontWeight.w800))),
          title: Text(row['user']?['name']?.toString() ?? '—', style: const TextStyle(color: Colors.white)),
          trailing: Text('${row['score']}', style: TextStyle(color: accent, fontWeight: FontWeight.w800)),
        );
      },
    ));
  }
}
