import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/glass_container.dart';
import 'bloc/hadith_bloc.dart';

class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HadithBloc()..add(GetHadithBook(filename: 'bukhari.json')),
      child: const HadithView(),
    );
  }
}

class HadithView extends StatelessWidget {
  const HadithView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/hadithback.png'),
            fit: BoxFit.cover,
            opacity: 0.05,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'صحيح البخاري',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: BlocBuilder<HadithBloc, HadithState>(
            builder: (context, state) {
              if (state is HadithDownloading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 20),
                      Text(
                        'جاري التحميل: ${state.progress}',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 18),
                      ),
                    ],
                  ),
                );
              }

              if (state is HadithLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (state is HadithFetched) {
                final List items = state.hadithBook;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final hadith = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              hadith['hadithArabic'] ?? '',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'AmiriQuran',
                                fontSize: 18,
                                height: 1.5,
                              ),
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'رقم الحديث: ${hadith['hadithNumber']}',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    color: AppColors.textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                                const Icon(Icons.share_rounded, size: 20, color: AppColors.primary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }

              if (state is HadithInitial) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_download_rounded, size: 80, color: AppColors.primary),
                        const SizedBox(height: 24),
                        const Text(
                          'كتاب صحيح البخاري غير محمل حالياً',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<HadithBloc>().add(DownloadHadithBook(filename: 'bukhari.json'));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('تحميل الكتاب الآن', style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is HadithError) {
                return Center(
                  child: Text(state.message, style: const TextStyle(color: Colors.red)),
                );
              }

              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }
}
