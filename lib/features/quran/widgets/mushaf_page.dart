import 'package:flutter/material.dart';

class MushafPage extends StatelessWidget {
  final int pageNumber;
  final bool isDarkMode;
  
  const MushafPage({
    super.key, 
    required this.pageNumber, 
    required this.isDarkMode
  });

  @override
  Widget build(BuildContext context) {
    // Format page number to be 3 digits (e.g., 001, 002, 010, 100)
    final String formattedPage = pageNumber.toString().padLeft(3, '0');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Center(
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: ColorFiltered(
            colorFilter: isDarkMode 
                ? const ColorFilter.matrix([
                    -1.0, 0.0, 0.0, 0.0, 255.0, // R
                    0.0, -1.0, 0.0, 0.0, 255.0, // G
                    0.0, 0.0, -1.0, 0.0, 255.0, // B
                    0.0, 0.0, 0.0, 1.0, 0.0,    // A
                  ])
                : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
            child: Image.asset(
              'assets/quran_pages/page_$formattedPage.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_not_supported_rounded, size: 50, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text('صفحة $pageNumber غير موجودة', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
