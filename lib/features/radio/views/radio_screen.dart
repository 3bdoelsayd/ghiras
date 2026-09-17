import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../logic/radio_controller.dart';
import '../data/radio_model.dart';

class RadioScreen extends StatelessWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RadioController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            // 1. قسم إذاعة القاهرة (المميزة)
            Obx(() {
              if (controller.cairoRadio.value == null) return const SizedBox.shrink();
              return _buildFeaturedCairoCard(controller);
            }),

            // 2. شريط البحث
            _buildSearchBar(controller),

            // 3. التبويبات
            _buildTabBar(),

            // 4. محتوى التبويبات
            Expanded(
              child: TabBarView(
                children: [
                  _buildRadioList(controller, controller.filteredReciterRadios),
                  _buildRadioList(controller, controller.filteredOtherRadios),
                ],
              ),
            ),

            // 5. المشغل الصغير
            _buildMiniPlayer(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCairoCard(RadioController controller) {
    final radio = controller.cairoRadio.value!;
    return Obx(() {
      final isSelected = controller.currentRadio.value?.id == radio.id;
      final isPlaying = isSelected && controller.isPlaying.value;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A5F4A), Color(0xFF0F3D2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A5F4A).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                right: -15,
                bottom: -15,
                child: Icon(Icons.mosque_rounded, size: 70, color: Colors.white.withOpacity(0.05)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC9A84C).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'الإذاعة الأكثر استماعاً',
                              style: TextStyle(color: Color(0xFFC9A84C), fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            radio.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => controller.playRadio(radio),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC9A84C),
                          shape: BoxShape.circle,
                        ),
                        child: controller.isBuffering.value && isSelected
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              )
                            : Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSearchBar(RadioController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller.searchController,
          onChanged: controller.filterRadios,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
          decoration: InputDecoration(
            hintText: 'ابحث عن إذاعة أو قارئ...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13, fontFamily: 'Cairo'),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
            suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      controller.searchController.clear();
                      controller.filterRadios('');
                    },
                  )
                : const SizedBox.shrink()),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'القراء'),
          Tab(text: 'إذاعات أخرى'),
        ],
      ),
    );
  }

  Widget _buildRadioList(RadioController controller, RxList<QuranRadio> list) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }

      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              const Text(
                'لا توجد نتائج مطابقة لبحثك',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final radio = list[index];
          return _buildRadioTile(context, radio, controller);
        },
      );
    });
  }

  Widget _buildRadioTile(BuildContext context, QuranRadio radio, RadioController controller) {
    return Obx(() {
      try {
        final isSelected = controller.currentRadio.value?.id == radio.id;
        final isPlaying = isSelected && controller.isPlaying.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isSelected 
                ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1)
                : BorderSide.none.style == BorderStyle.none ? Border.all(color: Colors.black.withOpacity(0.03)) : null,
          ),
          child: Material(
            color: Colors.transparent, // حماية تأثير الضغط
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.headphones_rounded,
                  color: isSelected ? AppColors.primary : Colors.grey[400],
                  size: 20,
                ),
              ),
              title: Text(
                radio.name,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              trailing: isSelected && controller.isBuffering.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : Icon(
                      isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                      color: isSelected ? AppColors.primary : const Color(0xFF1A5F4A).withOpacity(0.7),
                      size: 28,
                    ),
              onTap: () => controller.playRadio(radio),
            ),
          ),
        );
      } catch (e) {
        return const SizedBox.shrink();
      }
    });
  }

  Widget _buildMiniPlayer(RadioController controller) {
    return Obx(() {
      if (controller.currentRadio.value == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.radio_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.currentRadio.value!.name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      'جاري البث المباشر الآن',
                      style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
              ),
              if (controller.isBuffering.value)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                IconButton(
                  icon: Icon(
                    controller.isPlaying.value ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                  onPressed: controller.togglePlay,
                ),
            ],
          ),
        ),
      );
    });
  }
}
