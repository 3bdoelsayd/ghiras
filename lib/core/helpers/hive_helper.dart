import 'package:hive_flutter/hive_flutter.dart';

class HiveHelper {
  static const String _defaultBox = "settings";

  /// يحفظ قيمة افتراضية إذا كان الحقل فارغاً
  static void nullValidator(String field, dynamic value, {String? boxName}) {
    final box = Hive.box(boxName ?? _defaultBox);
    if (box.get(field) == null) {
      box.put(field, value);
    }
  }

  /// الحصول على قيمة من Hive
  static dynamic getValue(String field, {String? boxName, dynamic defaultValue}) {
    return Hive.box(boxName ?? _defaultBox).get(field, defaultValue: defaultValue);
  }

  /// تحديث قيمة في Hive
  static void updateValue(String field, dynamic value, {String? boxName}) {
    Hive.box(boxName ?? _defaultBox).put(field, value);
  }

  /// تهيئة Hive (موجودة بالفعل في main.dart ولكن نضعها هنا للتنظيم)
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_defaultBox);
  }
}

// توفير الدوال بشكل مباشر كما في مشروعك القديم لسهولة الاستخدام
void nullValidator(String field, dynamic value) => HiveHelper.nullValidator(field, value);
dynamic getValue(String field) => HiveHelper.getValue(field);
void updateValue(String field, dynamic value) => HiveHelper.updateValue(field, value);
