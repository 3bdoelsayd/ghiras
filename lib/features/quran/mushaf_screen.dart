import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'logic/mushaf_controller.dart';
import 'logic/quran_audio_controller.dart';
import 'widgets/quran_page_widget.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/glass_container.dart';

class MushafScreen extends StatefulWidget {
  final int initialPage;
  const MushafScreen({super.key, this.initialPage = 1});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);
    final controller = Get.put(MushafController());
    Get.put(QuranAudioController());
    controller.currentPage.value = widget.initialPage;
    controller.loadCurrentPageFont();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MushafController>();
    final audioController = Get.find<QuranAudioController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() => Text(
          'الصفحة ${controller.currentPage.value}',
          style: const TextStyle(fontSize: 18),
        )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context, controller),
          ),
          Obx(() => IconButton(
            icon: Icon(controller.isDarkMode.value
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: controller.toggleTheme,
          )),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: PageView.builder(
                controller: _pageController,
                reverse: false,
                itemCount: 605,
                physics: const BouncingScrollPhysics(),
                allowImplicitScrolling: true,
                onPageChanged: (index) {
                  if (index == 0) {
                    controller.currentPage.value = 0;
                  } else {
                    controller.onPageChanged(index - 1);
                  }
                },
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCoverPage();
                  }
                  return RepaintBoundary(
                    child: QuranPageWidget(pageNumber: index),
                  );
                },
              ),
            ),
          ),
          Obx(() => audioController.currentSurah.value != 0
              ? Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: _buildAudioPlayer(audioController),
              ),
            ),
          )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildCoverPage() {
    return Container(
      color: const Color(0xFF1A1200),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/quran.jpg',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.2),
          ),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'القُرآنُ الكريمُ',
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                    shadows: [
                      Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                          offset: Offset(2, 2))
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'برواية حفص عن عاصم',
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer(QuranAudioController audio) {
    return GlassContainer(
      opacity: 0.8,
      blur: 20,
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Obx(() => Row(
          children: [
            IconButton(
              icon: audio.isLoading.value
                  ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(
                  audio.isPlaying.value
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  size: 40,
                  color: AppColors.primary),
              onPressed: audio.togglePlay,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'آية ${audio.currentAyah.value}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: audio.progress.value,
                    backgroundColor: Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 20, color: Colors.grey),
              onPressed: audio.stop,
            ),
          ],
        )),
      ),
    );
  }

  void _showSettings(BuildContext context, MushafController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('حجم الخط',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Obx(() => Slider(
              value: controller.fontSize.value,
              min: 18,
              max: 32,
              onChanged: (val) => controller.updateFontSize(val),
              activeColor: AppColors.primary,
            )),
          ],
        ),
      ),
    );
  }
}