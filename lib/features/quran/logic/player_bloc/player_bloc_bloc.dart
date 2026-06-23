import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../core/models/reciter.dart';
import '../../../../core/models/moshaf.dart';
import '../player_bar_bloc/player_bar_bloc.dart';
import 'package:ghiras/main.dart';

part 'player_bloc_event.dart';
part 'player_bloc_state.dart';

class PlayerBlocBloc extends Bloc<PlayerBlocEvent, PlayerBlocState> {
  PlayerBlocBloc() : super(PlayerBlocInitial()) {
    on<PlayerBlocEvent>((event, emit) async {
      if (event is StartPlaying) {
        // ✅ استخدام الـ global audioPlayer لضمان عدم وجود أكثر من instance
        await audioPlayer.stop();
        int nextMediaId = 0;
        List<String> surahNumbers = event.moshaf.surahList.split(',');
        
        // ✅ طلب تصريح التخزين إذا لزم الأمر
        if (Platform.isAndroid) {
          await Permission.storage.request();
          // للأندرويد 13 فما فوق
          await Permission.photos.request(); 
          await Permission.videos.request();
          await Permission.audio.request();
        }

        final appDir = await getApplicationDocumentsDirectory();
        final skoonDir = Directory("${appDir.path}/skoon");
        if (!await skoonDir.exists()) {
          await skoonDir.create(recursive: true);
        }

        List reciterLinks = surahNumbers.map((e) {
          final surahNum = int.parse(e);
          // ✅ استخدام معرف القارئ والمصحف بدلاً من الأسماء العربية لتجنب مشاكل الملفات
          String fileName = "reciter_${event.reciter.id}_mushaf_${event.moshaf.id}_surah_$surahNum.mp3";
          File localFile = File("${skoonDir.path}/$fileName");
          
          if (localFile.existsSync()) {
            return {
              "link": localFile.path,
              "isLocal": true,
              "suraNumber": e
            };
          } else {
            String baseUrl = event.moshaf.server;
            if (baseUrl.endsWith('/')) {
              baseUrl = baseUrl.substring(0, baseUrl.length - 1);
            }
            // ✅ تحويل الرابط لـ https لضمان العمل على الأجهزة الحديثة
            if (baseUrl.startsWith('http://')) {
              baseUrl = baseUrl.replaceFirst('http://', 'https://');
            }
            final url = "$baseUrl/${e.toString().padLeft(3, "0")}.mp3";
            return {
              "link": url,
              "isLocal": false,
              "suraNumber": e
            };
          }
        }).toList();

        var playList = reciterLinks.map((e) {
          final mediaItem = MediaItem(
            id: '${nextMediaId++}',
            album: "غراس الجنة",
            artist: event.reciter.name,
            title: "سورة ${quran.getSurahNameArabic(int.parse(e["suraNumber"]))}",
            artUri: Uri.parse("https://ghiras.app/logo.png"),
          );

          if (e["isLocal"]) {
            return AudioSource.file(
              e["link"],
              tag: mediaItem,
            );
          } else {
            return AudioSource.uri(
              Uri.parse(e["link"]),
              headers: {
                'User-Agent': 'GhirasApp/1.0 (Android; Quran Audio Player)',
              },
              tag: mediaItem,
            );
          }
        }).toList();

        int currentSuraNumber = event.suraNumber == -1 
            ? int.parse(surahNumbers[0]) 
            : event.suraNumber;

        audioPlayer.setLoopMode(LoopMode.off);
        
        try {
          // ✅ التأكد من تعيين المصدر للـ global player
          await audioPlayer.setAudioSource(
            ConcatenatingAudioSource(children: playList),
            initialIndex: event.initialIndex,
          );
          audioPlayer.play();
          playerbarBloc.add(ShowBarEvent());

          emit(PlayerBlocPlaying(
              moshaf: event.moshaf,
              reciter: event.reciter,
              suraNumber: currentSuraNumber,
              jsonData: event.jsonData,
              audioPlayer: audioPlayer,
              surahNumbers: surahNumbers,
              playList: playList));
        } on PlayerException catch (e) {
          debugPrint("Error loading playlist: ${e.message}");
          emit(PlayerBlocError("خطأ في المشغل: ${e.message}"));
        } on PlayerInterruptedException catch (e) {
          debugPrint("Connection interrupted: ${e.message}");
          emit(PlayerBlocError("انقطع الاتصال: ${e.message}"));
        } catch (e) {
          debugPrint("Error loading playlist: $e");
          emit(PlayerBlocError("تعذر تحميل قائمة التشغيل: $e"));
        }

      } else if (event is DownloadSurah) {
        final dio = Dio();
        if (Platform.isAndroid) {
          await [Permission.audio, Permission.storage].request();
        }

        final appDir = await getApplicationDocumentsDirectory();
        final skoonDir = Directory("${appDir.path}/skoon");
        if (!await skoonDir.exists()) await skoonDir.create(recursive: true);
        
        final surahNum = int.parse(event.suraNumber);
        final surahName = quran.getSurahNameArabic(surahNum);
        final fileName = "reciter_${event.reciter.id}_mushaf_${event.moshaf.id}_surah_$surahNum.mp3";
        final fullPath = "${skoonDir.path}/$fileName";

        if (!File(fullPath).existsSync()) {
          Get.snackbar("بدأ التحميل", "جاري تحميل سورة $surahName", 
              backgroundColor: Colors.blue, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
          try {
            String downloadUrl = event.url;
            if (downloadUrl.startsWith('http://')) {
              downloadUrl = downloadUrl.replaceFirst('http://', 'https://');
            }
            await dio.download(downloadUrl, fullPath);
            Get.snackbar("تم التحميل", "تم تحميل سورة $surahName بنجاح", 
                backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
          } catch (e) {
            debugPrint("Download error: $e");
            Get.snackbar("خطأ في التحميل", "تعذر تحميل سورة $surahName", 
                backgroundColor: Colors.red, colorText: Colors.white);
          }
        } else {
          Get.snackbar("موجود بالفعل", "سورة $surahName محملة مسبقاً", 
              backgroundColor: Colors.orange, colorText: Colors.white);
        }
      } else if (event is DownloadAllSurahs) {
        final dio = Dio();
        if (Platform.isAndroid) {
          await [Permission.audio, Permission.storage].request();
        }

        final appDir = await getApplicationDocumentsDirectory();
        final skoonDir = Directory("${appDir.path}/skoon");
        if (!await skoonDir.exists()) await skoonDir.create(recursive: true);

        List<String> surahNumbers = event.moshaf.surahList.split(',');
        
        Get.snackbar("بدأ تحميل المصحف", "جاري تحميل جميع سور القارئ ${event.reciter.name}", 
            backgroundColor: Colors.blue, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 3));

        int successCount = 0;
        for (var e in surahNumbers) {
          final surahNum = int.parse(e);
          final surahName = quran.getSurahNameArabic(surahNum);
          final fileName = "reciter_${event.reciter.id}_mushaf_${event.moshaf.id}_surah_$surahNum.mp3";
          final fullPath = "${skoonDir.path}/$fileName";

          if (!File(fullPath).existsSync()) {
            try {
              String baseUrl = event.moshaf.server;
              if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);
              if (baseUrl.startsWith('http://')) baseUrl = baseUrl.replaceFirst('http://', 'https://');
              final url = "$baseUrl/${e.toString().padLeft(3, "0")}.mp3";
              await dio.download(url, fullPath);
              successCount++;
            } catch (err) {
              debugPrint("Download error for $surahName: $err");
            }
          }
        }
        
        Get.snackbar("اكتمل التحميل", "تم تحميل $successCount سورة للقارئ ${event.reciter.name}", 
            backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      } else if (event is ClosePlayerEvent) {
        await audioPlayer.stop();
        playerbarBloc.add(HideBarEvent());
        emit(PlayerBlocInitial());
      }
    });
  }
}