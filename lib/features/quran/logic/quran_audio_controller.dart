import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:quran/quran.dart' as quran;
import 'mushaf_controller.dart';
import 'package:flutter/material.dart';
import 'package:ghiras/main.dart'; // ✅ نستخدم الـ instance الـ global

class QuranAudioController extends GetxController {
  // ✅ مش بنعمل AudioPlayer جديد — بنستخدم الـ global
  AudioPlayer get _audioPlayer => audioPlayer;

  var isPlaying = false.obs;
  var currentSurah = 0.obs;
  var currentAyah = 0.obs;
  var isLoading = false.obs;
  var progress = 0.0.obs;

  bool _isTransitioning = false;

  @override
  void onInit() {
    super.onInit();
    // ✅ نعتمد على الـ AudioSession العالمي الذي تم تهيئته في main.dart

    _audioPlayer.playerStateStream.listen((state) {
      if (currentSurah.value != 0) {
        isPlaying.value = state.playing;
        if (state.processingState == ProcessingState.completed) {
          if (!_isTransitioning) {
            _playNextAyah();
          }
        }
      }
    });

    _audioPlayer.positionStream.listen((pos) {
      if (currentSurah.value != 0) {
        final total = _audioPlayer.duration?.inMilliseconds ?? 1;
        progress.value = (pos.inMilliseconds / total).clamp(0.0, 1.0);
      }
    });
  }

  @override
  void onClose() {
    // ❌ مش بنعمل dispose للـ global player
    super.onClose();
  }

  var selectedReciter = 'ar.alafasy'.obs;

  int _getVerseId(int surah, int ayah) {
    int verseId = 0;
    for (int s = 1; s < surah; s++) {
      verseId += quran.getVerseCount(s);
    }
    verseId += ayah;
    return verseId;
  }

  Future<void> playAyah(int surah, int ayah) async {
    try {
      _isTransitioning = true;
      isLoading.value = true;

      currentSurah.value = surah;
      currentAyah.value = ayah;

      _syncMushafPage(surah, ayah);

      int verseId = _getVerseId(surah, ayah);

      // ✅ استخدام https دائماً
      final url =
          'https://cdn.islamic.network/quran/audio/128/${selectedReciter.value}/$verseId.mp3';

      // ✅ تأكدنا من استخدام الـ global player
      await _audioPlayer.stop();

      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          headers: {
            'User-Agent': 'GhirasApp/1.0 (Android; Quran Audio Player)',
          },
          tag: MediaItem(
            id: 'ayah_$verseId',
            album: 'تلاوة الآيات',
            title: "سورة ${quran.getSurahNameArabic(surah)} - آية $ayah",
            artist: "تطبيق غراس",
            artUri: Uri.parse("https://ghiras.app/logo.png"),
          ),
        ),
      );

      await _audioPlayer.play();

      isLoading.value = false;
      _isTransitioning = false;
    } on PlayerException catch (e) {
      isLoading.value = false;
      _isTransitioning = false;
      debugPrint("Audio Playback Error: ${e.message}");
    } catch (e) {
      isLoading.value = false;
      _isTransitioning = false;
      debugPrint("Audio Playback Error: $e");
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

  Future<void> _playNextAyah() async {
    if (currentSurah.value == 0 || _isTransitioning) return;

    int nextAyah = currentAyah.value + 1;
    int surah = currentSurah.value;

    if (nextAyah > quran.getVerseCount(surah)) {
      if (surah < 114) {
        surah++;
        nextAyah = 1;
      } else {
        stop();
        return;
      }
    }
    await playAyah(surah, nextAyah);
  }
}