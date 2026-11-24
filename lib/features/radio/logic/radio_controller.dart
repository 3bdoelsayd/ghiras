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
  StreamSubscription? _currentIndexSubscription;

  // روابط إذاعة القاهرة الاحتياطية لضمان الاستقرار
  final List<String> _cairoFallbacks = [
    "https://stream.radiojar.com/8s5u5tpdtwzuv", // رابط المستخدم الأول
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
      if (currentRadio.value != null) {
        isPlaying.value = state.playing;
        isBuffering.value = state.processingState == ProcessingState.buffering ||
                           state.processingState == ProcessingState.loading;

        // في حال انقطاع البث المباشر أثناء التشغيل نعيد الاتصال تلقائياً
        if (state.processingState == ProcessingState.idle && isPlaying.value) {
          _reconnectRadio();
        }
      }
    });

    _currentIndexSubscription = audioPlayer.currentIndexStream.listen((index) {
      if (index != null && allRadios.isNotEmpty && index < allRadios.length) {
        final radio = allRadios[index];
        if (currentRadio.value?.id != radio.id) {
          currentRadio.value = radio;
        }
      }
    });

    _playbackEventSubscription = audioPlayer.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace st) {
      debugPrint("Radio Playback Error: $e");
      if (currentRadio.value != null && isPlaying.value) {
        _reconnectRadio();
      } else {
        errorMessage.value = "حدث خطأ في تشغيل الإذاعة: $e";
      }
    });
  }

  void _reconnectRadio() {
    if (currentRadio.value != null) {
      Future.delayed(const Duration(seconds: 2), () {
        if (currentRadio.value != null && isPlaying.value) {
          playRadio(currentRadio.value!, isRetry: true);
        }
      });
    }
  }

  @override
  void onClose() {
    _playerStateSubscription?.cancel();
    _playbackEventSubscription?.cancel();
    _currentIndexSubscription?.cancel();
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
        _categorizeRadios(fetchedRadios);
      }
    } catch (e) {
      errorMessage.value = 'فشل تحميل الإذاعات. تأكد من اتصالك بالإنترنت';
    } finally {
      isLoading.value = false;
    }
  }

  void _categorizeRadios(List<QuranRadio> list) {
    // 1. إضافة إذاعة القاهرة
    final cairo = QuranRadio(
      id: 828282, 
      name: "إذاعة القرآن الكريم من القاهرة",
      url: _cairoFallbacks[0],
    );
    cairoRadio.value = cairo;

    // 2. تجميع كافة الإذاعات لتمكين التبديل عبر شريط الإشعارات والتحكم الخارجي
    List<QuranRadio> fullList = [cairo];
    fullList.addAll(list.where((r) => !r.name.contains('القاهرة')));
    allRadios.value = fullList;

    // 3. إذاعات القراء
    reciterRadios.value = list.where((r) => 
      (r.name.contains('الشيخ') || r.name.contains('القارئ')) &&
      !r.name.contains('تفسير') && !r.name.contains('ترجمة')
    ).toList();

    // 4. الإذاعات الأخرى
    otherRadios.value = list.where((r) => 
      !reciterRadios.contains(r) && !r.name.contains('القاهرة')
    ).toList();

    // تهيئة القوائم المفلترة
    filteredReciterRadios.value = reciterRadios;
    filteredOtherRadios.value = otherRadios;
    
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

      int index = allRadios.indexWhere((r) => r.id == radio.id);
      if (index == -1) index = 0;

      // بناء قائمة تشغيل كاملة تمكّن المستخدم من التبديل بين الإذاعات من قفل الشاشة وشريط الإشعارات
      List<AudioSource> sources = allRadios.map((r) {
        return AudioSource.uri(
          Uri.parse(r.url),
          tag: MediaItem(
            id: 'radio_${r.id}',
            album: 'إذاعات القرآن الكريم',
            title: r.name,
            artist: 'بث مباشر - غراس',
            artUri: Uri.parse("asset:///assets/images/logo.png"),
          ),
        );
      }).toList();

      await audioPlayer.stop();
      await audioPlayer.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: index,
      );
      
      await audioPlayer.play();
    } catch (e) {
      if (radio.id == 828282 && _currentCairoFallbackIndex < _cairoFallbacks.length - 1) {
        _currentCairoFallbackIndex++;
        
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
        _currentCairoFallbackIndex = 0;
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
