import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quran/quran.dart' as quran;
import '../../../core/services/notification_service.dart';
import '../../../core/models/reciter.dart';
import '../../../core/models/moshaf.dart';

class QuranDownloadController extends GetxController {
  final Dio _dio = Dio();
  final _notificationService = Get.find<NotificationService>();

  // تتبع تقدم التحميل: key هو (سورة-مصحف-قارئ) والقيمة هي النسبة من 0 إلى 100
  var downloadProgress = <String, int>{}.obs;
  var isDownloadingAll = false.obs;
  var currentDownloadIndex = 0.obs;
  var totalToDownload = 0.obs;

  String _getFileKey(int surahNum, String reciterName, int mushafId) {
    return "$reciterName-$mushafId-$surahNum";
  }

  Future<String> _getDownloadPath(int surahNum, String reciterName, int mushafId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final skoonDir = Directory("${appDir.path}/skoon");
    if (!await skoonDir.exists()) await skoonDir.create(recursive: true);
    
    final surahName = quran.getSurahNameArabic(surahNum);
    return "${skoonDir.path}/$reciterName-$mushafId-$surahName.mp3";
  }

  Future<void> downloadSurah({
    required Reciter reciter,
    required Moshaf moshaf,
    required int surahNum,
  }) async {
    final key = _getFileKey(surahNum, reciter.name, moshaf.id);
    if (downloadProgress.containsKey(key)) return;

    final path = await _getDownloadPath(surahNum, reciter.name, moshaf.id);
    if (File(path).existsSync()) {
      Get.snackbar("موجود بالفعل", "سورة ${quran.getSurahNameArabic(surahNum)} محملة مسبقاً");
      return;
    }

    if (Platform.isAndroid) {
      await [Permission.audio, Permission.storage].request();
    }

    final url = "${moshaf.server}/${surahNum.toString().padLeft(3, '0')}.mp3".replaceAll('http://', 'https://');
    final notificationId = key.hashCode.abs();

    try {
      downloadProgress[key] = 0;
      await _dio.download(
        url,
        path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            int progress = ((received / total) * 100).toInt();
            downloadProgress[key] = progress;
            _notificationService.showDownloadNotification(
              id: notificationId,
              title: "جاري تحميل سورة ${quran.getSurahNameArabic(surahNum)}",
              body: "القارئ ${reciter.name}",
              progress: progress,
            );
          }
        },
      );
      
      downloadProgress.remove(key);
      _notificationService.showDownloadNotification(
        id: notificationId,
        title: "اكتمل التحميل",
        body: "تم تحميل سورة ${quran.getSurahNameArabic(surahNum)} بنجاح",
        progress: 100,
        isCompleted: true,
      );
      
    } catch (e) {
      downloadProgress.remove(key);
      _notificationService.cancelNotification(notificationId);
      Get.snackbar("خطأ", "فشل تحميل سورة ${quran.getSurahNameArabic(surahNum)}");
    }
  }

  Future<void> downloadAllSurahs({
    required Reciter reciter,
    required Moshaf moshaf,
  }) async {
    if (isDownloadingAll.value) return;

    final surahNumbers = moshaf.surahList.split(',').map((e) => int.parse(e)).toList();
    totalToDownload.value = surahNumbers.length;
    currentDownloadIndex.value = 0;
    isDownloadingAll.value = true;

    Get.snackbar("بدأ التحميل", "جاري تحميل كافة السور للقارئ ${reciter.name}", 
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.blue, colorText: Colors.white);

    for (var surahNum in surahNumbers) {
      final path = await _getDownloadPath(surahNum, reciter.name, moshaf.id);
      if (!File(path).existsSync()) {
        currentDownloadIndex.value++;
        final url = "${moshaf.server}/${surahNum.toString().padLeft(3, '0')}.mp3".replaceAll('http://', 'https://');
        
        try {
          await _dio.download(url, path);
          _notificationService.showDownloadNotification(
            id: 999, // ID موحد لتحميل الكل
            title: "جاري تحميل المصحف الكامل",
            body: "تم تحميل ${currentDownloadIndex.value} من ${totalToDownload.value} سورة",
            progress: ((currentDownloadIndex.value / totalToDownload.value) * 100).toInt(),
          );
        } catch (e) {
          debugPrint("Error downloading surah $surahNum: $e");
        }
      } else {
        currentDownloadIndex.value++;
      }
    }

    isDownloadingAll.value = false;
    _notificationService.showDownloadNotification(
      id: 999,
      title: "اكتمل تحميل المصحف",
      body: "تم تحميل جميع سور القارئ ${reciter.name}",
      progress: 100,
      isCompleted: true,
    );
    
    Get.snackbar("اكتمل التحميل", "تم تحميل جميع سور القارئ ${reciter.name} بنجاح",
        backgroundColor: Colors.green, colorText: Colors.white);
  }
}
