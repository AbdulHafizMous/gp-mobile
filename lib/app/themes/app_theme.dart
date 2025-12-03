import 'package:flutter/material.dart';

class GPTheme {
  static TextTheme lightTextTheme = const TextTheme();

  static Color primaryColor = const Color(0xFFEF193B);

  static TextTheme darkTextTheme = const TextTheme();

  static ThemeData light() {
    return ThemeData(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          // Set the predictive back transitions for Android.
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Ghotam',
      primaryColor: primaryColor,
      appBarTheme: const AppBarTheme(
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 25,
        ),
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
                color: Colors.white, width: 1, style: BorderStyle.solid),
          )),
      inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.black, fontSize: 12),
          fillColor: Colors.white,
          filled: true,
          errorStyle: TextStyle(color: Colors.white, fontSize: 12),
          iconColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(50),
            ),
            borderSide: BorderSide(color: Colors.white),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(50),
            ),
            borderSide: BorderSide(color: Colors.white),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(50),
            ),
            borderSide: BorderSide(color: Colors.white),
          ),
          outlineBorder: BorderSide(
            color: Colors.white,
            width: 1,
            style: BorderStyle.solid,
          )),
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
      fontFamily: 'Ghotam',
      primaryColor: primaryColor,
      appBarTheme: const AppBarTheme(
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 25,
        ),
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
                color: Colors.white, width: 1, style: BorderStyle.solid),
          )),
      inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.black, fontSize: 12),
          fillColor: Colors.white,
          filled: true,
          errorStyle: TextStyle(color: Colors.white, fontSize: 12),
          iconColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(50),
            ),
            borderSide: BorderSide(color: Colors.white),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(50),
            ),
            borderSide: BorderSide(color: Colors.white),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(50),
            ),
            borderSide: BorderSide(color: Colors.white),
          ),
          outlineBorder: BorderSide(
            color: Colors.white,
            width: 1,
            style: BorderStyle.solid,
          )),
    );
  }
}
