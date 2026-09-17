import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/sleep_timer_service.dart';

class SleepTimerDialog extends StatefulWidget {
  const SleepTimerDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const SleepTimerDialog(),
      ),
    );
  }

  @override
  State<SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<SleepTimerDialog> {
  final TextEditingController _customMinsController = TextEditingController();

  @override
  void dispose() {
    _customMinsController.dispose();
    super.dispose();
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
                      backgroundColor: Colors.red.withOpacity(0.1),
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
            return Column(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildTimerOption(context, timerService, '15 دقيقة', 15),
                    _buildTimerOption(context, timerService, '30 دقيقة', 30),
                    _buildTimerOption(context, timerService, '45 دقيقة', 45),
                    _buildTimerOption(context, timerService, 'ساعة', 60),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                const Text('أو حدد وقتك الخاص بالدقائق:', 
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey)
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: TextField(
                        controller: _customMinsController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: '00',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final mins = int.tryParse(_customMinsController.text);
                        if (mins != null && mins > 0) {
                          timerService.setTimer(Duration(minutes: mins));
                          Navigator.pop(context);
                        } else {
                          Get.snackbar('تنبيه', 'يرجى إدخال عدد دقائق صحيح', 
                            snackPosition: SnackPosition.BOTTOM
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      child: const Text('بدء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            );
          }),
          const SizedBox(height: 24),
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
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
