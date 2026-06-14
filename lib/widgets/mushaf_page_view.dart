import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/quran_models.dart';
import '../services/quran_bloc.dart';

class MushafPageView extends StatefulWidget {
  final int initialPage;

  const MushafPageView({Key? key, this.initialPage = 1}) : super(key: key);

  @override
  State<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<MushafPageView> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: _currentPage - 1);
    context.read<QuranBloc>().add(LoadPageEvent(_currentPage));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        body: BlocBuilder<QuranBloc, QuranState>(
          builder: (context, state) {
            if (state is QuranLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is QuranLoaded) {
              return PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page + 1);
                  context.read<QuranBloc>().add(LoadPageEvent(_currentPage));
                },
                itemBuilder: (context, index) {
                  final pageNumber = index + 1;
                  return QuranPageDisplay(
                    pageNumber: pageNumber,
                    ayahs: state.ayahs,
                  );
                },
                itemCount: 604, // Total pages in Quran
              );
            } else if (state is QuranError) {
              return Center(
                child: Text('Error: ${state.message}'),
              );
            }
            return const SizedBox();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showPageNavigator(context),
          child: const Icon(Icons.bookmark),
        ),
      ),
    );
  }

  void _showPageNavigator(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PageNavigatorDialog(
        currentPage: _currentPage,
        onPageSelected: (page) {
          _pageController.jumpToPage(page - 1);
          context.read<QuranBloc>().add(LoadPageEvent(page));
          Navigator.pop(context);
        },
      ),
    );
  }
}

class QuranPageDisplay extends StatelessWidget {
  final int pageNumber;
  final List<Ayah> ayahs;

  const QuranPageDisplay({
    Key? key,
    required this.pageNumber,
    required this.ayahs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filter ayahs for this page
    final pageAyahs = ayahs.where((ayah) => ayah.page == pageNumber).toList();

    return Container(
      color: const Color(0xFFF5DEB3), // Mushaf paper color
      child: Column(
        children: [
          // Header with page info
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            child: Text(
              'الصفحة $pageNumber',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          Divider(height: 1.h, color: Colors.grey[400]),
          // Quran text content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < pageAyahs.length; i++)
                      QuranLineWidget(
                        ayah: pageAyahs[i],
                        isLastInPage: i == pageAyahs.length - 1,
                      ),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1.h, color: Colors.grey[400]),
          // Footer with page number
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              pageNumber.toString(),
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuranLineWidget extends StatelessWidget {
  final Ayah ayah;
  final bool isLastInPage;

  const QuranLineWidget({
    Key? key,
    required this.ayah,
    required this.isLastInPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Text(
              ayah.text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'UthmanicHafs13',
                fontSize: 20.sp,
                height: 1.8,
                color: const Color(0xFF1A1A1A),
                letterSpacing: 1.5,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 4.h, bottom: isLastInPage ? 0 : 8.h),
            child: Text(
              ' ﴿${ayah.number}﴾ ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'UthmanicHafs13',
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PageNavigatorDialog extends StatefulWidget {
  final int currentPage;
  final Function(int) onPageSelected;

  const PageNavigatorDialog({
    Key? key,
    required this.currentPage,
    required this.onPageSelected,
  }) : super(key: key);

  @override
  State<PageNavigatorDialog> createState() => _PageNavigatorDialogState();
}

class _PageNavigatorDialogState extends State<PageNavigatorDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentPage.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('انتقل إلى الصف��ة'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          hintText: 'رقم الصفحة (1-604)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () {
            final page = int.tryParse(_controller.text);
            if (page != null && page >= 1 && page <= 604) {
              widget.onPageSelected(page);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('رقم صفحة غير صحيح')),
              );
            }
          },
          child: const Text('انتقل'),
        ),
      ],
    );
  }
}
