import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../../main.dart';
import '../data/radio_model.dart';
import '../data/radio_service.dart';

class RadioController extends GetxController {
  // القوائم الأصلية
  var allRadios = <QuranRadio>[].obs;
  var cairoRadio = Rxn<QuranRadio>();
  var reciterRadios = <QuranRadio>[].obs;
  var otherRadios = <QuranRadio>[].obs;

  // القوائم المفلترة للبحث
  var filteredReciterRadios = <QuranRadio>[].obs;
  var filteredOtherRadios = <QuranRadio>[].obs;

  var isLoading = true.obs;
  var errorMessage = ''.obs;
  
  var currentRadio = Rxn<QuranRadio>();
  var isPlaying = false.obs;
  var isBuffering = false.obs;
  var searchQuery = ''.obs;

  final searchController = TextEditingController();
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _playbackEventSubscription;

  // روابط إذاعة القاهرة الاحتياطية لضمان الاستقرار
  final List<String> _cairoFallbacks = [
    "https://stream.radiojar.com/8s5u5tpdtwzuv", // رابط المستخدم (الأول)
    "http://live.mp3quran.net:8006/",            // رابط mp3quran
    "https://n0a.radiojar.com/8s5u5tpdtxuvv",    // رابط بديل آخر
    "https://radioqurancairo.com/live",          // رابط الموقع المتخصص
  ];
  int _currentCairoFallbackIndex = 0;

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
    }, onError: (Object e, StackTrace st) {
      errorMessage.value = "حدث خطأ في التشغيل: $e";
      isPlaying.value = false;
    });
  }

  @override
  void onClose() {
    _playerStateSubscription?.cancel();
    _playbackEventSubscription?.cancel();
    searchController.dispose();
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
        allRadios.value = fetchedRadios;
        _categorizeRadios(fetchedRadios);
      }
    } catch (e) {
      errorMessage.value = 'فشل تحميل الإذاعات. تأكد من اتصالك بالإنترنت';
    } finally {
      isLoading.value = false;
    }
  }

  void _categorizeRadios(List<QuranRadio> list) {
    // 1. إضافة إذاعة القاهرة يدوياً بأول رابط متاح
    final cairo = QuranRadio(
      id: 828282, 
      name: "إذاعة القرآن الكريم من القاهرة",
      url: _cairoFallbacks[0],
    );
    cairoRadio.value = cairo;

    // 2. إذاعات القراء (التي تحتوي على اسم "إذاعة" وكلمة "الشيخ" أو "القارئ")
    reciterRadios.value = list.where((r) => 
      (r.name.contains('الشيخ') || r.name.contains('القارئ')) &&
      !r.name.contains('تفسير') && !r.name.contains('ترجمة')
    ).toList();

    // 3. الإذاعات الأخرى (الإذاعات العامة، التفسير، اللغات، بث مباشر)
    otherRadios.value = list.where((r) => 
      !reciterRadios.contains(r) && !r.name.contains('القاهرة')
    ).toList();

    // تهيئة القوائم المفلترة
    filteredReciterRadios.value = reciterRadios;
    filteredOtherRadios.value = otherRadios;
    
    // إذا كانت قائمة القراء فارغة لسبب ما، نضع كل شيء في "أخرى"
    if (reciterRadios.isEmpty) {
      filteredOtherRadios.value = list.where((r) => !r.name.contains('القاهرة')).toList();
    }
  }

  Future<void> playRadio(QuranRadio radio, {bool isRetry = false}) async {
    try {
      if (!isRetry && currentRadio.value?.id == radio.id && isPlaying.value) {
        await audioPlayer.pause();
        return;
      }

      currentRadio.value = radio;
      errorMessage.value = '';
      if (!isRetry) isBuffering.value = true;

      await audioPlayer.stop();
      
      await audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(radio.url),
          tag: MediaItem(
            id: 'radio_${radio.id}',
            album: 'غراس - إذاعات',
            title: radio.name,
            artist: 'إذاعة مباشرة',
            artUri: Uri.parse("asset:///assets/images/logo.png"),
          ),
        ),
      );
      
      await audioPlayer.play();
    } catch (e) {
      // منطق الاسترداد (Fallback) لإذاعة القاهرة
      if (radio.id == 828282 && _currentCairoFallbackIndex < _cairoFallbacks.length - 1) {
        _currentCairoFallbackIndex++;
        debugPrint("Cairo Radio failed, trying fallback index: $_currentCairoFallbackIndex");
        
        // إظهار تنبيه بسيط للمستخدم
        Get.snackbar(
          'تنبيه',
          'جاري محاولة رابط بديل لإذاعة القاهرة...',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange.withOpacity(0.7),
          colorText: Colors.white,
        );

        final retryRadio = QuranRadio(
          id: radio.id,
          name: radio.name,
          url: _cairoFallbacks[_currentCairoFallbackIndex],
        );
        await playRadio(retryRadio, isRetry: true);
      } else {
        errorMessage.value = 'تعذر تشغيل الإذاعة. حاول مرة أخرى';
        isBuffering.value = false;
        _currentCairoFallbackIndex = 0; // إعادة التعيين للمرة القادمة
      }
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

  void filterRadios(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredReciterRadios.value = reciterRadios;
      filteredOtherRadios.value = otherRadios;
    } else {
      filteredReciterRadios.value = reciterRadios
          .where((r) => r.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      filteredOtherRadios.value = otherRadios
          .where((r) => r.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }
}
