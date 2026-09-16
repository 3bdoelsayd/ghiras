import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/sleep_timer_service.dart';

class SleepTimerDialog extends StatelessWidget {
  const SleepTimerDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => const SleepTimerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerService = Get.find<SleepTimerService>();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'مؤقت النوم',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'إيقاف التشغيل تلقائياً بعد مرور الوقت المحدد',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 24),
          Obx(() {
            if (timerService.isActive) {
              return Column(
                children: [
                  Text(
                    'المتبقي: ${timerService.formattedRemainingTime}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      timerService.cancelTimer();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('إيقاف المؤقت', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ],
              );
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildTimerOption(context, timerService, '15 دقيقة', 15),
                _buildTimerOption(context, timerService, '30 دقيقة', 30),
                _buildTimerOption(context, timerService, '45 دقيقة', 45),
                _buildTimerOption(context, timerService, 'ساعة', 60),
                _buildTimerOption(context, timerService, 'ساعتين', 120),
              ],
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTimerOption(BuildContext context, SleepTimerService service, String label, int minutes) {
    return InkWell(
      onTap: () {
        service.setTimer(Duration(minutes: minutes));
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
