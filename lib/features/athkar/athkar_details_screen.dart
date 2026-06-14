import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'data/athkar_model.dart';

class AthkarDetailsScreen extends StatefulWidget {
  final AthkarCategory category;
  const AthkarDetailsScreen({super.key, required this.category});

  @override
  State<AthkarDetailsScreen> createState() => _AthkarDetailsScreenState();
}

class _AthkarDetailsScreenState extends State<AthkarDetailsScreen> {
  late List<int> _currentCounts;
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentCounts = widget.category.array.map((e) => e.count).toList();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _decrementCount(int index) {
    if (_currentCounts[index] > 0) {
      setState(() {
        _currentCounts[index]--;
      });

      if (_currentCounts[index] == 0) {
        if (_currentIndex < widget.category.array.length - 1) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              widget.category.category,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 16),
            ),
            Text(
              '${_currentIndex + 1} من ${widget.category.array.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Cairo'),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.category.array.length,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
            minHeight: 3,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemCount: widget.category.array.length,
              itemBuilder: (context, index) {
                final item = widget.category.array[index];
                final currentCount = _currentCounts[index];
                final isDone = currentCount == 0;
                final totalCount = item.count == 0 ? 1 : item.count;

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // كارت النص
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(35),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                            child: Text(
                              item.text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                height: 1.6,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'UthmanicHafs13',
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // العداد الدائري الكبير
                          GestureDetector(
                            onTap: () => _decrementCount(index),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 130,
                                  height: 130,
                                  child: CircularProgressIndicator(
                                    value: currentCount / totalCount,
                                    strokeWidth: 10,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(isDone ? Colors.green : AppColors.primary),
                                  ),
                                ),
                                Container(
                                  width: 105,
                                  height: 105,
                                  decoration: BoxDecoration(
                                    color: isDone ? Colors.green : AppColors.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isDone ? Colors.green : AppColors.primary).withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      )
                                    ],
                                  ),
                                  child: Center(
                                    child: isDone
                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 50)
                                        : Text(
                                            '$currentCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 36,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            isDone ? 'تم بحمد الله' : 'اضغط على الدائرة للعدّ',
                            style: TextStyle(
                              color: isDone ? Colors.green : AppColors.textGrey.withValues(alpha: 0.6),
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // إرشاد بسيط للتنقل
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swipe_left_rounded, color: AppColors.textGrey.withValues(alpha: 0.3), size: 20),
                const SizedBox(width: 8),
                Text('اسحب للتنقل بين الأذكار', style: TextStyle(color: AppColors.textGrey.withValues(alpha: 0.3), fontSize: 12, fontFamily: 'Cairo')),
                const SizedBox(width: 8),
                Icon(Icons.swipe_right_rounded, color: AppColors.textGrey.withValues(alpha: 0.3), size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
