import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../logic/tasbeeh_controller.dart';
import '../../../shared/widgets/glass_container.dart';

class TasbeehScreen extends StatelessWidget {
  const TasbeehScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TasbeehController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المسبحة الإلكترونية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: CircleAvatar(radius: 150, backgroundColor: AppColors.primary.withOpacity(0.03)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildTotalStats(controller),
                  const SizedBox(height: 30),
                  _buildMainCounter(controller),
                  const SizedBox(height: 30),
                  _buildChallenges(controller),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalStats(TasbeehController controller) {
    return Obx(() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassContainer(
        opacity: 0.05,
        borderRadius: 24,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('إجمالي التسبيح', '${controller.totalCount.value}', Icons.all_inclusive_rounded),
              Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.2)),
              _buildStatItem('التحدي الحالي', controller.selectedTarget.value == 0 ? 'لا يوجد' : '${controller.selectedTarget.value}', Icons.emoji_events_rounded),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey, fontFamily: 'Cairo')),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Cairo')),
      ],
    );
  }

  Widget _buildMainCounter(TasbeehController controller) {
    return Builder(
      builder: (context) => Column(
        children: [
          Obx(() => Text(
            '${controller.count.value}',
            style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: AppColors.primary, fontFamily: 'Cairo'),
          )),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () => controller.increment(),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 40, offset: const Offset(0, 20)),
                ],
                border: Border.all(color: AppColors.primary.withOpacity(0.05), width: 8),
              ),
              child: Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.prayerCardGrad2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 60),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          TextButton.icon(
            onPressed: () => _showResetConfirm(context, controller),
            icon: const Icon(Icons.refresh_rounded, color: Colors.redAccent),
            label: const Text('تصفير العداد', style: TextStyle(color: Colors.redAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildChallenges(TasbeehController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text('تحديات التسبيح', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildChallengeCard(controller, 33, 'سنة'),
              _buildChallengeCard(controller, 100, 'تحدي'),
              _buildChallengeCard(controller, 1000, 'إنجاز'),
              _buildChallengeCard(controller, 5000, 'عظيم'),
              _buildChallengeCard(controller, 10000, 'خاتم'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(TasbeehController controller, int target, String label) {
    return Obx(() {
      final isSelected = controller.selectedTarget.value == target;
      return GestureDetector(
        onTap: () => controller.setTarget(target),
        child: Container(
          width: 100,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.primary : Colors.black12),
            boxShadow: [
              if (isSelected) BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$target', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textDark, fontFamily: 'Cairo')),
              Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : AppColors.textGrey, fontFamily: 'Cairo')),
            ],
          ),
        ),
      );
    });
  }

  void _showResetConfirm(BuildContext context, TasbeehController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تصفير العداد', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من رغبتك في تصفير العداد الحالي؟', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            onPressed: () {
              controller.reset();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('تصفير', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
