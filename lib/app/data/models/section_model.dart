// lib/app/data/models/section_model.dart

import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/club/views/club_view.dart';
import 'package:grand_public_v2/app/modules/space/views/spaces_list_view.dart';
import 'package:grand_public_v2/app/modules/social/views/social_view.dart';
import 'package:grand_public_v2/app/modules/shop/views/shop_view.dart';

class DrawerItem {
  final String title;
  final IconData icon;
  final String? route;
  final List<String> requiredRoles;

  const DrawerItem({
    required this.title,
    required this.icon,
    this.route,
    this.requiredRoles = const [],
  });
}

class SectionModel {
  final String title;
  final String description;
  final IconData icon;
  final String? route;
  final bool hasSub;
  final bool isLive;
  final Widget? page;
  final List<DrawerItem> drawerItems;

  const SectionModel({
    required this.title,
    required this.description,
    required this.icon,
    this.isLive = false,
    this.hasSub = false,
    this.page,
    this.route,
    this.drawerItems = const [],
  });
}

final sections = [
  SectionModel(
    title: "Espaces",
    description:
        "Explorez des univers riches avec des contenus variés : médias, lives et expériences immersives.",
    icon: Icons.dashboard_customize_outlined,
    hasSub: true,
    isLive: true,
    page: SpacesListView(),
    drawerItems: [
      DrawerItem(
        title: "Tous les espaces",
        icon: Icons.grid_view_rounded,
        route: "/home/spaces",
      ),
      DrawerItem(
        title: "Gérer les espaces",
        icon: Icons.settings_outlined,
        route: "/home/spaces/manage",
        requiredRoles: ["Admin", "Super Admin"],
      ),
    ],
  ),
  // ── "Music" retiré du bottom nav : fonctionnalité non disponible pour le
  // moment (page "BIENTÔT"). Un reviewer/utilisateur qui tombe sur un onglet
  // vide donne l'impression d'une app incomplète (Apple Guideline 4.2).
  // Décommenter dès que la fonctionnalité Music sera prête à être publiée.
  // SectionModel(
  //   title: "Music",
  //   description:
  //       "Découvrez les tendances musicales, artistes et contenus exclusifs.",
  //   icon: Icons.music_note_outlined,
  //   route: "/home/music",
  //   drawerItems: [
  //     DrawerItem(
  //       title: "Tendances",
  //       icon: Icons.trending_up_rounded,
  //       route: "/home/music/trending",
  //     ),
  //     DrawerItem(
  //       title: "Artistes",
  //       icon: Icons.person_outlined,
  //       route: "/home/music/artists",
  //     ),
  //     DrawerItem(
  //       title: "Playlists",
  //       icon: Icons.queue_music_rounded,
  //       route: "/home/music/playlists",
  //     ),
  //     DrawerItem(
  //       title: "Uploader un son",
  //       icon: Icons.upload_rounded,
  //       route: "/home/music/upload",
  //       requiredRoles: ["Admin", "Super Admin", "creator"],
  //     ),
  //   ],
  // ),
  SectionModel(
    title: "Club",
    description:
        "Profitez d'offres exclusives, promotions et avantages uniques.",
    icon: Icons.local_offer_outlined,
    hasSub: true,
    isLive: true,
    page: ClubView(),
    // route: "/home/club",
    drawerItems: [
      DrawerItem(
        title: "Promotions",
        icon: Icons.local_offer_outlined,
        route: "/home/club",
      ),
      DrawerItem(
        title: "Validations",
        icon: Icons.verified_outlined,
        route: "/home/club/validations",
        requiredRoles: ["Admin", "Super Admin", "Partner"],
      ),
    ],
  ),
  SectionModel(
    title: "Social",
    description: "Discutez, échangez et connectez-vous avec la communauté.",
    icon: Icons.chat_bubble_outline,
    isLive: true,
    page: SocialView(),
    drawerItems: [
      DrawerItem(
        title: "Chat",
        icon: Icons.chat_bubble_outline_rounded,
        route: "/social/chat",
      ),
      DrawerItem(
        title: "Dating",
        icon: Icons.favorite_border_rounded,
        route: "/social/dating",
      ),
      DrawerItem(
        title: "Modération",
        icon: Icons.shield_outlined,
        route: "/social/moderation",
        requiredRoles: ["Admin", "Super Admin", "moderator"],
      ),
    ],
  ),
  // ── Shop : petites annonces / bons plans entre utilisateurs ────────────
  SectionModel(
    title: "Shop",
    description:
        "Achetez, vendez et échangez vos bons plans entre utilisateurs.",
    icon: Icons.storefront_outlined,
    isLive: true,
    page: const ShopView(),
    drawerItems: [
      DrawerItem(
        title: "Annonces",
        icon: Icons.storefront_outlined,
        route: "/shop",
      ),
      DrawerItem(
        title: "Mes annonces",
        icon: Icons.list_alt_rounded,
        route: "/shop/my-listings",
      ),
    ],
  ),
];

var fixedDrawerItems = [
  if (!activeUser.value.role.contains("Super Admin"))
    DrawerItem(
      title: "Premium",
      icon: Icons.workspace_premium_outlined,
      route: "/social-premium",
    ),
  DrawerItem(title: "Liens", icon: Icons.link_rounded, route: "/social-link"),
  DrawerItem(
    title: "À propos",
    icon: Icons.info_outline_rounded,
    route: "/social-about",
  ),
];
