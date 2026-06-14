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
      backgroundColor: const Color(0xFFF9F9F7),
      appBar: AppBar(
        title: const Text(' الختمه', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Obx(() => controller.khatmat.isEmpty
          ? _buildEmptyState(context, controller)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: _buildKhatmahCard(context, controller.khatmat.first, controller),
            )),
      floatingActionButton: Obx(() => controller.khatmat.isEmpty 
        ? FloatingActionButton.extended(
            onPressed: () => _showAddKhatmahDialog(context, controller),
            label: const Text('بدء ختمة جديدة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
            backgroundColor: AppColors.primary,
            elevation: 4,
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
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.menu_book_rounded, size: 80, color: AppColors.primary.withOpacity(0.3)),
          ),
          const SizedBox(height: 25),
          const Text('لا توجد ختمات جارية حالياً', style: TextStyle(fontFamily: 'Cairo', fontSize: 18, color: AppColors.textDark, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _showAddKhatmahDialog(context, controller),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        khatmah.title,
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textDark),
                      ),
                      _buildLaggingStatus(khatmah),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
                  onPressed: () => _showDeleteConfirm(context, controller, khatmah),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDetailedInfo(Icons.calendar_today_rounded, 'المتبقي', '${khatmah.remainingDays} يوم')),
                    Container(width: 1, height: 30, color: Colors.grey[100]),
                    Expanded(child: _buildDetailedInfo(Icons.auto_stories_rounded, 'الورد اليومي', '${khatmah.pagesPerDay} ص/يوم')),
                  ],
                ),
                const SizedBox(height: 25),
                
                // الورد القادم بتصميم عصري
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFFFFF9F0), Colors.orange.withOpacity(0.05)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withOpacity(0.1), width: 1),
                  ),
                  child: Column(
                    children: [
                      const Text('وردك القادم بإذن الله', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.orange, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        'من صفحة $startPage إلى صفحة $targetPage',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('تقدمك في الختمة', style: TextStyle(fontFamily: 'Cairo', color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('%${(khatmah.progress * 100).toInt()}', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: khatmah.progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey[100],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MushafReader(
                            initialPage: khatmah.lastReadPage > 0 ? khatmah.lastReadPage : 1,
                            khatmahId: khatmah.id,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('متابعة القراءة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('أتممت الورد', style: TextStyle(fontFamily: 'Cairo', color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo(IconData icon, String title, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildLaggingStatus(KhatmahModel khatmah) {
    if (!khatmah.isLagging) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: const Text('مُلتزم ✅', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text('متأخر ${khatmah.daysBehind} يوم', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
          padding: EdgeInsets.fromLTRB(25, 20, 25, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 25),
                const Center(child: Text('بدء رحلة ختم جديدة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary))),
                const SizedBox(height: 20),
                const Text('المدة الزمنية (بالأيام)', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'عدد الأيام المتوقع للختم',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.timer_outlined, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('ابدأ من الجزء:', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(18)),
                  child: DropdownButton<int>(
                    value: selectedJuz,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    items: List.generate(30, (i) => i + 1).map((juz) => DropdownMenuItem(value: juz, child: Text('الجزء $juz', style: const TextStyle(fontFamily: 'Cairo')))).toList(),
                    onChanged: (val) => setModalState(() => selectedJuz = val!),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      final List<int> juzPages = [1, 22, 42, 62, 82, 102, 121, 142, 162, 182, 201, 221, 242, 262, 282, 302, 322, 342, 362, 382, 402, 422, 442, 462, 482, 502, 522, 542, 562, 582];
                      controller.addKhatmah("ختمة جديدة", int.tryParse(daysController.text) ?? 30, startPage: juzPages[selectedJuz - 1]);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 4, shadowColor: AppColors.primary.withOpacity(0.3)),
                    child: const Text('توكلت على الله .. ابدأ الختمة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
