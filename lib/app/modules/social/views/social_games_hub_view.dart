// Sous-section « Jeux » de Social : porte d'entrée de Youwiiin (qui garde ses propres menus : jeux, classements…).
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/modules/youwiiin/controllers/youwiiin_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class SocialGamesHubView extends StatelessWidget {
  const SocialGamesHubView({super.key});

  void _open({int tab = 0, int? filter}) {
    final c = gzController;
    if (filter != null) c.homeFilter.value = filter;
    Get.toNamed('/youwiiin/home', arguments: {'tab': tab});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isYouwiiinActivated) return const Center(child: Text('Jeux bientôt disponibles.'));
    final c = gzController;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        // Bandeau principal
        GestureDetector(
          onTap: () => _open(),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(colors: [GPTheme.socialColor, const Color(0xFF6D28D9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: GPTheme.socialColor.withValues(alpha: .35), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: Row(children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Youwiiin', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                  SizedBox(height: 3),
                  Text('Des dizaines de jeux, en solo ou à plusieurs. Défie tes amis !', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3)),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: GPTheme.socialColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0),
            onPressed: () => _open(),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Jouer maintenant', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 22),
        const Text('Raccourcis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Obx(() => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.9,
              children: [
                _Shortcut(icon: Icons.apps_rounded, label: 'Tous les jeux', color: GPTheme.socialColor, isDark: isDark, onTap: () => _open(filter: 0)),
                _Shortcut(icon: Icons.favorite_rounded, label: 'Mes favoris', color: Colors.pinkAccent, isDark: isDark, onTap: () => _open(filter: 1)),
                _Shortcut(icon: Icons.mail_rounded, label: 'Invitations', color: Colors.orange, isDark: isDark, badge: c.invitations.length, onTap: () => _open(filter: 2)),
                _Shortcut(icon: Icons.emoji_events_rounded, label: 'Classements', color: Colors.amber.shade700, isDark: isDark, onTap: () => _open(tab: 1)),
              ],
            )),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final int badge;
  final VoidCallback onTap;
  const _Shortcut({required this.icon, required this.label, required this.color, required this.isDark, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) => Material(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: isDark ? 0 : 1.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Stack(clipBehavior: Clip.none, children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 22)),
                if (badge > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                      child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ]),
              const SizedBox(width: 10),
              Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5))),
            ]),
          ),
        ),
      );
}
