# Flutter Proguard Rules

# Flutter Wrapper
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

# Hive
-keep class com.ebrouwer.hive.** { *; }

# Adhan (Prayer Times)
-keep class com.batoulapps.adhan.** { *; }

# Geolocation & Geocoding
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.geocoding.** { *; }
