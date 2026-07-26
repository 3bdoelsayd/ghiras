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
    
    return "${skoonDir.path}/reciter_${reciterId}_mushaf_${mushafId}_surah_$surahNum.mp3";
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
    
    // التحقق من صحة الملف الموجود
    if (File(path).existsSync()) {
      final fileSize = await File(path).length();
      // إذا كان الملف أصغر من 50 كيلوبايت فهو بالتأكيد تالف أو غير مكتمل
      if (fileSize < 50 * 1024) {
        await File(path).delete();
      } else if (downloadStatus[key] == 'completed' || downloadStatus[key] == null) {
        if (!downloadStatus.containsKey(key)) {
          Get.snackbar("موجود بالفعل", "سورة ${quran.getSurahNameArabic(surahNum)} محملة مسبقاً");
          return;
        }
      }
    }

    if (Platform.isAndroid) {
      // نطلب فقط الصلاحيات المسموحة في المانيفست
      await [Permission.audio, Permission.storage].request();
    }

    // إزالة إجبار https لأن الكثير من سيرفرات القراء لا تدعمها وتكتفي بـ http
    final url = "${moshaf.server}/${surahNum.toString().padLeft(3, '0')}.mp3";
    final notificationId = key.hashCode.abs();
    
    final cancelToken = CancelToken();
    _cancelTokens[key] = cancelToken;
    downloadStatus[key] = 'downloading';

    try {
      // دعم الاستئناف الحقيقي: نتحقق من حجم الملف الموجود حالياً
      int downloadedLength = 0;
      File partialFile = File(path);
      if (await partialFile.exists()) {
        downloadedLength = await partialFile.length();
      }

      // إذا كان الملف موجوداً بالكامل (بناءً على الحجم المتوقع من السيرفر)، نعتبره مكتملاً
      // لكننا هنا سنفتح اتصالاً لطلب الجزء المتبقي فقط
      Options options = Options(
        headers: downloadedLength > 0 ? {'range': 'bytes=$downloadedLength-'} : {},
        responseType: ResponseType.stream, // استخدام Stream لضمان عدم استهلاك الرامات
      );

      final response = await _dio.get(url, options: options);
      
      // فتح الملف في وضع "الإضافة" (Append)
      final file = File(path);
      IOSink raf = file.openWrite(mode: downloadedLength > 0 ? FileMode.append : FileMode.write);
      
      int totalBytes = response.headers.value(HttpHeaders.contentLengthHeader) != null 
          ? int.parse(response.headers.value(HttpHeaders.contentLengthHeader)!) + downloadedLength 
          : -1;

      int currentReceived = downloadedLength;

      await response.data.stream.listen(
        (List<int> chunk) {
          raf.add(chunk);
          currentReceived += chunk.length;
          
          if (totalBytes != -1) {
            int progress = ((currentReceived / totalBytes) * 100).toInt();
            downloadProgress[key] = progress;
            
            // تحديث الإشعار كل 5% لتجنب الضغط على النظام
            if (progress % 5 == 0) {
              _notificationService.showDownloadNotification(
                id: notificationId,
                title: "جاري تحميل سورة ${quran.getSurahNameArabic(surahNum)}",
                body: "تم تحميل $progress%",
                progress: progress,
              );
            }
          }
        },
        onDone: () async {
          await raf.close();
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
        },
        onError: (e) async {
          await raf.close();
          throw e;
        },
        cancelOnError: true,
      ).asFuture();
      
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

  void cancelDownload(String key, String path) async {
    pauseDownload(key);
    downloadStatus.remove(key);
    downloadProgress.remove(key);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteDownloadedSurah(int surahNum, dynamic reciterId, int mushafId) async {
    final path = await _getDownloadPath(surahNum, reciterId, mushafId);
    final key = _getFileKey(surahNum, reciterId, mushafId);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      downloadStatus.remove(key);
      Get.snackbar("تم الحذف", "تم حذف سورة ${quran.getSurahNameArabic(surahNum)} لإعادة تحميلها");
    }
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
          // إزالة إجبار https لضمان عمل السيرفرات القديمة
          final url = "${moshaf.server}/${surahNum.toString().padLeft(3, '0')}.mp3";
          
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
