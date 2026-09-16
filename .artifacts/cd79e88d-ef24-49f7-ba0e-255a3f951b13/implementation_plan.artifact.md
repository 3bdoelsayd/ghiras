# Upgrade Android Gradle Plugin and Kotlin Versions

The project is currently failing to build because some dependencies (`androidx.browser:browser:1.9.0` and `androidx.core:core-ktx:1.17.0`) require a newer version of the Android Gradle Plugin (AGP 8.9.1 or higher), while the project is using AGP 8.6.0. Additionally, Flutter is warning about upcoming drops in support for AGP 8.6.0 and Kotlin 1.9.25/2.0.0, recommending upgrades to AGP 8.11.1 and Kotlin 2.2.20.

## User Review Required

> [!IMPORTANT]
> The proposed upgrade to AGP 8.11.1 and Kotlin 2.2.20 uses very recent/preview versions as recommended by the Flutter build warnings. While these satisfy the requirements of the failing dependencies, they might require specific Gradle versions. The project is already using Gradle 8.14, which should be compatible.

## Proposed Changes

### Build Configuration

#### [MODIFY] [settings.gradle.kts](file:///home/sigma/StudioProjects/ghiras/android/settings.gradle.kts)
- Update `com.android.application` version from `8.6.0` to `8.11.1`.
- Update `org.jetbrains.kotlin.android` version from `1.9.25` to `2.2.20`.

## Verification Plan

### Automated Tests
- Run `flutter build apk --debug` to verify that the build failure is resolved and dependencies are correctly matched.
- Check for any new warnings or errors related to Kotlin 2.2.20 or AGP 8.11.1.

### Manual Verification
- Verify that the app still runs correctly on an Android device/emulator after the build succeeds.
