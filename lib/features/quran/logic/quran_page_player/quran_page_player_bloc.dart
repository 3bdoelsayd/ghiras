import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../core/helpers/hive_helper.dart';
import 'package:ghiras/main.dart';

part 'quran_page_player_event.dart';
part 'quran_page_player_state.dart';

class QuranPagePlayerBloc
    extends Bloc<QuranPagePlayerEvent, QuranPagePlayerState> {
  QuranPagePlayerBloc() : super(QuranPagePlayerInitial()) {

    on<QuranPagePlayerEvent>((event, emit) async {
      if (event is PlayFromVerse) {
        String? storedJsonString = getValue(
          "${event.reciterIdentifier}-${event.suraName.replaceAll(" ", "")}-durations",
        );

        if (storedJsonString == null) {
          Fluttertoast.showToast(msg: "بيانات التوقيت غير متوفرة");
          return;
        }

        List<dynamic> decodedList;
        try {
          decodedList = json.decode(storedJsonString);
        } catch (e) {
          Fluttertoast.showToast(msg: "خطأ في بيانات التوقيت");
          return;
        }

        List durations = List.from(decodedList);

        final verseData = durations.firstWhere(
          (element) => element["verseNumber"] == event.verse,
          orElse: () => null,
        );
        if (verseData == null) {
          Fluttertoast.showToast(msg: "توقيت الآية غير متوفر");
          return;
        }
        double duration = verseData["startDuration"];

        final reciterMatch = {
          "identifier": event.reciterIdentifier,
          "englishName": event.reciterIdentifier,
        };

        // استخدام مسار آمن
        final appDir = await getApplicationDocumentsDirectory();
        final filePath =
            "${appDir.path}/audio-${event.reciterIdentifier}-${event.suraName.replaceAll(" ", "")}.mp3";

        if (!File(filePath).existsSync()) {
          Fluttertoast.showToast(msg: "ملف الصوت غير موجود، يرجى التحميل أولاً");
          return;
        }

        try {
          // ✅ استخدام الـ global audioPlayer
          await audioPlayer.stop();
          await audioPlayer.setAudioSource(
            AudioSource.file(
              filePath,
              tag: MediaItem(
                id: event.suraName,
                album: reciterMatch["englishName"],
                title: quran.getSurahNameArabic(event.surahNumber),
                artUri: Uri.parse("https://ghiras.app/logo.png"),
              ),
            ),
          );
          
          await audioPlayer.seek(Duration(milliseconds: duration.toInt()));
          await audioPlayer.play();
          
          emit(QuranPagePlayerPlaying(
            player: audioPlayer,
            audioPlayerStream: audioPlayer.positionStream,
            suraNumber: event.surahNumber,
            reciter: reciterMatch,
            durations: durations,
          ));
        } on PlayerException catch (e) {
          Fluttertoast.showToast(msg: "خطأ في المشغل: ${e.message}");
          return;
        } catch (e) {
          Fluttertoast.showToast(msg: "خطأ أثناء تشغيل الملف");
          return;
        }

      } else if (event is PlayUrl) {
        try {
          await audioPlayer.stop();
          await audioPlayer.setAudioSource(
            AudioSource.uri(
              Uri.parse(event.url),
              tag: MediaItem(
                id: event.url,
                album: "القرآن الكريم",
                title: event.title,
                artUri: Uri.parse("https://ghiras.app/logo.png"),
              ),
            ),
          );
          await audioPlayer.play();
        } catch (e) {
          Fluttertoast.showToast(msg: "خطأ أثناء تشغيل الرابط");
          debugPrint("PlayUrl Error: $e");
        }

      } else if (event is PausePlaying) {
        await audioPlayer.pause();

      } else if (event is StopPlaying) {
        await audioPlayer.stop();
        emit(QuranPagePlayerStopped());

      } else if (event is KillPlayerEvent) {
        await audioPlayer.stop();
        emit(QuranPagePlayerIdle());
      }
    });
  }
}
