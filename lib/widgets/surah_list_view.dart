import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/quran_models.dart';
import '../services/quran_bloc.dart';
import 'surah_detail_view.dart';

class SurahListView extends StatelessWidget {
  const SurahListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranBloc, QuranState>(
      builder: (context, state) {
        if (state is SurahsLoaded) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: ListView.builder(
              itemCount: state.surahs.length,
              itemBuilder: (context, index) {
                final surah = state.surahs[index];
                return _buildSurahTile(context, surah);
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
    );
  }

  Widget _buildSurahTile(BuildContext context, Surah surah) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1A5B3D),
          child: Text(
            surah.number.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          surah.nameArabic,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${surah.nameEnglish} • ${surah.numberOfAyahs} آية',
          style: TextStyle(fontSize: 12.sp),
        ),
        trailing: Text(
          surah.revelationType,
          style: TextStyle(
            fontSize: 11.sp,
            color: surah.revelationType == 'Meccan' ? Colors.orange : Colors.blue,
          ),
        ),
        onTap: () {
          context.read<QuranBloc>().add(LoadSurahEvent(surah.number));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurahDetailView(surah: surah),
            ),
          );
        },
      ),
    );
  }
}
