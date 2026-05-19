# PlayGrid Club — release ProGuard / R8 rules.
#
# `proguard-android-optimize.txt` (default) plus this file are applied when
# `minifyEnabled = true` is set on the release build type.

# --- Flutter / embedding ---------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# --- Kotlin metadata used by reflection-based libraries -------------------
-keepattributes *Annotation*, InnerClasses, Signature, EnclosingMethod

# --- Stack traces are useless without line numbers ------------------------
-keepattributes SourceFile, LineNumberTable
-renamesourcefileattribute SourceFile

# Add app-specific keep rules below as real Supabase / FCM SDKs are wired in.
