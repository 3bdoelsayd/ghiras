import 'package:get/get.dart';

class QuranApiService extends GetConnect {
  static QuranApiService get to => Get.find();

  Future<List<String>> getPageGlyphs(int pageNumber) async {
    try {
      // Using Quran.com API v4 to get v2 codes for the specific page
      // This is a common way to get the characters that match the QCF_Pxxx fonts
      final response = await get(
        'https://api.quran.com/api/v4/quran/verses/code_v2',
        query: {
          'page_number': pageNumber.toString(),
        },
      );

      if (response.status.hasError) {
        return [];
      }

      final List verses = response.body['verses'];
      return verses.map((v) => v['code_v2'] as String).toList();
    } catch (e) {
      print('Error fetching glyphs: $e');
      return [];
    }
  }
}
