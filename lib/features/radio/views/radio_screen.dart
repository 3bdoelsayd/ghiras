import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../logic/radio_controller.dart';
import '../data/radio_model.dart';

class RadioScreen extends StatelessWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RadioController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F1),
      appBar: AppBar(
        title: const Text(
          'إذاعات القرآن الكريم',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w900,
            color: Color(0xFF2C3E50),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (controller.errorMessage.isNotEmpty && controller.radios.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        controller.errorMessage.value,
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.loadRadios,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.radios.length,
                itemBuilder: (context, index) {
                  final radio = controller.radios[index];
                  return _buildRadioTile(context, radio, controller);
                },
              );
            }),
          ),
          _buildMiniPlayer(controller),
        ],
      ),
    );
  }

  Widget _buildRadioTile(BuildContext context, QuranRadio radio, RadioController controller) {
    return Obx(() {
      final isSelected = controller.currentRadio.value?.id == radio.id;
      final isPlaying = isSelected && controller.isPlaying.value;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.radio_rounded,
              color: isSelected ? AppColors.primary : Colors.grey[400],
            ),
          ),
          title: Text(
            radio.name,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
              color: const Color(0xFF2C3E50),
            ),
          ),
          trailing: isSelected && controller.isBuffering.value
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              : IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                    color: isSelected ? AppColors.primary : const Color(0xFF1A5F4A),
                    size: 32,
                  ),
                  onPressed: () => controller.playRadio(radio),
                ),
          onTap: () => controller.playRadio(radio),
        ),
      );
    });
  }

  Widget _buildMiniPlayer(RadioController controller) {
    return Obx(() {
      if (controller.currentRadio.value == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'جاري التشغيل الآن',
                    style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo'),
                  ),
                  Text(
                    controller.currentRadio.value!.name,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                controller.isPlaying.value ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 36,
                color: AppColors.primary,
              ),
              onPressed: controller.togglePlay,
            ),
          ],
        ),
      );
    });
  }
}
