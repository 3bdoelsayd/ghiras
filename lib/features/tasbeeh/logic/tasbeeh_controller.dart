import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TasbeehController extends GetxController {
  var count = 0.obs;
  var totalCount = 0.obs;
  var selectedTarget = 0.obs; // 0 means no target
  late Box _box;

  @override
  void onInit() {
    super.onInit();
    _box = Hive.box('settings');
    count.value = _box.get('tasbeeh_count', defaultValue: 0);
    totalCount.value = _box.get('tasbeeh_total', defaultValue: 0);
    selectedTarget.value = _box.get('tasbeeh_target', defaultValue: 0);
  }

  void increment() {
    count.value++;
    totalCount.value++;
    _save();
    
    if (selectedTarget.value > 0 && count.value == selectedTarget.value) {
      Get.snackbar(
        'مبارك!',
        'لقد أتممت تحدي ${selectedTarget.value} تسبيحة',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void reset() {
    count.value = 0;
    _save();
  }

  void setTarget(int target) {
    selectedTarget.value = target;
    _box.put('tasbeeh_target', target);
  }

  void _save() {
    _box.put('tasbeeh_count', count.value);
    _box.put('tasbeeh_total', totalCount.value);
  }

  double get progress {
    if (selectedTarget.value == 0) return 0.0;
    return (count.value / selectedTarget.value).clamp(0.0, 1.0);
  }
}
