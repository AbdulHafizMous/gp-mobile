-dontwarn org.slf4j.**
-keep class org.slf4j.** { *; }

# ── Flutter ──────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── RevenueCat / Purchases (IAP iOS-side lib compilée aussi côté Android) ──
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# ── Firebase (Analytics + Messaging, déjà en dépendance) ──────────
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ── video_player / youtube_player_flutter ─────────────────────────
-keep class io.flutter.plugins.videoplayer.** { *; }
-dontwarn io.flutter.plugins.videoplayer.**

# ── GetX (réflexion sur les MethodChannel handlers) ───────────────
-keep class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }

# ── Attributs génériques nécessaires pour Gson/JSON/annotations ───
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable