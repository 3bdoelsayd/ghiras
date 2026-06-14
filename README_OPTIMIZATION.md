# غِراس - Ghiras App - تحسينات عرض المصحف

## الميزات الجديدة 🚀

### 1. عرض المصحف الأمثل
- ✅ عرض مطابق للمصحف الحقيقي (15 سطر لكل صفحة)
- ✅ خط عثماني (UthmanicHafs13) أصلي
- ✅ تنسيق سطور احترافي
- ✅ ألوان المصحف الأصلية (أوراق كريمية)

### 2. الأداء والخفة
- ✅ استخدام Hive للتخزين المحلي السريع
- ✅ تحميل بيانات ديناميكي (lazy loading)
- ✅ Pagination لتقليل استهلاك الذاكرة
- ✅ Cache ذكي للبيانات

### 3. سهولة الاستخدام
- ✅ البحث السريع في القرآن
- ✅ الإشارات المرجعية (Bookmarks)
- ✅ تتبع التقدم في القراءة
- ✅ ملاحة سهلة بين الصفحات والسور

### 4. الهيكل المعماري
```
lib/
├── models/
│   ├── quran_models.dart       # نماذج القرآن
│   └── bookmark_model.dart     # نموذج الإشارات
├── services/
│   ├── quran_repository.dart   # مستودع البيانات
│   ├── quran_bloc.dart         # إدارة الحالة
│   ├── bookmark_service.dart   # خدمة الإشارات
│   └── quran_service.dart      # خدمات عامة
├── widgets/
│   ├── mushaf_page_view.dart   # عرض صفحة المصحف
│   ├── surah_list_view.dart    # قائمة السور
│   ├── surah_detail_view.dart  # تفاصيل السورة
│   ├── page_indicator_widget.dart  # مؤشر الصفحة
│   ├── ayah_highlight_widget.dart  # تمييز الآيات
│   └── search_quran_widget.dart    # البحث
├── utils/
│   ├── quran_constants.dart    # الثوابت
│   └── quran_helpers.dart      # الدوال المساعدة
└── main.dart                    # نقطة البداية
```

## التحسينات التقنية

### 1. إدارة الحالة (BLoC)
```dart
- InitializeQuranEvent: تهيئة البيانات
- LoadSurahEvent: تحميل سورة
- LoadPageEvent: تحميل صفحة
- SearchQuranEvent: البحث
- LoadJuzEvent: تحميل جزء
```

### 2. التخزين المحلي (Hive)
- 4 صناديق: Surahs, Ayahs, Bookmarks, ReadingProgress
- تخزين سريع بدون SQL
- كفاءة عالية في الأداء

### 3. معالجة البيانات
- تحويل JSON إلى نماذج
- Caching تلقائي
- معالجة الأخطاء

## كيفية الاستخدام

### 1. التهيئة
```dart
final quranBloc = QuranBloc(repository: QuranRepository());
quranBloc.add(const InitializeQuranEvent());
```

### 2. تحميل صفحة
```dart
quranBloc.add(const LoadPageEvent(1));
```

### 3. البحث
```dart
quranBloc.add(const SearchQuranEvent('الحمد'));
```

## الملفات المطلوبة

### assets/json/
- `surahs.json` - بيانات السور ✅
- `ayahs_complete.json` - بيانات الآيات (كامل 6236 آية)
- `quarters.json` - بيانات الأرباع ✅

### assets/fonts/
- `UthmanicHafs1 Ver13.otf` - الخط العثماني ✅

## نصائح الأداء

1. **استخدم PageView** لتحميل صفحات واحدة في كل مرة
2. **Cache البيانات** في Hive لسرعة أكبر
3. **تجنب Rebuild غير الضروري** باستخدام BlocBuilder
4. **استخدم ListView مع itemBuilder** وليس Children
5. **اضغط الخطوط** إلى صيغة TTF بدلاً من OTF حيث الإمكان

## الخطوات التالية

- [ ] تحميل بيانات الآيات الكاملة (6236 آية)
- [ ] تحسين البحث (مؤشر Inverted Index)
- [ ] إضافة ميزة التلاوة الصوتية
- [ ] تصدير الآيات المختارة
- [ ] مشاركة الآيات
- [ ] إحصائيات القراءة
- [ ] الوضع الليلي

---

**تم التطوير بعناية لتقديم أفضل تجربة قرآنية** 📖✨
