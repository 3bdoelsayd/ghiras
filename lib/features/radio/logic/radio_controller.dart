import 'dart:async';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../../main.dart';
import '../data/radio_model.dart';
import '../data/radio_service.dart';

class RadioController extends GetxController {
  var radios = <QuranRadio>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;
  
  var currentRadio = Rxn<QuranRadio>();
  var isPlaying = false.obs;
  var isBuffering = false.obs;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _playbackEventSubscription;

  @override
  void onInit() {
    super.onInit();
    loadRadios();
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    _playerStateSubscription = audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      isBuffering.value = state.processingState == ProcessingState.buffering ||
                         state.processingState == ProcessingState.loading;
      
      if (state.processingState == ProcessingState.completed) {
        isPlaying.value = false;
      }
    });

    _playbackEventSubscription = audioPlayer.playbackEventStream.listen((event) {
      // Handle playback errors or stalls if needed
    }, onError: (Object e, StackTrace st) {
      errorMessage.value = "حدث خطأ في التشغيل: $e";
      isPlaying.value = false;
    });
  }

  @override
  void onClose() {
    _playerStateSubscription?.cancel();
    _playbackEventSubscription?.cancel();
    super.onClose();
  }

  Future<void> loadRadios() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final fetchedRadios = await RadioService.fetchRadios();
      if (fetchedRadios.isEmpty) {
        errorMessage.value = 'لا توجد إذاعات متاحة حالياً';
      } else {
        radios.value = fetchedRadios;
      }
    } catch (e) {
      errorMessage.value = 'فشل تحميل الإذاعات. تأكد من اتصالك بالإنترنت';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> playRadio(QuranRadio radio) async {
    try {
      if (currentRadio.value?.id == radio.id && isPlaying.value) {
        await audioPlayer.pause();
        return;
      }

      currentRadio.value = radio;
      errorMessage.value = '';

      await audioPlayer.stop();
      
      await audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(radio.url),
          tag: MediaItem(
            id: 'radio_${radio.id}',
            album: 'غراس - إذاعات',
            title: radio.name,
            artist: 'إذاعة مباشرة',
          ),
        ),
      );
      
      await audioPlayer.play();
    } catch (e) {
      errorMessage.value = 'تعذر تشغيل الإذاعة. حاول مرة أخرى';
      // Retry logic could be implemented here
    }
  }

  void togglePlay() {
    if (isPlaying.value) {
      audioPlayer.pause();
    } else {
      if (currentRadio.value != null) {
        audioPlayer.play();
      }
    }
  }
}
