# ─────────────────────────────────────────────
# Trak — ProGuard Rules
# ─────────────────────────────────────────────

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# flutter_local_notifications
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Android notification components
-keep class androidx.core.app.** { *; }
-keep class androidx.core.app.NotificationCompat { *; }
-keep class * extends android.content.BroadcastReceiver { *; }
-keep class * extends android.app.Service { *; }

# SharedPreferences
-keep class androidx.preference.** { *; }

# Timezone
-keep class org.threeten.** { *; }

# Keep all model classes (prevents R8 breaking serialization)
-keep class com.example.taskmanager.** { *; }

# General Android safety
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-dontwarn kotlin.**