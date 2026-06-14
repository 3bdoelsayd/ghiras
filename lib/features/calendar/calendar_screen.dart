import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../core/constants/app_colors.dart';
import 'package:intl/intl.dart' as intl;

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late HijriCalendar _today;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _today = HijriCalendar.now();
    _selectedYear = _today.hYear;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'التقويم الإسلامي',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _buildYearPicker(),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 12,
        itemBuilder: (context, index) {
          return _buildMonthCard(_selectedYear, index + 1);
        },
      ),
    );
  }

  Widget _buildYearPicker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedYear,
          items: List.generate(20, (i) => 1440 + i).map((y) {
            return DropdownMenuItem(
              value: y,
              child: Text(_toArabicNumbers(y.toString()), style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedYear = v);
          },
        ),
      ),
    );
  }

  Widget _buildMonthCard(int year, int month) {
    final hijri = HijriCalendar();
    hijri.hYear = year;
    hijri.hMonth = month;
    hijri.hDay = 1;

    final firstDayGregorian = hijri.hijriToGregorian(year, month, 1);
    // في إصدار hijri 3.0.0+ يتم استخدام getDaysInMonth
    final daysInMonth = hijri.getDaysInMonth(year, month);
    final startWeekday = firstDayGregorian.weekday; // Mon=1, Sun=7
    final offset = (startWeekday + 1) % 7; // Adjust for Saturday as first day (Index 0)

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getArabicHijriMonth(month),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
                Text(
                  intl.DateFormat('MMMM yyyy', 'ar').format(firstDayGregorian),
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textGrey.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildWeekHeader(),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: daysInMonth + offset,
                  itemBuilder: (context, index) {
                    if (index < offset) return const SizedBox.shrink();
                    final day = index - offset + 1;
                    final gDate = hijri.hijriToGregorian(year, month, day);
                    final isToday = _isToday(year, month, day);

                    return Container(
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isToday ? AppColors.primary : Colors.grey.shade100),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _toArabicNumbers(day.toString()),
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              color: isToday ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          Text(
                            _toArabicNumbers(gDate.day.toString()),
                            style: TextStyle(
                              fontSize: 8,
                              fontFamily: 'Cairo',
                              height: 1.0,
                              color: isToday ? Colors.white.withValues(alpha: 0.8) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    const days = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((d) => Expanded(
        child: Center(
          child: Text(d, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
      )).toList(),
    );
  }

  bool _isToday(int y, int m, int d) {
    return _today.hYear == y && _today.hMonth == m && _today.hDay == d;
  }

  String _toArabicNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
  }

  String _getArabicHijriMonth(int month) {
    const months = ['محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'];
    return months[month - 1];
  }
}
