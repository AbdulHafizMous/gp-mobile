import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/constants/index.dart';

class GPTheme {
  static TextTheme lightTextTheme = const TextTheme();

  static Color primaryColor = const Color.fromARGB(255, 235, 32, 64);
  static Color secondaryColor = const Color.fromARGB(85, 235, 32, 64);

  // ── Couleurs par section (Espaces / Social / Club) ──────────────────────
  // Espaces garde le rouge "main" (primaryColor). Social passe au bleu,
  // Club au jaune. Utilisé pour l'appbar, la bottom bar et le sidebar sur le
  // Home ; la cohérence dark/light reste gérée par les appelants
  // (en dark on garde le fond noir, ces couleurs ne s'appliquent qu'en light).
  static Color socialColor = const Color.fromARGB(255, 0, 134, 201);
  static Color clubColor = const Color.fromARGB(255, 255, 198, 0);
  // Couleur de contenu (texte/icône) à utiliser PAR-DESSUS un fond plein
  // clubColor : le jaune est trop clair pour du texte blanc (contraste
  // insuffisant), on utilise donc une couleur sombre. Le bleu Social a un
  // contraste suffisant avec du blanc, pas besoin d'équivalent pour lui.
  static Color clubOnColor = const Color.fromARGB(255, 0, 0, 0);

  /// Couleur d'accent (fond appbar/bottombar/drawer) pour l'index de section
  /// donné (0 = Espaces, 1 = Social, 2 = Club).
  static Color colorForSection(int index) {
    switch (index) {
      case 1:
        return socialColor;
      case 2:
        return clubColor;
      default:
        return primaryColor;
    }
  }

  /// Couleur à utiliser pour du texte/icône POSÉ SUR une surface claire
  /// (ex : pill blanche d'un item de sidebar) selon la section active.
  /// Contrairement à [colorForSection], celle-ci reste lisible sur blanc
  /// (clubColor/jaune ne l'est pas, on retombe donc sur clubOnColor).
  static Color contentColorForSection(int index) {
    switch (index) {
      case 1:
        return socialColor;
      case 2:
        return clubOnColor;
      default:
        return primaryColor;
    }
  }

  /// Logo (appbar + sidebar) pour l'index de section donné.
  static String logoForSection(int index) {
    switch (index) {
      case 1:
        return LOGO_SOCIAL;
      case 2:
        return LOGO_CLUB;
      default:
        return LOGO_MEDIA;
    }
  }

  static TextTheme darkTextTheme = const TextTheme();

  static ThemeData light() {
    return ThemeData(
      fontFamily: 'gotham_book',
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          // Set the predictive back transitions for Android.
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: Colors.white,
      primaryColor: primaryColor,
      brightness: Brightness.light, // Crucial
      cardColor: Colors.white,
      dividerColor: Colors.grey.shade200,
      hintColor: Colors.grey.shade600,
      cardTheme: CardThemeData(
        color: primaryColor,
        surfaceTintColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
      appBarTheme: const AppBarTheme(
        iconTheme: IconThemeData(color: Colors.white, size: 25),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.shifting,
      ),
      drawerTheme: const DrawerThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: WidgetStateBorderSide.resolveWith(
          (states) => const BorderSide(color: Colors.white, width: 1),
        ),
        shape: const RoundedRectangleBorder(
          side: BorderSide(
            color: Colors.white,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.black, fontSize: 12),
        fillColor: Colors.white,
        filled: true,
        errorStyle: TextStyle(color: Colors.white, fontSize: 12),
        iconColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(50)),
          borderSide: BorderSide(color: Colors.white),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(50)),
          borderSide: BorderSide(color: Colors.white),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(50)),
          borderSide: BorderSide(color: Colors.white),
        ),
        outlineBorder: BorderSide(
          color: Colors.white,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: Colors.black,
      fontFamily: 'gotham_book',
      primaryColor: Colors.white,
      brightness: Brightness.dark, // Crucial
      cardColor: const Color(0xFF1A1A1A),
      dividerColor: Colors.white10,
      hintColor: Colors.white70,
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: primaryColor,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      appBarTheme: const AppBarTheme(
        iconTheme: IconThemeData(color: Colors.white, size: 25),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.shifting,
      ),
      drawerTheme: const DrawerThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: WidgetStateBorderSide.resolveWith(
          (states) => const BorderSide(color: Colors.white, width: 1),
        ),
        shape: const RoundedRectangleBorder(
          side: BorderSide(
            color: Colors.white,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.black, fontSize: 12),
        fillColor: Colors.white,
        filled: true,
        errorStyle: TextStyle(color: Colors.white, fontSize: 12),
        iconColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(50)),
          borderSide: BorderSide(color: Colors.white),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(50)),
          borderSide: BorderSide(color: Colors.white),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(50)),
          borderSide: BorderSide(color: Colors.white),
        ),
        outlineBorder: BorderSide(
          color: Colors.white,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
    );
  }
}