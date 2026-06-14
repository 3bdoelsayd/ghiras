import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/bookmark_model.dart';
import '../services/bookmark_bloc.dart';

class BookmarksView extends StatelessWidget {
  const BookmarksView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشارات المرجعية'),
        centerTitle: true,
      ),
      body: BlocBuilder<BookmarkBloc, BookmarkState>(
        builder: (context, state) {
          if (state is BookmarkLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BookmarksLoaded) {
            if (state.bookmarks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_outline,
                      size: 64.sp,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'لا توجد إشارات مرجعية',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }
            return Directionality(
              textDirection: TextDirection.rtl,
              child: ListView.builder(
                padding: EdgeInsets.all(12.w),
                itemCount: state.bookmarks.length,
                itemBuilder: (context, index) {
                  final bookmark = state.bookmarks[index];
                  return _buildBookmarkCard(context, bookmark);
                },
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

  Widget _buildBookmarkCard(
    BuildContext context,
    Bookmark bookmark,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'السورة ${bookmark.surahNumber}:${bookmark.ayahNumber}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    context
                        .read<BookmarkBloc>()
                        .add(DeleteBookmarkEvent(bookmark.id));
                  },
                ),
              ],
            ),
            if (bookmark.notes != null && bookmark.notes!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  bookmark.notes!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            SizedBox(height: 8.h),
            Text(
              'الصفحة: ${bookmark.pageNumber}',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
