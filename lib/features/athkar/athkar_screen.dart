import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'data/azkar_data.dart';
import 'data/athkar_model.dart';
import 'athkar_details_screen.dart';

class AthkarScreen extends StatefulWidget {
  final ScrollController? scrollController;
  const AthkarScreen({super.key, this.scrollController});

  @override
  State<AthkarScreen> createState() => _AthkarScreenState();
}

class _AthkarScreenState extends State<AthkarScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? morningAthkar;
    Map<String, dynamic>? eveningAthkar;
    List<Map<String, dynamic>> otherAthkar = [];

    for (var item in azkarList) {
      if (item['category'] == 'أذكار الصباح') {
        morningAthkar = item;
      } else if (item['category'] == 'أذكار المساء') {
        eveningAthkar = item;
      } else {
        if (_searchQuery.isEmpty || item['category'].toString().contains(_searchQuery)) {
          otherAthkar.add(item);
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: widget.scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- قسم أذكار الصباح ---
                  if (morningAthkar != null && _searchQuery.isEmpty) ...[
                    _buildMainCategoryCard(
                      morningAthkar,
                      'أذكار الصباح',
                      'ابدأ يومك بذكر الله وطمأنينة القلب',
                      Icons.wb_sunny_rounded,
                      [const Color(0xFFF39C12), const Color(0xFFF1C40F)],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // --- قسم أذكار المساء ---
                  if (eveningAthkar != null && _searchQuery.isEmpty) ...[
                    _buildMainCategoryCard(
                      eveningAthkar,
                      'أذكار المساء',
                      'حصن نفسك في ليلك واستشعر معية الله',
                      Icons.nights_stay_rounded,
                      [const Color(0xFF2C3E50), const Color(0xFF4B79A1)],
                    ),
                    const SizedBox(height: 35),
                  ],

                  _buildSectionHeader('أذكار متنوعة'),
                  const SizedBox(height: 15),
                  _buildSearchBar(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderBehavior(
                (context, index) => _buildOtherCategoryItem(otherAthkar[index]),
                childCount: otherAthkar.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'الأذكار والدعاء',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 18),
        ),
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
    );
  }

  Widget _buildMainCategoryCard(Map<String, dynamic> item, String title, String subtitle, IconData icon, List<Color> colors) {
    return InkWell(
      onTap: () => _navigateToDetails(item),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 180),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topRight, end: Alignment.bottomLeft),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              Positioned(
                left: -20,
                bottom: -20,
                child: Icon(icon, size: 150, color: Colors.white.withValues(alpha: 0.15)),
              ),
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: Icon(icon, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
              ),
              const Positioned(
                top: 25,
                left: 25,
                child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 5, height: 25, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(5))),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark, fontFamily: 'Cairo'),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'ابحث عن أذكار أخرى...',
          hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14, fontFamily: 'Cairo'),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildOtherCategoryItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.05),
          child: const Icon(Icons.spa_rounded, color: AppColors.primary, size: 20),
        ),
        title: Text(
          item['category'],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Cairo'),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black12),
        onTap: () => _navigateToDetails(item),
      ),
    );
  }

  void _navigateToDetails(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AthkarDetailsScreen(
          category: AthkarCategory.fromJson(item),
        ),
      ),
    );
  }
}

class SliverChildBuilderBehavior extends SliverChildBuilderDelegate {
  SliverChildBuilderBehavior(super.builder, {super.childCount});
}
