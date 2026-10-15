// Tuile « Chaînes » des drawers (Grandpublic, Blowmusic, Youwiiin) : un
// ExpansionTile au même format que les boutons du menu fixe, placé juste
// sous « Youwiiin ». Déplié, il liste les chaînes disponibles.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/channels/controllers/channels_list_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class ChannelsDrawerTile extends StatelessWidget {
  final Color? accentColor;
  const ChannelsDrawerTile({super.key, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<ChannelsListController>()
        ? Get.find<ChannelsListController>()
        : Get.put(ChannelsListController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? GPTheme.primaryColor;
    final fg = isDark ? Colors.white : color;

    return Obx(() {
      // Rien à afficher tant qu'aucune chaîne n'existe.
      if (!c.isLoading.value && c.channels.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(30),
            color: isDark ? Colors.transparent : Colors.white,
          ),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              iconColor: fg,
              collapsedIconColor: fg,
              shape: const Border(),
              collapsedShape: const Border(),
              leading: Icon(Icons.live_tv_rounded, color: fg, size: 20),
              title: Text('Chaînes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: fg)),
              children: [
                if (c.isLoading.value)
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                for (final ch in c.channels)
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Get.back(); // ferme le drawer
                      Get.toNamed('/channel/${ch.id}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: color,
                          backgroundImage: ch.logoUrl != null ? NetworkImage(ch.logoUrl!) : null,
                          child: ch.logoUrl == null
                              ? Text(ch.name.isEmpty ? '?' : ch.name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(ch.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                        if (ch.isSubscribed) const Icon(Icons.verified_rounded, color: Colors.green, size: 16),
                      ]),
                    ),
                  ),
                InkWell(
                  onTap: () {
                    Get.back();
                    Get.toNamed('/channels');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Voir toutes les chaînes',
                        style: TextStyle(color: fg.withValues(alpha: 0.75), fontWeight: FontWeight.w700, fontSize: 12.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
