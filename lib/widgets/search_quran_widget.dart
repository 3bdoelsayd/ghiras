import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/quran_models.dart';
import '../services/quran_bloc.dart';

class SearchQuranWidget extends StatefulWidget {
  const SearchQuranWidget({Key? key}) : super(key: key);

  @override
  State<SearchQuranWidget> createState() => _SearchQuranWidgetState();
}

class _SearchQuranWidgetState extends State<SearchQuranWidget> {
  late TextEditingController _searchController;
  List<Ayah> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(12.w),
          child: TextField(
            controller: _searchController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'ابحث في القرآن',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onChanged: (query) {
              if (query.isNotEmpty) {
                setState(() => _isSearching = true);
                context.read<QuranBloc>().add(SearchQuranEvent(query));
              } else {
                setState(() {
                  _isSearching = false;
                  _searchResults = [];
                });
              }
            },
          ),
        ),
        if (_isSearching)
          Expanded(
            child: BlocBuilder<QuranBloc, QuranState>(
              builder: (context, state) {
                if (state is QuranLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is QuranLoaded) {
                  _searchResults = state.ayahs;
                  if (_searchResults.isEmpty) {
                    return const Center(child: Text('لا توجد نتائج'));
                  }
                  return Directionality(
                    textDirection: TextDirection.rtl,
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final ayah = _searchResults[index];
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12.w),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  ayah.text,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'UthmanicHafs13',
                                    fontSize: 18.sp,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'السورة: ${ayah.surahNumber} - الآية: ${ayah.number}',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                } else if (state is QuranError) {
                  return Center(child: Text('خطأ: ${state.message}'));
                }
                return const SizedBox();
              },
            ),
          ),
      ],
    );
  }
}
