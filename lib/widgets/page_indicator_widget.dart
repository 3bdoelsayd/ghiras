import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PageIndicatorWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPageUp;
  final VoidCallback onPageDown;

  const PageIndicatorWidget({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageUp,
    required this.onPageDown,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: currentPage > 1 ? onPageUp : null,
            iconSize: 20.sp,
          ),
          Text(
            '$currentPage / $totalPages',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: currentPage < totalPages ? onPageDown : null,
            iconSize: 20.sp,
          ),
        ],
      ),
    );
  }
}
