import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran/quran.dart' as quran;
import 'mushaf_controller.dart';
import 'package:ghiras/main.dart'; // ✅ نستخدم الـ instance الـ global

class QuranAudioController extends GetxController {
  // ✅ استخدام الـ AudioPlayer العالمي
  AudioPlayer get _audioPlayer => audioPlayer;

  var isPlaying = false.obs;
  var currentSurah = 0.obs;
  var currentAyah = 0.obs;
  var isLoading = false.obs;
  var progress = 0.0.obs;
  var selectedReciter = 'ar.alafasy'.obs;

  StreamSubscription? _playerStateSub;
  StreamSubscription? _indexSub;
  StreamSubscription? _posSub;

  @override
  void onInit() {
    super.onInit();

    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (currentSurah.value != 0) {
        isPlaying.value = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _onSurahCompleted();
        }
      }
    });

    _indexSub = _audioPlayer.currentIndexStream.listen((index) {
      if (currentSurah.value != 0 && index != null) {
        final newAyah = index + 1;
        if (newAyah != currentAyah.value) {
          currentAyah.value = newAyah;
          _syncMushafPage(currentSurah.value, newAyah);
        }
      }
    });

    _posSub = _audioPlayer.positionStream.listen((pos) {
      if (currentSurah.value != 0) {
        final total = _audioPlayer.duration?.inMilliseconds ?? 1;
        progress.value = (pos.inMilliseconds / total).clamp(0.0, 1.0);
      }
    });
  }

  @override
  void onClose() {
    _playerStateSub?.cancel();
    _indexSub?.cancel();
    _posSub?.cancel();
    super.onClose();
  }

  int _getVerseId(int surah, int ayah) {
    int verseId = 0;
    for (int s = 1; s < surah; s++) {
      verseId += quran.getVerseCount(s);
    }
    verseId += ayah;
    return verseId;
  }

  String _getReciterName(String identifier) {
    switch (identifier) {
      case 'ar.alafasy':
        return 'الشيخ مشاري العفاسي';
      case 'ar.abdulbasitmurattal':
        return 'الشيخ عبد الباسط عبد الصمد';
      case 'ar.minshawi':
        return 'الشيخ محمد صديق المنشاوي';
      case 'ar.husary':
        return 'الشيخ محمود خليل الحصري';
      default:
        return 'تلاوة قرآنية';
    }
  }

  Future<void> playAyah(int surah, int ayah) async {
    try {
      isLoading.value = true;

      final bool isNewSurah = currentSurah.value != surah ||
          _audioPlayer.audioSource == null;

      currentSurah.value = surah;
      currentAyah.value = ayah;

      _syncMushafPage(surah, ayah);

      if (isNewSurah) {
        final verseCount = quran.getVerseCount(surah);
        final surahName = quran.getSurahNameArabic(surah);
        final reciterName = _getReciterName(selectedReciter.value);

        List<AudioSource> sources = [];
        for (int i = 1; i <= verseCount; i++) {
          int verseId = _getVerseId(surah, i);
          final url =
              'https://cdn.islamic.network/quran/audio/128/${selectedReciter.value}/$verseId.mp3';

          sources.add(
            AudioSource.uri(
              Uri.parse(url),
              headers: {
                'User-Agent': 'GhirasApp/1.0 (Android; Quran Audio Player)',
              },
              tag: MediaItem(
                id: 'surah_${surah}_ayah_$i',
                album: 'سورة $surahName',
                title: 'سورة $surahName - آية $i',
                artist: reciterName,
                artUri: Uri.parse("asset:///assets/images/logo.png"),
              ),
            ),
          );
        }

        final playlist = ConcatenatingAudioSource(children: sources);
        await _audioPlayer.stop();
        await _audioPlayer.setAudioSource(playlist, initialIndex: ayah - 1);
      } else {
        if (_audioPlayer.currentIndex != ayah - 1) {
          await _audioPlayer.seek(Duration.zero, index: ayah - 1);
        }
      }

      await _audioPlayer.play();
      isLoading.value = false;
    } on PlayerException catch (e) {
      isLoading.value = false;
      debugPrint("Audio Playback Error: ${e.message}");
    } catch (e) {
      isLoading.value = false;
      debugPrint("Audio Playback Error: $e");
    }
  }

  Future<void> playNextAyah() async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
    } else if (currentSurah.value > 0 && currentSurah.value < 114) {
      await playAyah(currentSurah.value + 1, 1);
    }
  }

  Future<void> playPreviousAyah() async {
    if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
    } else if (currentSurah.value > 1) {
      int prevSurah = currentSurah.value - 1;
      int lastAyah = quran.getVerseCount(prevSurah);
      await playAyah(prevSurah, lastAyah);
    }
  }

  void _onSurahCompleted() {
    if (currentSurah.value > 0 && currentSurah.value < 114) {
      playAyah(currentSurah.value + 1, 1);
    } else {
      stop();
    }
  }

  void togglePlay() {
    if (isPlaying.value) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void _syncMushafPage(int surah, int ayah) {
    if (Get.isRegistered<MushafController>()) {
      final mushafController = Get.find<MushafController>();
      final pageOfAyah = quran.getPageNumber(surah, ayah);
      if (mushafController.currentPage.value != pageOfAyah) {
        mushafController.onPageChanged(pageOfAyah - 1);
      }
    }
  }

  void stop() {
    _audioPlayer.stop();
    currentSurah.value = 0;
    currentAyah.value = 0;
    isPlaying.value = false;
  }
}
