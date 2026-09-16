# Implementation Plan - Upgrade Build Tools

The build failed because the project's Android Gradle Plugin (AGP) version (8.3.2) is lower than the minimum version supported by the current Flutter version (8.6.0). Additionally, a warning suggests upgrading Gradle to at least 8.14.0.

## Proposed Changes

### Build Configuration

#### [MODIFY] [settings.gradle.kts](file:///home/sigma/StudioProjects/ghiras/android/settings.gradle.kts)
- Upgrade `com.android.application` plugin version from `8.3.2` to `8.6.0`.
- Upgrade `org.jetbrains.kotlin.android` plugin version from `1.9.24` to `1.9.25` (recommended for AGP 8.6).

#### [MODIFY] [gradle-wrapper.properties](file:///home/sigma/StudioProjects/ghiras/android/gradle/wrapper/gradle-wrapper.properties)
- Upgrade `distributionUrl` to use Gradle `8.12` or `8.13` (checking latest supported).
  > [!NOTE]
  > The Flutter warning explicitly mentioned `8.14.0`. I will use `https://services.gradle.org/distributions/gradle-8.12-all.zip` if `8.14` is not yet available, but the warning said it will be dropped "soon", so I'll try to reach the recommended version if possible.
  > Actually, looking at the AGP compatibility table, AGP 8.6 only needs Gradle 8.7+. Gradle 8.12 is already higher than 8.7.
  > I will upgrade to Gradle 8.12 (already there) or higher as suggested.

### Potential Cleanup

#### [MODIFY] [gradle.properties](file:///home/sigma/StudioProjects/ghiras/android/gradle.properties)
- Ensure `android.newDsl=false` is maintained to avoid AGP 9+ preview warnings if they persist, or remove it if not needed.

## Verification Plan

### Automated Tests
- Run `flutter build apk --debug` to verify the build process completes.
- Run `gradlew help` in the `android` directory.

### Manual Verification
- Verify the app launches on the emulator.
