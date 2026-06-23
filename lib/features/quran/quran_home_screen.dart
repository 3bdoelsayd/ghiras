import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:quran/quran.dart' as quran;
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_router.dart';
import 'logic/mushaf_controller.dart';

class QuranHomeScreen extends StatefulWidget {
  const QuranHomeScreen({super.key});

  @override
  State<QuranHomeScreen> createState() => _QuranHomeScreenState();
}

class _QuranHomeScreenState extends State<QuranHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late Box _settingsBox;
  int? _lastPage;

  static const List<int> _juzStartPages = [
    1, 22, 42, 62, 82, 102, 121, 142, 162, 182,
    201, 221, 242, 262, 282, 302, 322, 342, 362, 382,
    402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _settingsBox = Hive.box('settings');
    _lastPage = _settingsBox.get('last_quran_page');

    if (!Get.isRegistered<MushafController>()) {
      Get.put(MushafController(), permanent: true);
    }
  }

  void _navigateToPage(int page) {
    context.push('${AppRouter.mushaf}/$page');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: AppColors.primary,
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false,
              title: const Text(
                'القرآن الكريم',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  fontSize: 20,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/zikrback.png',
                      fit: BoxFit.cover,
                      opacity: const AlwaysStoppedAnimation(0.4),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withOpacity(0.3), AppColors.primary],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 16),
                tabs: const [
                  Tab(text: 'السور'),
                  Tab(text: 'الأجزاء'),
                ],
              ),
            ),
          ];
        },
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SurahTab(
                    searchQuery: _searchQuery,
                    lastPage: _lastPage,
                    onNavigate: _navigateToPage,
                    juzPages: _juzStartPages,
                    onRefresh: () {
                      setState(() {
                        _lastPage = _settingsBox.get('last_quran_page');
                      });
                    },
                  ),
                  _JuzTab(searchQuery: _searchQuery, onNavigate: _navigateToPage, juzPages: _juzStartPages),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'بحث عن سورة، جزء، حزب أو رقم صفحة...',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'cairo'),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }
}

class _SurahTab extends StatelessWidget {
  final String searchQuery;
  final int? lastPage;
  final Function(int) onNavigate;
  final List<int> juzPages;
  final VoidCallback onRefresh;

  const _SurahTab({required this.searchQuery, this.lastPage, required this.onNavigate, required this.juzPages, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final filteredSurahs = List.generate(114, (i) => i + 1).where((index) {
      final name = quran.getSurahNameArabic(index);
      return name.contains(searchQuery);
    }).toList();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: (lastPage != null && searchQuery.isEmpty ? 1 : 0) + 
                 (searchQuery.isNotEmpty && int.tryParse(searchQuery) != null ? 1 : 0) + 
                 filteredSurahs.length,
      itemBuilder: (context, index) {
        int currentIndex = 0;

        // 1. كارت آخر قراءة
        if (lastPage != null && searchQuery.isEmpty) {
          if (index == currentIndex) return _buildLastReadCard();
          currentIndex++;
        }

        // 2. نتيجة البحث عن رقم صفحة
        if (searchQuery.isNotEmpty && int.tryParse(searchQuery) != null) {
          if (index == currentIndex) return _buildPageSearchResult(int.parse(searchQuery));
          currentIndex++;
        }

        // 3. قائمة السور
        final surahIndex = index - currentIndex;
        final surahNumber = filteredSurahs[surahIndex];
        final nameArabic = quran.getSurahNameArabic(surahNumber);
        final nameEnglish = quran.getSurahName(surahNumber);
        final versesCount = quran.getVerseCount(surahNumber);
        final startPage = quran.getSurahPages(surahNumber)[0];

        return Column(
          children: [
            ListTile(
              onTap: () => onNavigate(startPage),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    surahNumber.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                  ),
                ),
              ),
              title: Text(
                nameArabic,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'cairo'),
              ),
              subtitle: Text(
                '$nameEnglish • $versesCount آية',
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
              trailing: Text(
                'ص $startPage',
                style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1, color: Colors.black12, indent: 70),
          ],
        );
      },
    );
  }

  Widget _buildLastReadCard() {
    final page = lastPage!;
    final surahNum = quran.getPageData(page)[0]['surah'];
    final surahName = quran.getSurahNameArabic(surahNum);

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF39C12).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF39C12).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, color: Color(0xFFF39C12), size: 30),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('متابعة القراءة', style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'cairo')),
                    Text('سورة $surahName', style: const TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'cairo')),
                  ],
                ),
                const Spacer(),
                Text('صفحة $page', style: const TextStyle(color: Color(0xFFF39C12), fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onNavigate(page),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF39C12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('متابعة الآن', style: TextStyle(color: Colors.white, fontFamily: 'cairo', fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final settingsBox = Hive.box('settings');
                      final todayKey = 'wird_pages_${intl.DateFormat('yyyy-MM-dd').format(DateTime.now())}';
                      List<int> pagesRead = List<int>.from(settingsBox.get(todayKey, defaultValue: []));

                      // إنهاء الورد اليومي (بإضافة 10 صفحات أو ما تبقى من الجزء)
                      int pagesToAdd = 10;
                      int startPage = page;

                      for (int i = 0; i < pagesToAdd; i++) {
                        int currentPage = startPage + i;
                        if (currentPage <= 604 && !pagesRead.contains(currentPage)) {
                          pagesRead.add(currentPage);
                        }
                      }

                      settingsBox.put(todayKey, pagesRead);

                      int nextLastPage = (page + pagesToAdd).clamp(1, 604);
                      settingsBox.put('last_quran_page', nextLastPage);

                      onRefresh(); // تحديث الواجهة في الأب

                      Get.snackbar('أحسنت!', 'تم إتمام وردك اليومي بنجاح',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        icon: const Icon(Icons.stars_rounded, color: Colors.white),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF39C12)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('تمت القراءة', style: TextStyle(color: Color(0xFFF39C12), fontFamily: 'cairo', fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageSearchResult(int page) {
    if (page < 1 || page > 604) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ListTile(
        onTap: () => onNavigate(page),
        tileColor: AppColors.primary.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: const Icon(Icons.find_in_page_rounded, color: AppColors.primary),
        title: Text('الانتقال إلى صفحة $page', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'cairo')),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ),
    );
  }
}

class _JuzTab extends StatelessWidget {
  final String searchQuery;
  final Function(int) onNavigate;
  final List<int> juzPages;
  const _JuzTab({required this.searchQuery, required this.onNavigate, required this.juzPages});

  @override
  Widget build(BuildContext context) {
    final filteredJuz = List.generate(30, (i) => i + 1).where((index) {
      if (searchQuery.isEmpty) return true;
      final queryNum = int.tryParse(searchQuery);
      if (queryNum != null) return index == queryNum;
      return 'الجزء $index'.contains(searchQuery) || index.toString().contains(searchQuery);
    }).toList();

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: filteredJuz.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12, indent: 70),
      itemBuilder: (context, index) {
        final juzNumber = filteredJuz[index];
        final startPage = juzPages[juzNumber - 1];
        final firstSurahNum = quran.getSurahAndVersesFromJuz(juzNumber).keys.first;
        final firstSurah = quran.getSurahNameArabic(firstSurahNum);

        return ListTile(
          onTap: () => onNavigate(startPage),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          leading: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                juzNumber.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ),
          title: Text(
            'الجزء $juzNumber',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'cairo'),
          ),
          subtitle: Text(
            'يبدأ من سورة $firstSurah',
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontFamily: 'cairo'),
          ),
          trailing: Text(
            'ص $startPage',
            style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}

class _HizbTab extends StatelessWidget {
  final String searchQuery;
  final Function(int) onNavigate;
  final List<int> juzPages;
  const _HizbTab({required this.searchQuery, required this.onNavigate, required this.juzPages});

  @override
  Widget build(BuildContext context) {
    final filteredHizb = List.generate(60, (i) => i + 1).where((index) {
      if (searchQuery.isEmpty) return true;
      final queryNum = int.tryParse(searchQuery);
      if (queryNum != null) return index == queryNum;
      return 'الحزب $index'.contains(searchQuery) || index.toString().contains(searchQuery);
    }).toList();

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: filteredHizb.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12, indent: 70),
      itemBuilder: (context, index) {
        final hizbNumber = filteredHizb[index];
        final juzNum = ((hizbNumber + 1) ~/ 2);
        final juzStartPage = juzPages[juzNum - 1];
        final startPage = hizbNumber % 2 == 0 ? juzStartPage + 10 : juzStartPage;

        final surahNum = quran.getSurahAndVersesFromJuz(juzNum).keys.first;
        final surahName = quran.getSurahNameArabic(surahNum);

        return ListTile(
          onTap: () => onNavigate(startPage),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          leading: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                hizbNumber.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ),
          title: Text(
            'الحزب $hizbNumber',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'cairo'),
          ),
          subtitle: Text(
            'سورة $surahName',
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontFamily: 'cairo'),
          ),
          trailing: Text(
            'ص $startPage',
            style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}

class _FawasilTab extends StatelessWidget {
  final Function(int) onNavigate;
  const _FawasilTab({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MushafController>();

    return Obx(() => controller.fawasil.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border_rounded, size: 80, color: AppColors.primary.withOpacity(0.1)),
          const SizedBox(height: 15),
          const Text('لا توجد فواصل مضافة', style: TextStyle(fontFamily: 'cairo', color: AppColors.textGrey)),
          const Text('أضف فاصلاً من داخل المصحف للرجوع إليه لاحقاً', style: TextStyle(fontFamily: 'cairo', fontSize: 12, color: Colors.grey)),
        ],
      ),
    )
        : ListView.separated(
      padding: const EdgeInsets.all(15),
      itemCount: controller.fawasil.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final fasil = controller.fawasil[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            onTap: () => onNavigate(fasil['page']),
            leading: const Icon(Icons.bookmark_rounded, color: AppColors.primary),
            title: Text(fasil['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'cairo')),
            subtitle: Text('صفحة ${fasil['page']}', style: const TextStyle(fontFamily: 'cairo', fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
              onPressed: () => controller.removeFasil(index),
            ),
          ),
        );
      },
    ));
  }
}
