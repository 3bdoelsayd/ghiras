import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/bookmark_bloc.dart';
import '../utils/quran_helpers.dart';

class ReadingProgressView extends StatelessWidget {
  const ReadingProgressView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقدم القراءة'),
        centerTitle: true,
      ),
      body: BlocBuilder<BookmarkBloc, BookmarkState>(
        builder: (context, state) {
          if (state is BookmarkLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProgressLoaded) {
            final progress = state.progress;
            if (progress == null) {
              return Center(
                child: Text(
                  'لم تبدأ القراءة بعد',
                  style: TextStyle(fontSize: 16.sp),
                ),
              );
            }
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'آخر قراءة',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            _buildProgressRow(
                              'السورة:',
                              'السورة ${progress.lastReadSurah}',
                            ),
                            _buildProgressRow(
                              'الآية:',
                              'الآية ${progress.lastReadAyah}',
                            ),
                            _buildProgressRow(
                              'الصفحة:',
                              'الصفحة ${progress.lastReadPage}',
                            ),
                            _buildProgressRow(
                              'الجزء:',
                              'الجزء ${progress.currentJuz}',
                            ),
                            _buildProgressRow(
                              'الوقت:',
                              QuranHelpers.formatReadingDate(
                                progress.lastReadTime,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الإحصائيات',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            _buildProgressRow(
                              'إجمالي الصفحات المقروءة:',
                              '${progress.totalPagesRead} صفحة',
                            ),
                            _buildProgressRow(
                              'نسبة الإنجاز:',
                              '${((progress.totalPagesRead / 604) * 100).toStringAsFixed(1)}%',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    LinearProgressIndicator(
                      value: progress.totalPagesRead / 604,
                      minHeight: 8.h,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1A5B3D),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is BookmarkError) {
            return Center(child: Text('خطأ: ${state.message}'));
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildProgressRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
