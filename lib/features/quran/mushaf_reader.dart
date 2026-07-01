import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import 'data/page_surah_map.dart';
import 'widgets/quran_page_widget.dart';
import 'logic/mushaf_controller.dart';
import 'logic/quran_audio_controller.dart';
import '../khatmah/logic/khatmah_controller.dart';

class MushafReader extends StatefulWidget {
  final int initialPage;
  final String? khatmahId;
  const MushafReader({super.key, this.initialPage = 1, this.khatmahId});

  @override
  State<MushafReader> createState() => _MushafReaderState();
}

class _MushafReaderState extends State<MushafReader> {
  late PageController _pageController;
  late int _currentPage;
  late Box _settingsBox;
  bool _wirdDialogShown = false;
  bool _wirdCompleted = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _settingsBox = Hive.box('settings');

    _pageController = PageController(initialPage: _currentPage - 1);
    
    // ... rest of initState

    // ✅ Listener يمنع التقليب بعد إتمام الورد
    _pageController.addListener(() {
      if (_wirdCompleted) {
        final target = _todayTargetPage;
        if (target != null && _pageController.page != null) {
          final maxPage = (target - 1).toDouble();
          if (_pageController.page! > maxPage) {
            _pageController.jumpToPage(target - 1);
          }
        }
      }
    });

    if (!Get.isRegistered<MushafController>()) {
      Get.put(MushafController(), permanent: true);
    }
    if (!Get.isRegistered<QuranAudioController>()) {
      Get.put(QuranAudioController(), permanent: true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<MushafController>().currentPage.value = _currentPage;
    });
  }

  @override
  void dispose() {
    if (Get.isRegistered<QuranAudioController>()) {
      Get.find<QuranAudioController>().stop();
    }
    _pageController.dispose();
    super.dispose();
  }

  int? get _todayTargetPage {
    if (widget.khatmahId == null) return null;
    if (!Get.isRegistered<KhatmahController>()) return null;
    final kController = Get.find<KhatmahController>();
    final idx = kController.khatmat.indexWhere((k) => k.id == widget.khatmahId);
    if (idx == -1) return null;
    return kController.khatmat[idx].targetPageForToday;
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    setState(() => _currentPage = index + 1);
    _settingsBox.put('last_quran_page', _currentPage);
    _trackDailyWird(_currentPage);

    if (widget.khatmahId != null && Get.isRegistered<KhatmahController>()) {
      Get.find<KhatmahController>()
          .updateProgress(widget.khatmahId!, _currentPage);
    }

    Get.find<MushafController>().onPageChanged(index);

    // ✅ لما يوصل للهدف
    final target = _todayTargetPage;
    if (target != null && _currentPage >= target && !_wirdDialogShown) {
      _wirdDialogShown = true;
      setState(() => _wirdCompleted = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          if (_currentPage >= 604) {
            _showKhatmahDuaDialog();
          } else {
            _showFinishedWirdDialog();
          }
        }
      });
    }
  }

  void _trackDailyWird(int page) {
    final todayKey =
        'wird_pages_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    List<int> pagesRead =
    List<int>.from(_settingsBox.get(todayKey, defaultValue: []));
    if (!pagesRead.contains(page)) {
      pagesRead.add(page);
      _settingsBox.put(todayKey, pagesRead);
    }
  }

  void _showFinishedWirdDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFBF9F3),
        title: const Text(
          'تم بحمد الله',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'لقد أتممت ورد اليوم بنجاح\nتقبل الله طاعتك',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 15,
            height: 1.8,
            color: Colors.black87,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              if (Get.isRegistered<KhatmahController>()) {
                Get.find<KhatmahController>().finishTodayPortion(widget.khatmahId!);
              }
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close reader
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text(
              'العودة للرئيسية',
              style: TextStyle(
                fontFamily: 'cairo',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFasilDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة فاصل',
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Cairo')),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
              hintText: 'اسم الفاصل (مثلاً: ورد اليوم)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Get.find<MushafController>()
                    .addFasil(_currentPage, controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت إضافة الفاصل')));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  bool _shouldShowFinishButton() {
    if (widget.khatmahId == null) return false;
    if (!Get.isRegistered<KhatmahController>()) return false;
    final controller = Get.find<KhatmahController>();
    final index =
    controller.khatmat.indexWhere((k) => k.id == widget.khatmahId);
    if (index == -1) return false;
    final khatmah = controller.khatmat[index];
    return _currentPage >= khatmah.targetPageForToday;
  }

  void _showKhatmahDuaDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: const Text(
          'دعاء ختم القرآن',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AppColors.primary),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'اللَّهُمَّ ارْحَمْنِي بالقُرْءَانِ وَاجْعَلهُ لِي إِمَاماً وَنُوراً وَهُدًى وَرَحْمَةً * اللَّهُمَّ ذَكِّرْنِي مِنْهُ مَانَسِيتُ وَعَلِّمْنِي مِنْهُ مَاجَهِلْتُ وَارْزُقْنِي تِلاَوَتَهُ آنَاءَ اللَّيْلِ وَأَطْرَافَ النَّهَارِ وَاجْعَلْهُ لِي حُجَّةً يَارَبَّ العَالَمِينَ',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'AmiriQuran', fontSize: 18, height: 1.6),
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                if (widget.khatmahId != null && Get.isRegistered<KhatmahController>()) {
                  Get.find<KhatmahController>().completeKhatmah(widget.khatmahId!);
                }
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
              child: const Text('تقبل الله منّا ومنكم',
                  style:
                  TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = PageSurahMap.getPageInfo(_currentPage);
    final isDark = Get.find<MushafController>().isDarkMode.value;
    final target = _todayTargetPage;

    double wirdProgress = 0.0;
    int startPage = widget.initialPage;

    if (target != null) {
      int totalToRead = target - startPage;
      if (totalToRead > 0) {
        wirdProgress =
            ((_currentPage - startPage) / totalToRead).clamp(0.0, 1.0);
      } else if (_currentPage >= target) {
        wirdProgress = 1.0;
      }
    }

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFBF9F3),
      appBar: AppBar(
        backgroundColor:
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFBF9F3),
        elevation: 0,
        toolbarHeight: 45, // تقليل ارتفاع التولبار لتوفير مساحة
        centerTitle: true,
        iconTheme:
        IconThemeData(color: isDark ? Colors.white : AppColors.textDark, size: 20),
        actions: [
          Obx(() {
            final controller = Get.find<MushafController>();
            final bool isSaved = controller.hasFasil(_currentPage);
            
            return IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                color: isSaved 
                    ? Colors.green 
                    : (isDark ? Colors.white : AppColors.textDark),
              ),
              onPressed: () {
                final info = PageSurahMap.getPageInfo(_currentPage);
                final surahName = info?['surah'] ?? 'صفحة';
                
                if (isSaved) {
                  controller.removeFasilByPage(_currentPage);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إزالة الفاصل', textAlign: TextAlign.center),
                      backgroundColor: Colors.redAccent,
                      duration: Duration(seconds: 1),
                    ),
                  );
                } else {
                  controller.addFasil(_currentPage, 'سورة $surahName (ص $_currentPage)');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم حفظ الفاصل بنجاح', textAlign: TextAlign.center),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            );
          }),
        ],
        title: Column(
          children: [
            Text(
              info?['surah'] ?? '',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              'الجزء ${info?['juz']} • صفحة $_currentPage',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey[600],
                fontSize: 10,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: 604,
            reverse: false,
            physics: const CustomPageViewScrollPhysics(),
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return QuranPageWidget(
                  key: ValueKey(index), pageNumber: index + 1);
            },
          ),
          if (widget.khatmahId != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                color: Colors.black12,
                child: FractionallySizedBox(
                  alignment: Alignment.centerRight,
                  widthFactor: wirdProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 4)
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _shouldShowFinishButton()
          ? Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          onPressed: () {
            if (Get.isRegistered<QuranAudioController>()) {
              Get.find<QuranAudioController>().stop();
            }
            if (widget.khatmahId != null &&
                Get.isRegistered<KhatmahController>()) {
              final kController = Get.find<KhatmahController>();
              final index = kController.khatmat
                  .indexWhere((k) => k.id == widget.khatmahId);
              if (index != -1) {
                if (_currentPage >= 604) {
                  kController.completeKhatmah(widget.khatmahId!);
                  _showKhatmahDuaDialog();
                  return;
                } else {
                  kController.finishTodayPortion(widget.khatmahId!);
                }
              }
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تقبل الله طاعتك، تم حفظ تقدمك',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Cairo')),
                backgroundColor: AppColors.primary,
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.pop(context);
          },
          label: const Text('أتممت الورد',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          icon: const Icon(Icons.check_circle_outline_rounded,
              color: Colors.white),
          backgroundColor: AppColors.primary.withOpacity(0.9),
          elevation: 4,
        ),
      )
          : null,
    );
  }
}

class CustomPageViewScrollPhysics extends ScrollPhysics {
  const CustomPageViewScrollPhysics({super.parent});

  @override
  CustomPageViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageViewScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get dragStartDistanceMotionThreshold => 3.5;
}