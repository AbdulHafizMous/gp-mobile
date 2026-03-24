import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grand_public_v2/app/data/models/menu.dart';

// For Test
const bool useMock = false;
// Versionning
const String kAppVersion = '1.0.0';

const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.example.grand_public_v2';
const String kAppStoreUrl = 'https://apps.apple.com/app/idTON_APP_ID';

class SimplePhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(' ', '');

    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i + 1) % 2 == 0 && i != digits.length - 1) {
        buffer.write(' ');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

final List<AdminMenuItem> userMenuItems = [
  AdminMenuItem(
    title: 'Médias',
    description:
        'Explorez les dernières vidéos, découvrez du contenu exclusif et partagez vos coups de cœur.',
    route: '/media',
    icon: Icons.video_library_outlined,
  ),
  AdminMenuItem(
    title: 'Shop',
    description:
        'Accédez aux lives shopping, trouvez vos produits préférés et profitez d\'offres en direct.',
    route: '/shop',
    icon: Icons.shopping_cart_checkout_outlined,
  ),
  AdminMenuItem(
    title: 'Social',
    description:
        'Discutez avec la communauté, rejoignez des groupes et rencontrez des profils qui partagent vos intérêts.',
    route: '/social',
    icon: Icons.chat_outlined,
  ),
  AdminMenuItem(
    title: 'Club',
    description:
        'Découvrez les promotions, générez vos QR codes et bénéficiez d\'avantages uniques chez nos partenaires.',
    route: '/club',
    icon: Icons.local_offer_outlined,
  ),
];

final List<AdminMenuGroup> adminMenu = [
  AdminMenuGroup(
    title: '~ MEDIAS ~',
    items: [
      AdminMenuItem(
        title: 'Gestion des médias',
        description: 'Ajouter, modifier ou supprimer les contenus médias',
        route: '/media',
        icon: Icons.video_library_outlined,
      ),
      AdminMenuItem(
        title: 'Gestion des espaces',
        description: 'Créer et gérer les espaces',
        route: '/spaces',
        icon: Icons.space_dashboard_outlined,
      ),
      AdminMenuItem(
        title: 'Gestion des lives',
        description: 'Créer et suivre les lives',
        route: '/lives',
        icon: Icons.live_tv_outlined,
      ),
    ],
  ),

  AdminMenuGroup(
    title: '~ SHOP ~',
    items: [
      AdminMenuItem(
        title: 'Lives Shop',
        description: 'Gérer les lives de vente',
        route: '/live-shop',
        icon: Icons.live_tv,
      ),
      AdminMenuItem(
        title: 'Commandes',
        description: 'Consulter et valider les commandes',
        route: '/orders',
        icon: Icons.shopping_cart_checkout_outlined,
      ),
    ],
  ),

  AdminMenuGroup(
    title: '~ SOCIAL ~',
    items: [
      AdminMenuItem(
        title: 'Canaux de discussion',
        description: 'Créer et gérer les canaux',
        route: '/channels',
        icon: Icons.chat_outlined,
      ),
    ],
  ),

  AdminMenuGroup(
    title: '~ CLUB ~',
    items: [
      AdminMenuItem(
        title: 'Promotions',
        description: 'Créer et gérer les promotions',
        route: '/promotions',
        icon: Icons.local_offer_outlined,
      ),
    ],
  ),
];
