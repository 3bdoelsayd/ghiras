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
    Get.put(MainLayoutController());

    return Scaffold(
      extendBody: true, // للسماح للمحتوى بالظهور خلف البار الشفاف
      body: Obx(() {
        final controller = Get.find<MainLayoutController>();
        return IndexedStack(
          index: controller.currentIndex.value,
          children: controller.pages,
        );
      }),
      bottomNavigationBar: GetBuilder<MainLayoutController>(
        builder: (controller) => _GhirasBottomBar(controller: controller),
      ),
    );
  }
}

class _GhirasBottomBar extends StatelessWidget {
  final MainLayoutController controller;
  const _GhirasBottomBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return SafeArea(
      bottom: true,
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 550 : double.infinity),
          child: Container(
            margin: EdgeInsets.fromLTRB(
              isTablet ? 24 : 24.w,
              0,
              isTablet ? 24 : 24.w,
              isTablet ? 12 : 10.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Color(0xFFFDFDFD),
                  Color(0xFFF5F5F5), // تدرج خفيف يعطي إيحاء 3D
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
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
                const MiniPlayerBar(), // مدمج داخل نفس الحاوية
                SizedBox(
                  height: isTablet ? 58 : 62.h,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final double iconSize = isTablet ? 21.0 : 19.sp;
    final double fontSize = isTablet ? 9.5 : 8.sp;
    final EdgeInsets itemPadding = EdgeInsets.symmetric(
      horizontal: isTablet ? 12 : 10.w,
      vertical: isTablet ? 4 : 3.h,
    );

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeIndex(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: itemPadding,
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
                  size: iconSize,
                ),
              ),
            ),
            if (isSelected)
              Padding(
                padding: EdgeInsets.only(top: isTablet ? 2 : 1.h),
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: fontSize,
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
