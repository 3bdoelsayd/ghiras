import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import 'home/home_screen.dart';
import 'quran/quran_home_screen.dart';
import 'tasbeeh/views/tasbeeh_screen.dart';
import 'quran/views/reciters_page.dart';
import 'athkar/athkar_screen.dart';
import '../shared/widgets/mini_player_bar.dart';

class MainLayoutController extends GetxController {
  var currentIndex = 0.obs;

  final List<Widget> pages = [
    const HomeScreen(),
    const QuranHomeScreen(),
    const TasbeehScreen(),
    const RecitersPage(),
    const AthkarScreen(),
  ];

  void changeIndex(int index) {
    if (currentIndex.value != index) {
      HapticFeedback.lightImpact();
      currentIndex.value = index;
    }
  }
}

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainLayoutController());

    return Scaffold(
      extendBody: true, // للسماح للمحتوى بالظهور خلف البار الشفاف
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: controller.pages,
      )),
      bottomNavigationBar: _GhirasBottomBar(controller: controller),
    );
  }
}

class _GhirasBottomBar extends StatelessWidget {
  final MainLayoutController controller;
  const _GhirasBottomBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Container(
        margin: EdgeInsets.fromLTRB(24.w, 0, 24.w, 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFFDFDFD),
              const Color(0xFFF5F5F5), // تدرج خفيف يعطي إيحاء 3D
            ],
          ),
          boxShadow: [
            // ظل سفلي عميق للبروز
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            // ظل علوي فاتح جداً لتحديد الحواف (إيحاء 3D)
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 2,
              offset: const Offset(0, -1),
            ),
          ],
          border: Border.all(color: Colors.white, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayerBar(), // مدمج الآن داخل نفس الحاوية
            SizedBox(
              height: 62.h,
              child: Obx(() {
                final int currentIdx = controller.currentIndex.value;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      index: 0,
                      isSelected: currentIdx == 0,
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'الرئيسية',
                      controller: controller,
                    ),
                    _NavItem(
                      index: 1,
                      isSelected: currentIdx == 1,
                      icon: Icons.menu_book_outlined,
                      activeIcon: Icons.menu_book_rounded,
                      label: 'الفهرس',
                      controller: controller,
                    ),
                    _NavItem(
                      index: 2,
                      isSelected: currentIdx == 2,
                      icon: Icons.fingerprint_rounded,
                      activeIcon: Icons.fingerprint_rounded,
                      label: 'المسبحة',
                      controller: controller,
                    ),
                    _NavItem(
                      index: 3,
                      isSelected: currentIdx == 3,
                      icon: Icons.record_voice_over_outlined,
                      activeIcon: Icons.record_voice_over_rounded,
                      label: 'القراء',
                      controller: controller,
                    ),
                    _NavItem(
                      index: 4,
                      isSelected: currentIdx == 4,
                      icon: Icons.flare_outlined,
                      activeIcon: Icons.flare_rounded,
                      label: 'الأذكار',
                      controller: controller,
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final bool isSelected;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final MainLayoutController controller;

  const _NavItem({
    required this.index,
    required this.isSelected,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeIndex(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // تأمين المسافة
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h), // تقليل الحشو
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  )
                ] : null,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey<bool>(isSelected),
                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                  size: 19.sp, // تقليل بسيط جداً في الحجم
                ),
              ),
            ),
            if (isSelected)
              Padding(
                padding: EdgeInsets.only(top: 1.h), // تقليل المسافة بين الأيقونة والنص
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
