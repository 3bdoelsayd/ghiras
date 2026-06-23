import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/hive_helper.dart';
import '../../../core/models/reciter.dart';
import '../../../core/models/moshaf.dart';
import '../logic/player_bloc/player_bloc_bloc.dart';
import 'package:ghiras/main.dart';

import 'reciter_surah_list_page.dart';

// ─── Theme constants ───────────────────────────────────────────────────────────
const _kDarkGreen   = Color(0xFF1B4332);
const _kMidGreen    = Color(0xFF40916C);
const _kLightGreen  = Color(0xFFD8F3DC);
const _kAccentGreen = Color(0xFF74C69D);
const _kBg          = Color(0xFFF7F3EE);
const _kCard        = Colors.white;
const _kBorder      = Color(0xFFE8E0D5);
const _kTextPrimary = Color(0xFF1A1A1A);
const _kTextMuted   = Color(0xFF888888);
const _kPlayBg      = Color(0xFFFFF3E0);
const _kPlayIcon    = Color(0xFFE67E22);
const _kDlBg        = Color(0xFFE8F4FD);
const _kDlIcon      = Color(0xFF2980B9);
const _kFavBg       = Color(0xFFFFF5F5);
const _kFavBorder   = Color(0xFFFFD6D6);
const _kFavIcon     = Color(0xFFE53E3E);

class RecitersPage extends StatefulWidget {
  const RecitersPage({super.key, this.jsonData});
  final dynamic jsonData;

  @override
  _RecitersPageState createState() => _RecitersPageState();
}

class _RecitersPageState extends State<RecitersPage> {
  late List<Reciter> reciters;
  bool isLoading = true;
  late Dio dio;
  List<Reciter> favoriteRecitersList = [];
  List<Reciter> filteredReciters = [];
  List<Moshaf> rewayat = [];
  List suwar = [];

  final TextEditingController textEditingController = TextEditingController();
  String selectedMode = "all";

  @override
  void initState() {
    super.initState();
    reciters = [];
    dio = Dio();
    getFavoriteList();
    fetchReciters();
  }

  void getFavoriteList() {
    var jsonData = getValue("favoriteRecitersList");
    if (jsonData != null) {
      final List<dynamic> data = json.decode(jsonData);
      setState(() {
        favoriteRecitersList = reciters.where((r) => data.contains(r.id)).toList();
      });
    }
  }

  Future<void> getAndStoreRecitersData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      const lang = "ar";
      final r1 = await dio.get('https://mp3quran.net/api/v3/reciters?language=$lang');
      final r2 = await dio.get('https://mp3quran.net/api/v3/moshaf?language=$lang');
      final r3 = await dio.get('https://mp3quran.net/api/v3/suwar?language=$lang');
      if (r1.data?['reciters'] != null) prefs.setString("reciters-$lang", json.encode(r1.data['reciters']));
      if (r2.data?['riwayat'] != null) prefs.setString("moshaf-$lang",   json.encode(r2.data));
      if (r3.data?['suwar']   != null) prefs.setString("suwar-$lang",    json.encode(r3.data['suwar']));
    } catch (e) {
      debugPrint('Error storing data: $e');
    }
  }

  Future<void> fetchReciters() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      const lang  = "ar";
      
      String? d1 = prefs.getString("reciters-$lang");
      String? d2 = prefs.getString("moshaf-$lang");
      String? d3 = prefs.getString("suwar-$lang");

      if (d1 == null || d2 == null || d3 == null) {
        await getAndStoreRecitersData();
        d1 = prefs.getString("reciters-$lang");
        d2 = prefs.getString("moshaf-$lang");
        d3 = prefs.getString("suwar-$lang");
      }

      if (d1 != null && d2 != null && d3 != null) {
        final List<dynamic> data1 = json.decode(d1);
        final dynamic data2Raw = json.decode(d2);
        final List<dynamic> data2 = data2Raw is Map ? data2Raw["riwayat"] : data2Raw;
        final List<dynamic> data3 = json.decode(d3);
        
        final List<Reciter> loadedReciters = data1.map((r) => Reciter.fromJson(r)).toList();
        loadedReciters.sort((a, b) => a.name.toString().compareTo(b.name.toString()));

        // جلب المفضلة بناءً على البيانات الجديدة قبل عمل setState
        var favJson = getValue("favoriteRecitersList");
        List<Reciter> favList = [];
        if (favJson != null) {
          final List<dynamic> favIds = json.decode(favJson);
          favList = loadedReciters.where((r) => favIds.contains(r.id)).toList();
        }

        if (mounted) {
          setState(() {
            reciters = loadedReciters;
            filteredReciters = List.from(loadedReciters);
            favoriteRecitersList = favList;
            rewayat = data2.map((m) => Moshaf.fromJson(m)).toList();
            suwar = data3;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error fetching reciters: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void filterReciters(String query) {
    setState(() {
      filteredReciters = reciters
          .where((r) => r.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  List<Reciter> get _displayList {
    if (selectedMode == "favorite") return favoriteRecitersList;
    if (selectedMode != "all") {
      return filteredReciters
          .where((r) => r.moshaf.any((m) => m.id.toString() == selectedMode))
          .toList();
    }
    return filteredReciters;
  }

  void _toggleFavorite(Reciter reciter) {
    setState(() {
      if (favoriteRecitersList.any((r) => r.id == reciter.id)) {
        favoriteRecitersList.removeWhere((r) => r.id == reciter.id);
      } else {
        favoriteRecitersList.add(reciter);
      }
      updateValue(
        "favoriteRecitersList",
        json.encode(favoriteRecitersList.map((r) => r.id).toList()),
      );
    });
  }

  void _startPlaying(Reciter reciter, Moshaf moshaf) {
    playerPageBloc.add(StartPlaying(
      moshaf: moshaf,
      reciter: reciter,
      suraNumber: -1,
      initialIndex: 0,
      buildContext: context,
      jsonData: suwar,
    ));
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w, height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0D8CE),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text("تصفية القراء",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                    color: _kTextPrimary,
                  )),
              SizedBox(height: 12.h),
              _filterOption("الكل",      "all",      Icons.all_inclusive_rounded),
              _filterOption("المفضلة",  "favorite", Icons.favorite_rounded),
              const Divider(height: 20, color: _kBorder),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: rewayat.map((r) => _filterOption(r.name, r.id.toString(), Icons.menu_book_rounded)).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterOption(String title, String mode, IconData icon) {
    final bool active = selectedMode == mode;
    return InkWell(
      onTap: () {
        setState(() => selectedMode = mode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
        child: Row(
          children: [
            Container(
              width: 36.w, height: 36.h,
              decoration: BoxDecoration(
                color: active ? _kLightGreen : const Color(0xFFF5F0EA),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon,
                color: active ? _kDarkGreen : _kTextMuted,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    color: active ? _kDarkGreen : _kTextPrimary,
                  )),
            ),
            if (active)
              Icon(Icons.check_circle_rounded, color: _kDarkGreen, size: 20.sp),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200.h,
            pinned: true,
            floating: true,
            snap: true,
            backgroundColor: _kDarkGreen,
            automaticallyImplyLeading: false,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _buildHeaderContent(),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(48.h),
              child: _buildTabsRow(),
            ),
          ),
        ],
        body: _buildBody(),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Stack(
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
              colors: [Colors.black.withOpacity(0.3), _kDarkGreen],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("جميع القراء",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Cairo',
                              )),
                          Text(
                              "${reciters.isNotEmpty ? reciters.length : '—'} قارئاً من حول العالم",
                              style: TextStyle(
                                color: _kAccentGreen,
                                fontSize: 11.sp,
                                fontFamily: 'Cairo',
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 6.h),
                child: Container(
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: TextField(
                    controller: textEditingController,
                    onChanged: filterReciters,
                    style: TextStyle(color: Colors.white, fontSize: 13.sp, fontFamily: 'Cairo'),
                    decoration: InputDecoration(
                      hintText: "ابحث عن قارئ...",
                      hintStyle: TextStyle(color: Colors.white54, fontSize: 13.sp, fontFamily: 'Cairo'),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.white54, size: 18.sp),
                      suffixIcon: textEditingController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: Colors.white54, size: 15.sp),
                        onPressed: () {
                          textEditingController.clear();
                          filterReciters('');
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 48.h),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabsRow() {
    return Container(
      color: _kDarkGreen,
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      child: Row(
        children: [
          _buildTab("الكل", "all"),
          SizedBox(width: 8.w),
          _buildTab("المفضلة", "favorite"),
        ],
      ),
    );
  }

  Widget _buildTab(String label, String mode) {
    final bool active = selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => selectedMode = mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: active ? _kLightGreen : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: active ? _kDarkGreen : Colors.white.withOpacity(0.75),
            )),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kDarkGreen));
    }

    final list = _displayList;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 64.sp, color: _kTextMuted.withOpacity(0.5)),
              SizedBox(height: 16.h),
              Text(
                "لم نتمكن من تحميل قائمة القراء",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo', color: _kTextPrimary, fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8.h),
              Text(
                "يرجى التأكد من اتصالك بالإنترنت والمحاولة مرة أخرى",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo', color: _kTextMuted, fontSize: 13.sp),
              ),
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: fetchReciters,
                icon: Icon(Icons.refresh_rounded, size: 18.sp, color: Colors.white),
                label: Text("إعادة المحاولة", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kDarkGreen,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 10.h, bottom: 20.h),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _buildReciterCard(list[index]);
      },
    );
  }

  Widget _buildReciterCard(Reciter reciter) {
    final bool isFav = favoriteRecitersList.any((r) => r.id == reciter.id);

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _kBorder),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/images/zikrback.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              iconColor: _kDarkGreen,
              collapsedIconColor: _kTextMuted,
              leading: Container(
                width: 46.w, height: 46.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kDarkGreen, _kMidGreen],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  reciter.name.isNotEmpty ? reciter.name[0] : "؟",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reciter.name,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: _kTextPrimary,
                            )),
                        Text(
                            reciter.moshaf.isNotEmpty
                                ? "${reciter.moshaf.length} ${reciter.moshaf.length == 1 ? 'رواية' : 'روايات'}"
                                : "",
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11.sp,
                              color: _kTextMuted,
                            )),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleFavorite(reciter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32.w, height: 32.h,
                      decoration: BoxDecoration(
                        color: isFav ? const Color(0xFFFFE4E4) : _kFavBg,
                        borderRadius: BorderRadius.circular(9.r),
                        border: Border.all(color: _kFavBorder),
                      ),
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _kFavIcon,
                        size: 16.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
              ),
              children: reciter.moshaf.map((m) => _buildMoshafRow(reciter, m)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoshafRow(Reciter reciter, Moshaf moshaf) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecitersSurahListPage(
            reciter: reciter,
            mushaf: moshaf,
            jsonData: suwar,
          ),
        ),
      ),
      borderRadius: BorderRadius.only(
        bottomRight: Radius.circular(16.r),
        bottomLeft:  Radius.circular(16.r),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: Row(
          children: [
            Container(
              width: 30.w, height: 30.h,
              decoration: BoxDecoration(
                color: _kLightGreen,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFC3E6CB)),
              ),
              child: Icon(Icons.menu_book_rounded, color: _kDarkGreen, size: 15.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(moshaf.name,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF444444),
                      )),
                  Text(
                    "${moshaf.surahTotal} سورة ${moshaf.surahTotal == 114 ? '(مصحف كامل)' : ''}",
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10.sp,
                      color: moshaf.surahTotal == 114 ? _kDarkGreen : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionButton(
                  bg: _kPlayBg,
                  icon: Icons.play_circle_outline_rounded,
                  iconColor: _kPlayIcon,
                  tooltip: "تشغيل",
                  onTap: () => _startPlaying(reciter, moshaf),
                ),
                SizedBox(width: 6.w),
                _actionButton(
                  bg: _kDlBg,
                  icon: Icons.download_for_offline_outlined,
                  iconColor: _kDlIcon,
                  tooltip: "تنزيل",
                  onTap: () => playerPageBloc.add(
                    DownloadAllSurahs(moshaf: moshaf, reciter: reciter),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required Color bg,
    required IconData icon,
    required Color iconColor,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32.w, height: 32.h,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9.r),
          ),
          child: Icon(icon, color: iconColor, size: 17.sp),
        ),
      ),
    );
  }
}
