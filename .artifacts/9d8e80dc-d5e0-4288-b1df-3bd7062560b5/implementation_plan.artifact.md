# خطة تحديث أدوات بناء الأندرويد (Gradle & Kotlin)

بناءً على التحذيرات التي ظهرت في Terminal، سنقوم بتحديث محرك بناء التطبيق (Gradle) وإضافات الأندرويد ولغة Kotlin إلى الإصدارات المطلوبة لعام 2026. هذا سيضمن استقرار بناء التطبيق وتجنب توقفه مستقبلاً.

## User Review Required

> [!IMPORTANT]
> **تحديث Gradle**: سنقوم برفع إصدار Gradle من 8.14 إلى **9.1.0**. هذا تغيير كبير في محرك البناء.
> **تحديث Kotlin**: سنقوم برفع إصدار Kotlin إلى **2.3.20**.

## Proposed Changes

### [Android Build Tools]

#### [MODIFY] [gradle-wrapper.properties](file:///C:/Users/Disney/AndroidStudioProjects/ghiras/android/gradle/wrapper/gradle-wrapper.properties)
- تحديث رابط التحميل إلى `gradle-9.1-all.zip`.

#### [MODIFY] [settings.gradle.kts](file:///C:/Users/Disney/AndroidStudioProjects/ghiras/android/settings.gradle.kts)
- تحديث إصدار `com.android.application` إلى **9.0.1**.
- تحديث إصدار `org.jetbrains.kotlin.android` إلى **2.3.20**.

## Verification Plan

### Automated Tests
- تنفيذ أمر `flutter build apk --release` للتأكد من أن جميع الإضافات (Plugins) متوافقة مع الإصدارات الجديدة.

### Manual Verification
- تشغيل التطبيق على الجهاز المتصل (`OPD2403`) للتأكد من أن عملية البناء (Assemble) تتم بنجاح بدون تحذيرات.
