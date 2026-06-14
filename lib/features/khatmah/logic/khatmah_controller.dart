import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/khatmah_model.dart';
import 'package:uuid/uuid.dart';

class KhatmahController extends GetxController {
  var khatmat = <KhatmahModel>[].obs;
  late Box _khatmahBox;

  @override
  void onInit() async {
    super.onInit();
    _khatmahBox = await Hive.openBox('khatmah_box');
    _loadKhatmat();
  }

  void _loadKhatmat() {
    final data = _khatmahBox.get('khatmat_list', defaultValue: []);
    if (data is List) {
      final List<KhatmahModel> list = data.map((e) {
        return KhatmahModel.fromMap(Map<String, dynamic>.from(e as Map));
      }).toList();
      khatmat.assignAll(list);
    }
  }

  void addKhatmah(String title, int days, {int startPage = 1}) {
    final newKhatmah = KhatmahModel(
      id: const Uuid().v4(),
      title: title,
      startDate: DateTime.now(),
      durationDays: days,
      lastReadPage: startPage > 1 ? startPage - 1 : 0,
      readPages: [],
    );
    khatmat.add(newKhatmah);
    _saveToHive();
  }

  void updateProgress(String id, int page) {
    final index = khatmat.indexWhere((element) => element.id == id);
    if (index != -1) {
      if (!khatmat[index].readPages.contains(page)) {
        khatmat[index].readPages.add(page);
        khatmat[index].lastReadPage = page;
        khatmat.refresh();
        _saveToHive();
      }
    }
  }

  void finishTodayPortion(String id) {
    final index = khatmat.indexWhere((element) => element.id == id);
    if (index != -1) {
      final khatmah = khatmat[index];
      int pagesToAdd = khatmah.pagesPerDay;
      int startPage = (khatmah.lastReadPage > 0 ? khatmah.lastReadPage : 1);
      
      List<int> newlyRead = [];
      for (int i = 0; i < pagesToAdd; i++) {
        int currentPage = (startPage + i).clamp(1, 604);
        if (!khatmah.readPages.contains(currentPage)) {
          khatmah.readPages.add(currentPage);
          newlyRead.add(currentPage);
        }
      }
      
      // حفظ آخر مجموعة تمت إضافتها للتراجع عنها
      _lastAddedPages[id] = newlyRead;
      _lastPageBeforeFinish[id] = khatmah.lastReadPage;

      khatmah.lastReadPage = (startPage + pagesToAdd - 1).clamp(1, 604);
      khatmat.refresh();
      _saveToHive();
    }
  }

  final Map<String, List<int>> _lastAddedPages = {};
  final Map<String, int> _lastPageBeforeFinish = {};

  void undoLastPortion(String id) {
    final index = khatmat.indexWhere((element) => element.id == id);
    if (index != -1 && _lastAddedPages.containsKey(id)) {
      final khatmah = khatmat[index];
      for (var page in _lastAddedPages[id]!) {
        khatmah.readPages.remove(page);
      }
      khatmah.lastReadPage = _lastPageBeforeFinish[id] ?? 0;
      
      _lastAddedPages.remove(id);
      _lastPageBeforeFinish.remove(id);

      khatmat.refresh();
      _saveToHive();
    }
  }

  void deleteKhatmah(String id) {
    khatmat.removeWhere((element) => element.id == id);
    _saveToHive();
  }

  void _saveToHive() {
    _khatmahBox.put('khatmat_list', khatmat.map((e) => e.toMap()).toList());
  }

  void completeKhatmah(String id) {
    final index = khatmat.indexWhere((element) => element.id == id);
    if (index != -1) {
      deleteKhatmah(id);
      final box = Hive.box('settings');
      int totalCompleted = box.get('total_completed_khatmat', defaultValue: 0);
      box.put('total_completed_khatmat', totalCompleted + 1);
    }
  }
}
