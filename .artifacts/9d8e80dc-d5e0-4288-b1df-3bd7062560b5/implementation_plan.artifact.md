# خطة إصلاح وتفعيل الأذان لنسخة Google Play

تهدف هذه الخطة إلى ضمان عمل الأذان بشكل موثوق عند تحميل التطبيق من متجر جوجل بلاي، مع مراعاة سياسات أندرويد الحديثة (Android 13, 14, 15) التي تفرض قيوداً على الإشعارات والمنبهات.

## User Review Required

> [!IMPORTANT]
> **إذن المنبه الدقيق (Exact Alarms)**: سنستخدم إذن `USE_EXACT_ALARM` وهو مخصص لتطبيقات المنبه والأذان. جوجل تسمح به لهذه الفئة من التطبيقات. هذا الإذن يضمن أن الأذان سيعمل في وقته بالضبط دون تأخير من النظام.

> [!WARNING]
> **تحسين البطارية**: سنضيف واجهة تطلب من المستخدم استثناء التطبيق من "تحسين البطارية" (Battery Optimization). بدون هذه الخطوة، قد يقوم الهاتف بقتل العملية المسؤولة عن الأذان في الخلفية لتوفير الطاقة.

## Proposed Changes

### [Android Configuration]

#### [MODIFY] [AndroidManifest.xml](file:///C:/Users/Disney/AndroidStudioProjects/ghiras/android/app/src/main/AndroidManifest.xml)
- إضافة إذن `android.permission.USE_EXACT_ALARM` لضمان العمل التلقائي للمنبهات الدقيقة.
- إضافة إذن `android.permission.POST_NOTIFICATIONS` للتأكد من طلب صلاحية الإشعارات على أندرويد 13+.
- التأكد من إعداد الـ Receivers والـ Services للعمل في الخلفية.

#### [MODIFY] [build.gradle.kts](file:///C:/Users/Disney/AndroidStudioProjects/ghiras/android/app/build.gradle.kts)
- خفض `compileSdk` و `targetSdk` إلى **35** لضمان استقرار المكتبات (36 لا يزال تجريبياً وقد لا تدعمه بعض المكتبات بشكل كامل في المتجر).

### [Core Services]

#### [MODIFY] [notification_service.dart](file:///C:/Users/Disney/AndroidStudioProjects/ghiras/lib/core/services/notification_service.dart)
- إضافة طلب صلاحية الإشعارات فور فتح التطبيق.
- تحسين إعدادات قناة الأذان لتكون بـ "أعلى أولوية" (Priority Max).
- استخدام `AndroidScheduleMode.exactAllowWhileIdle` لضمان استيقاظ الهاتف عند موعد الصلاة حتى لو كان في وضع السكون (Doze Mode).
- إضافة دالة للتحقق من حالة إذن "تحسين البطارية" وتنبيه المستخدم إذا لم يكن مفعلاً.

#### [MODIFY] [prayer_service.dart](file:///C:/Users/Disney/AndroidStudioProjects/ghiras/lib/core/services/prayer_service.dart)
- تحسين عملية إعادة جدولة الأذان عند تغيير الموقع أو الإعدادات لضمان عدم ضياع أي موعد.

## Verification Plan

### Manual Verification
1.  **اختبار نسخة الـ Release**: سنقوم ببناء التطبيق بصيغة Release وتجربته يدوياً (هذا أهم اختبار يحاكي ما سيحدث للمستخدم بعد تحميله من المتجر).
2.  **فحص الصلاحيات**: التأكد من أن التطبيق يطلب "سماح الإشعارات" عند أول تشغيل.
3.  **تجربة الأذان في وضع السكون**: جدولة أذان وترك الهاتف مقفلاً لمدة 5 دقائق للتأكد من استيقاظه عند الموعد.
