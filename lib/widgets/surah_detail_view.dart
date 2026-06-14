import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/quran_models.dart';
import '../services/quran_bloc.dart';

class SurahDetailView extends StatelessWidget {
  final Surah surah;

  const SurahDetailView({Key? key, required this.surah}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(surah.nameArabic),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A5B3D),
      ),
      body: BlocBuilder<QuranBloc, QuranState>(
        builder: (context, state) {
          if (state is QuranLoaded) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: ListView.builder(
                padding: EdgeInsets.all(12.w),
                itemCount: state.ayahs.length,
                itemBuilder: (context, index) {
                  final ayah = state.ayahs[index];
                  return _buildAyahCard(context, ayah, index);
                },
              ),
            );
          } else if (state is QuranLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is QuranError) {
            return Center(child: Text('خطأ: ${state.message}'));
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildAyahCard(BuildContext context, Ayah ayah, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ayah number and metadata
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الآية ${ayah.number}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'الصفحة ${ayah.page}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            // Ayah text
            Text(
              ayah.text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'UthmanicHafs13',
                fontSize: 20.sp,
                height: 1.8,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(height: 8.h),
            // Ayah number symbol
            Text(
              ' ﴿${ayah.number}﴾ ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'UthmanicHafs13',
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
