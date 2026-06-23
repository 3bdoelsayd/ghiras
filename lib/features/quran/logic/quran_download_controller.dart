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
  
  // تتبع الحالات: key هو (سورة-مصحف-قارئ)
  // القيم: 'downloading', 'paused', 'completed'
  var downloadStatus = <String, String>{}.obs;
  
  // تتبع CancelTokens لكل عملية تحميل لإمكانية الإلغاء/الإيقاف
  final Map<String, CancelToken> _cancelTokens = {};

  var isDownloadingAll = false.obs;
  var currentDownloadIndex = 0.obs;
  var totalToDownload = 0.obs;
  CancelToken? _allDownloadCancelToken;

  String _getFileKey(int surahNum, dynamic reciterId, int mushafId) {
    return "$reciterId-$mushafId-$surahNum";
  }

  Future<String> _getDownloadPath(int surahNum, dynamic reciterId, int mushafId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final skoonDir = Directory("${appDir.path}/skoon");
    if (!await skoonDir.exists()) await skoonDir.create(recursive: true);
    
    return "${skoonDir.path}/reciter_${reciterId}_mushaf_${mushafId}_surah_${surahNum}.mp3";
  }

  Future<void> downloadSurah({
    required Reciter reciter,
    required Moshaf moshaf,
    required int surahNum,
  }) async {
    final key = _getFileKey(surahNum, reciter.id, moshaf.id);
    
    // إذا كان جاري التحميل، نقوم بإيقافه مؤقتاً
    if (downloadStatus[key] == 'downloading') {
      pauseDownload(key);
      return;
    }

    final path = await _getDownloadPath(surahNum, reciter.id, moshaf.id);
    
    // التحقق إذا كان الملف مكتملاً بالفعل
    if (File(path).existsSync() && (downloadStatus[key] == 'completed' || downloadStatus[key] == null)) {
      // نتأكد من حالة الملف فعلياً (ربما تم تحميله في جلسة سابقة)
      // إذا لم يكن في قائمة التحميل النشطة فهو مكتمل
      if (!downloadStatus.containsKey(key)) {
        Get.snackbar("موجود بالفعل", "سورة ${quran.getSurahNameArabic(surahNum)} محملة مسبقاً");
        return;
      }
    }

    if (Platform.isAndroid) {
      await [Permission.audio, Permission.storage].request();
    }

    final url = "${moshaf.server}/${surahNum.toString().padLeft(3, '0')}.mp3".replaceAll('http://', 'https://');
    final notificationId = key.hashCode.abs();
    
    final cancelToken = CancelToken();
    _cancelTokens[key] = cancelToken;
    downloadStatus[key] = 'downloading';

    try {
      // دعم الاستئناف: نتحقق من حجم الملف الموجود حالياً
      int downloadedLength = 0;
      File partialFile = File(path);
      if (await partialFile.exists()) {
        downloadedLength = await partialFile.length();
      }

      Options options = Options(
        headers: downloadedLength > 0 ? {'range': 'bytes=$downloadedLength-'} : {},
      );

      await _dio.download(
        url,
        path,
        cancelToken: cancelToken,
        options: options,
        deleteOnError: false, // لا تحذف الملف عند الخطأ للسماح بالاستئناف
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // إجمالي الملف = ما تم استقباله الآن + ما كان موجوداً مسبقاً
            // التوتال المرجع من السيرفر هو المتبقي فقط عند استخدام Range
            int totalBytes = total + downloadedLength;
            int currentReceived = received + downloadedLength;
            
            int progress = ((currentReceived / totalBytes) * 100).toInt();
            downloadProgress[key] = progress;
            
            _notificationService.showDownloadNotification(
              id: notificationId,
              title: "جاري تحميل سورة ${quran.getSurahNameArabic(surahNum)}",
              body: "القارئ ${reciter.name} ($progress%)",
              progress: progress,
            );
          }
        },
      );
      
      downloadStatus[key] = 'completed';
      downloadProgress.remove(key);
      _cancelTokens.remove(key);
      
      _notificationService.showDownloadNotification(
        id: notificationId,
        title: "اكتمل التحميل",
        body: "تم تحميل سورة ${quran.getSurahNameArabic(surahNum)} بنجاح",
        progress: 100,
        isCompleted: true,
      );
      
    } catch (e) {
      _cancelTokens.remove(key);
      
      if (CancelToken.isCancel(e as DioException)) {
        debugPrint("Download paused for $key");
        downloadStatus[key] = 'paused';
      } else {
        downloadStatus.remove(key);
        downloadProgress.remove(key);
        _notificationService.cancelNotification(notificationId);
        Get.snackbar("خطأ", "فشل تحميل سورة ${quran.getSurahNameArabic(surahNum)}");
      }
    }
  }

  void pauseDownload(String key) {
    if (_cancelTokens.containsKey(key)) {
      _cancelTokens[key]?.cancel("Paused by user");
      _cancelTokens.remove(key);
      downloadStatus[key] = 'paused';
    }
  }

  void cancelDownload(String key) async {
    pauseDownload(key);
    downloadStatus.remove(key);
    downloadProgress.remove(key);
    // يمكن إضافة كود هنا لحذف الملف فعلياً إذا أراد المستخدم "إلغاء" وليس "إيقاف مؤقت"
  }

  void cancelAllDownloads() {
    if (isDownloadingAll.value) {
      _allDownloadCancelToken?.cancel("Cancelled by user");
      isDownloadingAll.value = false;
    }
  }

  Future<void> downloadAllSurahs({
    required Reciter reciter,
    required Moshaf moshaf,
  }) async {
    if (isDownloadingAll.value) {
      cancelAllDownloads();
      return;
    }

    final surahNumbers = moshaf.surahList.split(',').map((e) => int.parse(e)).toList();
    totalToDownload.value = surahNumbers.length;
    currentDownloadIndex.value = 0;
    isDownloadingAll.value = true;
    _allDownloadCancelToken = CancelToken();

    Get.snackbar("بدأ التحميل", "جاري تحميل كافة السور للقارئ ${reciter.name}", 
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.blue, colorText: Colors.white);

    try {
      for (var surahNum in surahNumbers) {
        if (_allDownloadCancelToken?.isCancelled ?? false) break;

        final path = await _getDownloadPath(surahNum, reciter.id, moshaf.id);
        if (!File(path).existsSync()) {
          final url = "${moshaf.server}/${surahNum.toString().padLeft(3, '0')}.mp3".replaceAll('http://', 'https://');
          
          try {
            await _dio.download(url, path, cancelToken: _allDownloadCancelToken);
            currentDownloadIndex.value++;
            _notificationService.showDownloadNotification(
              id: 999,
              title: "جاري تحميل المصحف الكامل",
              body: "تم تحميل ${currentDownloadIndex.value} من ${totalToDownload.value} سورة",
              progress: ((currentDownloadIndex.value / totalToDownload.value) * 100).toInt(),
            );
          } catch (e) {
            if (CancelToken.isCancel(e as DioException)) {
              if (File(path).existsSync()) File(path).deleteSync();
              rethrow;
            }
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

    } catch (e) {
      isDownloadingAll.value = false;
      _notificationService.cancelNotification(999);
      if (CancelToken.isCancel(e as DioException)) {
        Get.snackbar("تم الإلغاء", "تم إيقاف تحميل المصحف", backgroundColor: Colors.orange, colorText: Colors.white);
      }
    }
  }
}
