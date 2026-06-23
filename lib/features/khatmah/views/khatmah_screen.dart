import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../logic/khatmah_controller.dart';
import '../../quran/mushaf_reader.dart';
import '../data/khatmah_model.dart';

class KhatmahScreen extends StatelessWidget {
  const KhatmahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(KhatmahController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الختمة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Obx(() => controller.khatmat.isEmpty
          ? _buildEmptyState(context, controller)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildKhatmahCard(context, controller.khatmat.first, controller),
            )),
      floatingActionButton: Obx(() => controller.khatmat.isEmpty 
        ? FloatingActionButton.extended(
            onPressed: () => _showAddKhatmahDialog(context, controller),
            label: const Text('بدء ختمة جديدة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
            backgroundColor: AppColors.primary,
            elevation: 2,
          )
        : const SizedBox.shrink()),
    );
  }

  Widget _buildEmptyState(BuildContext context, KhatmahController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(35),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.04), shape: BoxShape.circle),
            child: Icon(Icons.menu_book_rounded, size: 70, color: AppColors.primary.withOpacity(0.2)),
          ),
          const SizedBox(height: 25),
          const Text('ابدأ رحلة جديدة مع القرآن', style: TextStyle(fontFamily: 'Cairo', fontSize: 18, color: AppColors.textDark, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('لا توجد ختمات جارية حالياً', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: AppColors.textGrey)),
          const SizedBox(height: 35),
          ElevatedButton.icon(
            onPressed: () => _showAddKhatmahDialog(context, controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, 
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('إضافة ختمة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildKhatmahCard(BuildContext context, KhatmahModel khatmah, KhatmahController controller) {
    int startPage = (khatmah.lastReadPage > 0 ? khatmah.lastReadPage + 1 : 1);
    int targetPage = khatmah.targetPageForToday;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 24, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        khatmah.title,
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 4),
                      _buildLaggingStatus(khatmah),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red.withOpacity(0.4), size: 22),
                  onPressed: () => _showDeleteConfirm(context, controller, khatmah),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                // Info Row
                Row(
                  children: [
                    Expanded(child: _buildDetailedInfo(Icons.calendar_today_rounded, 'المتبقي', '${khatmah.remainingDays} يوم')),
                    Container(width: 1, height: 25, color: Colors.grey[50]),
                    Expanded(child: _buildDetailedInfo(Icons.menu_book_rounded, 'الورد اليومي', '${khatmah.pagesPerDay} ص/يوم')),
                  ],
                ),
                const SizedBox(height: 25),
                
                // Next Portion Card (وردك القادم)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2), // Softer beige
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE8E1D5), width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'وردك القادم بإذن الله', 
                        style: TextStyle(
                          fontFamily: 'Cairo', 
                          fontSize: 13, 
                          color: AppColors.primary.withOpacity(0.6), 
                          fontWeight: FontWeight.bold
                        )
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _pageIndicator('من صفحة', startPage.toString()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary.withOpacity(0.3)),
                          ),
                          _pageIndicator('إلى صفحة', targetPage.toString()),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),
                
                // Progress Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('تقدمك في الختمة', style: TextStyle(fontFamily: 'Cairo', color: AppColors.textGrey, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('%${(khatmah.progress * 100).toInt()}', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 10),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                    ),
                    FractionallySizedBox(
                      widthFactor: khatmah.progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF3B8E74)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MushafReader(
                            initialPage: startPage,
                            khatmahId: khatmah.id,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text('متابعة القراءة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () {
                      controller.finishTodayPortion(khatmah.id);
                      if (khatmah.progress >= 1.0) {
                        controller.completeKhatmah(khatmah.id);
                        _showKhatmahDuaDialog(context, isFinal: true);
                      } else {
                        _showFinishSnackBar(context, controller, khatmah);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('أتممت الورد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageIndicator(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textGrey)),
        Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildDetailedInfo(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary.withOpacity(0.4), size: 18),
        const SizedBox(height: 6),
        Text(title, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey[500])),
        Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildLaggingStatus(KhatmahModel khatmah) {
    if (!khatmah.isLagging) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 12, color: Colors.green),
          const SizedBox(width: 4),
          Text('ملتزم بالجدول', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.green.withOpacity(0.8), fontWeight: FontWeight.bold)),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
      child: Text('متأخر ${khatmah.daysBehind} يوم', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),
    );
  }

  void _showFinishSnackBar(BuildContext context, KhatmahController controller, KhatmahModel khatmah) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم تسجيل الورد اليومي بنجاح', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'تراجع', textColor: Colors.amber, onPressed: () => controller.undoLastPortion(khatmah.id)),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, KhatmahController controller, KhatmahModel khatmah) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('حذف الختمة', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من حذف هذه الختمة؟ لا يمكن التراجع عن هذا الفعل.', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(onPressed: () { controller.deleteKhatmah(khatmah.id); Navigator.pop(context); }, child: const Text('حذف', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  void _showKhatmahDuaDialog(BuildContext context, {bool isFinal = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
        backgroundColor: Colors.white,
        title: const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            'دعاء ختم القرآن',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.primary),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppColors.primary.withOpacity(0.05)),
                ),
                child: const Text(
                  'اللَّهُمَّ ارْحَمْنِي بالقُرْءَانِ وَاجْعَلهُ لِي إِمَاماً وَنُوراً وَهُدًى وَرَحْمَةً * اللَّهُمَّ ذَكِّرْنِي مِنْهُ مَانَسِيتُ وَعَلِّمْنِي مِنْهُ مَاجَهِلْتُ وَارْزُقْنِي تِلاَوَتَهُ آنَاءَ اللَّيْلِ وَأَطْرَافَ النَّهَارِ وَاجْعَلْهُ لِي حُجَّةً يَارَبَّ العَالَمِينَ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 22, height: 1.8, color: AppColors.textDark, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (isFinal) Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 5),
                child: const Text('تقبل الله منّا ومنكم', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddKhatmahDialog(BuildContext context, KhatmahController controller) {
    final daysController = TextEditingController(text: '30');
    int selectedJuz = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.vertical(top: Radius.circular(32))
          ),
          padding: EdgeInsets.fromLTRB(25, 12, 25, MediaQuery.of(context).viewInsets.bottom + 30),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 45, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    'بدء رحلة ختم جديدة', 
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 19, color: AppColors.textDark)
                  )
                ),
                const SizedBox(height: 30),
                const Text('المدة الزمنية (بالأيام)', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                const SizedBox(height: 10),
                TextField(
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'مثلاً: 30 يوم',
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                  ),
                ),
                const SizedBox(height: 25),
                const Text('ابدأ من الجزء:', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(18)),
                  child: DropdownButton<int>(
                    value: selectedJuz,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    items: List.generate(30, (i) => i + 1).map((juz) => DropdownMenuItem(value: juz, child: Text('الجزء $juz', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (val) => setModalState(() => selectedJuz = val!),
                  ),
                ),
                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      final List<int> juzPages = [1, 22, 42, 62, 82, 102, 121, 142, 162, 182, 201, 221, 242, 262, 282, 302, 322, 342, 362, 382, 402, 422, 442, 462, 482, 502, 522, 542, 562, 582];
                      controller.addKhatmah("ختمة جديدة", int.tryParse(daysController.text) ?? 30, startPage: juzPages[selectedJuz - 1]);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
                      elevation: 0,
                    ),
                    child: const Text('ابدأ الختمة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
