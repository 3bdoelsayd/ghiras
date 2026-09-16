import 'dart:async';
import 'package:get/get.dart';
import 'package:ghiras/main.dart';

class SleepTimerService extends GetxService {
  Timer? _timer;
  final Rx<Duration?> remainingTime = Rx<Duration?>(null);

  bool get isActive => remainingTime.value != null;

  void setTimer(Duration duration) {
    cancelTimer();
    remainingTime.value = duration;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime.value == null) {
        timer.cancel();
        return;
      }

      if (remainingTime.value!.inSeconds <= 0) {
        _onTimerFinished();
        timer.cancel();
      } else {
        remainingTime.value = remainingTime.value! - const Duration(seconds: 1);
      }
    });
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    remainingTime.value = null;
  }

  void _onTimerFinished() {
    audioPlayer.stop();
    cancelTimer();
    Get.snackbar(
      'مؤقت النوم',
      'تم إيقاف القراءة كما هو محدد في المؤقت',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String get formattedRemainingTime {
    if (remainingTime.value == null) return '';
    final minutes = remainingTime.value!.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remainingTime.value!.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
