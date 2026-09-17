# إصلاح مشكلة توقف تطبيق iOS على صفحة البداية (Splash Screen)

المشكلة ناتجة عن عدة أسباب تقنية تتعلق بتهيئة التطبيق على نظام iOS وفقدان بعض الإعدادات الضرورية في ملف `Info.plist` بالإضافة إلى محاولة إظهار نوافذ تنبيه (Dialogs) قبل تشغيل واجهة التطبيق.

## أسباب المشكلة المحددة
1. **نقص صلاحيات الموقع**: ملف `Info.plist` لا يحتوي على مفاتيح الوصول للموقع، مما يؤدي لتوقف التطبيق عند محاولة `PrayerService` تحديد الموقع.
2. **خطأ في تهيئة الإشعارات**: خدمة `NotificationService` لا تدعم نظام iOS حالياً (نقص إعدادات Darwin)، كما أنها تحاول إظهار تنبيهات `Get.defaultDialog` قبل استقرار واجهة التطبيق.
3. **التوقيع الرقمي (Codesigning)**: بناء التطبيق عبر GitHub Actions يتم بدون توقيع (`--no-codesign`)، وهو ما يمنعه من العمل بشكل سليم على أجهزة الآيفون الحقيقية إلا في حالات محددة (Sideloading).

---

## التغييرات المقترحة

### [Core] تحسين تهيئة التطبيق

#### [MODIFY] [lib/main.dart](file:///C:/Users/Disney/AndroidStudioProjects/ghiras/lib/main.dart)
- إضافة `FlutterNativeSplash.preserve` لضمان بقاء صفحة البداية حتى تكتمل التهيئة.
- معالجة تهيئة الإشعارات بحيث لا تعطل تشغيل التطبيق.

#### [MODIFY] [lib/core/services/notification_service.dart](file:///C:/Users/Disney/AndroidStudioProjects/ghiras/lib/core/services/notification_service.dart)
- إضافة `DarwinInitializationSettings` لدعم iOS.
- فصل طلب الصلاحيات عن عملية الـ `init` الأساسية لتجنب تعليق التطبيق.
- إضافة فحوصات لنوع النظام (Android/iOS) قبل طلب صلاحيات خاصة بالأندرويد فقط.

### [iOS] إعدادات النظام

#### [MODIFY] [ios/Runner/Info.plist](file:///C:/Users/Disney/AndroidStudioProjects/ghiras/ios/Runner/Info.plist)
- إضافة `NSLocationWhenInUseUsageDescription` و `NSLocationAlwaysAndWhenInUseUsageDescription`.
- إضافة `PermissionGroupNotification` والإعدادات اللازمة.

### [CI/CD] تحسين عملية البناء

#### [MODIFY] [.github/workflows/build-ios.yml](file:///C:/Users/Disney/AndroidStudioProjects/ghiras/.github/workflows/build-ios.yml)
- تنبيه المستخدم إلى ضرورة التوقيع اليدوي أو استخدام أدوات Sideloading.
- محاولة تحسين مخرجات البناء لتكون أسهل في التجربة.

---

## خطة التحقق

### التحقق اليدوي
1. إعادة بناء التطبيق وتجربته على المحاكي (Simulator) أولاً للتأكد من تجاوز صفحة البداية.
2. تجربة التطبيق على جهاز حقيقي بعد توقيعه يدوياً (عبر Xcode أو AltStore).

> [!IMPORTANT]
> يجب على المستخدم التأكد من إضافة ملف `GoogleService-Info.plist` إذا كان يستخدم Firebase، على الرغم من أن المشروع الحالي لا يبدو أنه يعتمد عليه بشكل مباشر في `main.dart`.

> [!WARNING]
> البناء الحالي من GitHub Actions (`--no-codesign`) سيتطلب منك استخدام برنامج مثل **AltStore** أو **Sideloadly** لتثبيته على آيفونك، لأنه لا يمكن تثبيته مباشرة كملف IPA عادي بدون توقيع.
