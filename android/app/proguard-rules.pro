# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Just Audio & Audio Service
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.google.android.exoplayer2.** { *; }

# Flutter Local Notifications (CRITICAL for Athan)
-keep class com.dexterous.** { *; }
-keep public class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.**

# Gson & Type Serialization (Fixes "Missing type parameter" crash)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keep class com.google.gson.** { *; }
-keep class com.google.crypto.tink.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# Timezone (Required for accurate Athan scheduling)
-keep class net.wolverinebeach.** { *; }
-dontwarn net.wolverinebeach.**
-keep class com.google.android.gms.internal.measure.** { *; }

# Adhan (Prayer Calculation)
-keep class com.batoulapps.adhan.** { *; }

# Hive & Persistence
-keep class com.ebrouwer.hive.** { *; }

# Google Play & Services
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.**
