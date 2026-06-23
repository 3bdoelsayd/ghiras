import 'dart:io';
import 'package:flutter/foundation.dart'; // أضفنا هذا السطر
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class QuranDatabaseService {
  static Database? _database;
  static const String _dbName = "qpc-v2-15-lines.db"; // الملف الذي اخترته من القائمة

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    // ملاحظة للتطوير: إذا قمت بتغيير ملف الـ assets، يفضل حذف التطبيق من الهاتف وتثبيته مجدداً
    // أو يمكنك تفعيل السطر التالي لمسح النسخة القديمة في كل مرة (للتجربة فقط):
    // await deleteDatabase(path);

    final exists = await databaseExists(path);

    if (!exists) {
      debugPrint("--- جاري نسخ قاعدة البيانات من Assets إلى الهاتف... ---");
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load(join("assets/db", _dbName));
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
        debugPrint("--- اكتمل النسخ بنجاح ---");
      } catch (e) {
        debugPrint("--- خطأ أثناء نسخ قاعدة البيانات: $e ---");
      }
    }

    return await openDatabase(path, readOnly: true);
  }
}
