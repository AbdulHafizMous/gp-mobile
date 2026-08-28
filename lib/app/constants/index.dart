import 'package:flutter/foundation.dart';

const LOGO_PIXEL = 'assets/images/logo_gpb.png';
const LOGO = 'assets/images/logo_gpb.png';
// Logos par section (appbar + sidebar) — voir GPTheme.logoForSection
const LOGO_SOCIAL = 'assets/images/logo_gp_social.png';
const LOGO_MEDIA = 'assets/images/logo_gp_media.png';
const LOGO_CLUB = 'assets/images/logo_gp_club.png';
const GOOGLE_LOGO = 'assets/icons/google.png';
const FACEBOOK_LOGO = 'assets/icons/facebook.png';
// const API_IP = "localhost";
// const API_URL = "http://$API_IP:8000/api";
const API_IP = "grandpublic.bj";
const API_URL = "https://grandpublic.bj/api";
const PUSHER_API_KEY = "0fe44ac921bf1cf4b22e";
const PUSHER_API_CLUSTER = "eu";
const FEEX_SHOP_ID = "68499e0e4e10d69c0dbfd22d";
const FEEX_API_KEY = "90366b50372111f189b307c79e518cc5";

// ══════════════════════════════════════════════════════════════════════════
// PAYWALL : paiement natif in-app vs redirection web
// true  -> paiement externalisé (redirection vers grandpublic.bj)
// false -> paiement natif dans l'app (FeexPay)
// ⚠️ Voir note importante envoyée en chat : à elle seule, cette bascule
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

/// Version effective à utiliser partout dans le code : le flag ci-dessus ne
/// doit JAMAIS masquer quoi que ce soit sur Android/Web — uniquement sur
/// iOS, quelle que soit la valeur de `skipMediaOnIos`.
bool get shouldSkipMedia =>
    skipMediaOnIos && !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

// ══════════════════════════════════════════════════════════════════════════
// DEBUG IAP (RevenueCat) — écran de diagnostic accessible par appui long sur
// le logo de l'écran Premium.
// true  -> écran de diagnostic actif (à utiliser uniquement pour déboguer).
// false -> désactivé complètement (à repasser avant la mise en prod finale).
// ══════════════════════════════════════════════════════════════════════════
const bool isDebuggingIap = true;