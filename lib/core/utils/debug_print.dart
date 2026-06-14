import 'dart:developer' as dev;

/// طابعة ملونة باللون الأصفر لتسهيل تتبع العمليات في الـ Console
void printYellow(dynamic text) {
  // استخدام الكود الخاص بك للطباعة الملونة في الـ Terminal
  print('\x1B[33m$text\x1B[0m');
}

/// طابعة ملونة باللون الأخضر (للنجاح)
void printGreen(dynamic text) {
  print('\x1B[32m$text\x1B[0m');
}

/// طابعة ملونة باللون الأحمر (للأخطاء)
void printRed(dynamic text) {
  print('\x1B[31m$text\x1B[0m');
}

/// طابعة ملونة باللون الأزرق (للمعلومات)
void printBlue(dynamic text) {
  print('\x1B[34m$text\x1B[0m');
}
