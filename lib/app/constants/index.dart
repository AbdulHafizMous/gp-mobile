import 'package:flutter/foundation.dart';

const LOGO_NAV = 'assets/images/Logo_G3_blanc.png';
const LOGO_NAV_Dark_Club = 'assets/images/Logo_G3_noir.png';
const LOGO_PIXEL = 'assets/images/icon.png';
const LOGO = 'assets/images/icon.png';
// Logos par section (appbar + sidebar) — voir GPTheme.logoForSection
const LOGO_SOCIAL = 'assets/images/logo_gp_social.png';
const LOGO_MEDIA = 'assets/images/logo_gp_media.png';
const LOGO_CLUB = 'assets/images/logo_gp_club.png';
const GOOGLE_LOGO = 'assets/icons/google.png';
const FACEBOOK_LOGO = 'assets/icons/facebook.png';
const API_IP = "localhost";
const API_URL = "http://$API_IP:8000/api";
// const API_IP = "grandpublic.bj";
// const API_URL = "https://grandpublic.bj/api";
// Site web (pages légales : /cgu, /politique-de-confidentialite...).
const String WEBSITE_URL = "https://grandpublic.bj";
const PUSHER_API_KEY = "0fe44ac921bf1cf4b22e";
const PUSHER_API_CLUSTER = "eu";
const FEEX_SHOP_ID = "68499e0e4e10d69c0dbfd22d";
// Clé PUBLIQUE Moneroo (paiement en Mobile Money / carte). Anciennement
// nommée FEEX_API_KEY (résidu d'une intégration FeexPay antérieure, jamais
// renommée lors du passage à KKiaPay, puis à Moneroo) — clarifié ici.
//
// Moneroo ne fournit qu'UNE seule clé API (pas de séparation publique/
// privée comme KKiaPay) — c'est celle-ci, utilisée ici uniquement pour le
// widget de paiement in-app (Android/non-iOS). La vérification du paiement
// est de toute façon toujours refaite côté serveur avec la clé secrète
// (voir MONEROO_SECRET_KEY / PaymentService côté backend) avant d'activer
// quoi que ce soit — cette clé ne permet donc pas, à elle seule, de créditer
// un compte. À remplacer par la vraie clé Moneroo (tableau de bord Moneroo).
const MONEROO_API_KEY = "90366b50372111f189b307c79e518cc5";

// ══════════════════════════════════════════════════════════════════════════
// PAYWALL : paiement natif in-app vs redirection web
// true  -> paiement externalisé (redirection vers grandpublic.bj)
// false -> paiement natif dans l'app (FeexPay)
// Voir note importante envoyée en chat : à elle seule, cette bascule
// ne règle PAS le rejet Apple Guideline 3.1.1. Ne PAS activer `false`
// sur un build iOS destiné à l'App Store tant que ce point n'est pas
// clarifié avec Apple (IAP requis, ou fonctionnalité retirée sur iOS).
// ══════════════════════════════════════════════════════════════════════════
const bool useExternalPaywall = false;

// ══════════════════════════════════════════════════════════════════════════
// REVENUECAT (Apple In-App Purchase — Guideline 3.1.1)
// Utilisé UNIQUEMENT sur iOS, quel que soit `useExternalPaywall`.
// Remplace par ta vraie clé publique API iOS depuis le dashboard RevenueCat.
// ══════════════════════════════════════════════════════════════════════════
const String REVENUECAT_IOS_API_KEY = "appl_PWZcuaTWEDfdfWQSLjWXOpPqTCy";

// ══════════════════════════════════════════════════════════════════════════
// SOUMISSION APP STORE SANS MÉDIAS (Espaces)
// true  -> masque l'onglet "Espaces" (bottom nav / drawer) et le menu
//          "Premium" (abonnement), démarre l'app sur "Social".
// false -> affichage normal, tout est visible.
// À repasser à false une fois la review Apple validée.
// ══════════════════════════════════════════════════════════════════════════
const bool skipMediaOnIos = true;

// ══════════════════════════════════════════════════════════════════════════
// SOUMISSION APP STORE AVEC MÉDIAS MAIS SANS PAIEMENTS (iOS uniquement)
// Indépendant de `skipMediaOnIos` : permet de soumettre une version qui
// contient les médias mais ni abonnements, ni packs, ni achats de vidéos.
// true  -> sur iOS : menu Premium masqué, aucun écran/bouton de paiement,
//          tous les points d'entrée d'achat sont bloqués.
// false -> comportement normal (RevenueCat sur iOS).
// Android / Web ne sont JAMAIS concernés.
// ══════════════════════════════════════════════════════════════════════════
const bool skipPaymentsOnIos = true;

bool get shouldSkipPayments =>
    // true;
    skipPaymentsOnIos && !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

const String paymentsUnavailableMessage =
    "Les achats ne sont pas disponibles dans cette version de l'application.";

bool isPlatformiOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// Version effective à utiliser partout dans le code : le flag ci-dessus ne
/// doit JAMAIS masquer quoi que ce soit sur Android/Web — uniquement sur
/// iOS, quelle que soit la valeur de `skipMediaOnIos`.
// const bool shouldSkipMedia = true;
//
bool get shouldSkipMedia =>
    skipMediaOnIos && !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

// ══════════════════════════════════════════════════════════════════════════
// DEBUG IAP (RevenueCat) — écran de diagnostic accessible par appui long sur
// le logo de l'écran Premium.
// true  -> écran de diagnostic actif (à utiliser uniquement pour déboguer).
// false -> désactivé complètement (à repasser avant la mise en prod finale).
// ══════════════════════════════════════════════════════════════════════════
const bool isDebuggingIap = true;

// ══════════════════════════════════════════════════════════════════════════
// BLOWMUSIC — double application
// ──────────────────────────────────────────────────────────────────────────
// true  -> l'écran d'accueil (wall_start) propose un choix "Grandpublic"
//          / "Blowmusic". Blowmusic démarre alors sur sa propre coquille
//          (logo, thème, menus dédiés) tout en partageant le même compte,
//          la même session et la même API backend que Grandpublic.
// false -> comportement actuel inchangé : un seul bouton "Démarrer" qui
//          mène directement au login Grandpublic (aucun écran de choix).
// ══════════════════════════════════════════════════════════════════════════
const bool isBlowMusicActivated = true;
// Logos / identité visuelle dédiés à Blowmusic (à remplacer par les vrais
// assets une fois livrés par le design : assets/images/blowmusic_*.png).
const String LOGO_BLOWMUSIC = 'assets/images/Icone_B_blanc.png';
const String LOGO_BLOWMUSIC_NAV = 'assets/images/Logo_B3_blanc.png';
const String LOGO_BLOWMUSIC_NAV_LIGHT = 'assets/images/Logo_B3.png';

// Clé utilisée dans GetStorage pour retenir quelle application l'utilisateur
// a choisie ('grandpublic' | 'blowmusic'). Voir AppModeService.
const String kAppModeStorageKey = 'app_mode';

// Youwiiin — jeux HTML5 embarqués via WebView, à côté de BlowMusic.
const bool isYouwiiinActivated = true;
const String LOGO_YOUWIIIN = 'assets/images/Icone_Y2.png';
const String LOGO_YOUWIIIN_NAV = 'assets/images/Logo_Y2.png';
const String LOGO_YOUWIIIN_LIGHT = 'assets/images/Icone_Y_Rouge.png';
const String LOGO_YOUWIIIN_NAV_LIGHT = 'assets/images/Logo_Y_Rouge.png';
const String LOGO_YOUWIIIN_DARK = 'assets/images/Icone_Y_Noir.png';
const String LOGO_YOUWIIIN_NAV_DARK = 'assets/images/Logo_Y_Noir.png';
