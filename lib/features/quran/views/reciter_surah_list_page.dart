import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;

import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/hive_helper.dart';
import '../../../core/models/reciter.dart';
import '../../../core/models/moshaf.dart';
import '../logic/player_bloc/player_bloc_bloc.dart';
import '../logic/quran_page_player/quran_page_player_bloc.dart';
import '../logic/quran_download_controller.dart';
import 'package:ghiras/main.dart';

// ─── Theme constants ───────────────────────────────────────────────────────────
const _kDarkGreen  = Color(0xFF1B4332);
const _kLightGreen = Color(0xFFD8F3DC);
const _kAccent     = Color(0xFF74C69D);
const _kBg         = Color(0xFFF5F0E8);
const _kCard       = Colors.white;
const _kBorder     = Color(0xFFE8E0D5);
const _kInnerBorder= Color(0xFFF0EBE3);
const _kTextMain   = Color(0xFF111111);
const _kTextMuted  = Color(0xFFBBBBBB);
const _kMakkahText = Color(0xFFC07A25);
const _kMakkahBg   = Color(0xFFFFFAF3);
const _kMakkahBdr  = Color(0xFFFDDBA5);
const _kMadinahBg  = Color(0xFFF0FAF3);
const _kMadinahBdr = Color(0xFFC3E6CB);
const _kPlayBg     = Color(0xFF1B4332);
const _kPlayIcon   = Color(0xFFD8F3DC);
const _kDlBg       = Color(0xFFE8F4FD);
const _kDlIcon     = Color(0xFF2980B9);
const _kDlDoneBg   = Color(0xFFEAFAF1);
const _kDlDoneIcon = Color(0xFF27AE60);
const _kFavOff     = Color(0xFFE0E0E0);
const _kFavOn      = Color(0xFFE53E3E);
const _kFavBg      = Color(0xFFFFF5F5);

class RecitersSurahListPage extends StatefulWidget {
  final Reciter reciter;
  final Moshaf mushaf;
  final dynamic jsonData;

  const RecitersSurahListPage({
    super.key,
    required this.reciter,
    required this.mushaf,
    required this.jsonData,
  });

  @override
  State<RecitersSurahListPage> createState() => _RecitersSurahListPageState();
}

class _RecitersSurahListPageState extends State<RecitersSurahListPage> {
  List surahs = [];
  List filteredSurahs = [];
  List favoriteSurahList = [];
  List favoriteSurahs = [];
  List downloadedSurahs = [];
  String selectedMode = "all";
  String? appDirPath;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initPath();
    _loadFavorites();
    _initSurahNames();
    _storePhotoUrl();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initPath() async {
    final dir = await getApplicationDocumentsDirectory();
    setState(() => appDirPath = "${dir.path}/skoon/");
  }

  void _initSurahNames() {
    setState(() {
      surahs = widget.mushaf.surahList.split(',').map((e) {
        final info = (widget.jsonData as List).firstWhere(
          (el) => el["id"].toString() == e.toString(),
          orElse: () => {"name": "سورة غير معروفة"},
        );
        return {"surahNumber": e, "suraName": info["name"]};
      }).toList();
    });
  }

  void _loadFavorites() {
    final d = getValue("favoriteSurahList");
    favoriteSurahList = d != null ? json.decode(d) : [];
  }

  String _favKey(int n) =>
      "${widget.reciter.name}${widget.mushaf.name}$n".trim();

  bool _isDownloaded(int surahNum) {
    if (appDirPath == null) return false;
    final fn = "reciter_${widget.reciter.id}_mushaf_${widget.mushaf.id}_surah_$surahNum.mp3";
    return File("$appDirPath$fn").existsSync();
  }

  void _filterFavoritesOnly() {
    setState(() {
      favoriteSurahs = surahs.where((s) =>
          favoriteSurahList.contains(_favKey(int.parse(s["surahNumber"])))).toList();
    });
  }

  void _filterDownloadsOnly() {
    if (appDirPath == null) return;
    setState(() {
      favoriteSurahs = surahs
          .where((s) => _isDownloaded(int.parse(s["surahNumber"])))
          .toList();
    });
  }

  void _filterSurahs(String value) {
    setState(() {
      filteredSurahs = value.isEmpty
          ? []
          : surahs
              .where((s) => _normalise(s["suraName"]).contains(_normalise(value)))
              .toList();
    });
  }

  String _normalise(String input) => input
      .replaceAll(RegExp(r'[\u064B-\u0652]'), '')
      .replaceAll('\u0622', '\u0627')
      .replaceAll('\u0623', '\u0627')
      .replaceAll('\u0625', '\u0627')
      .replaceAll('\u0649', '\u064A')
      .replaceAll('\u0629', '\u0647');

  Future<void> _storePhotoUrl() async {
    if (getValue("${widget.reciter.name} photo url") != null) return;
    try {
      final url =
          'https://www.googleapis.com/customsearch/v1?key=AIzaSyCR7ttKFGB4dG5MDJI3ygqiESjpWmKePrY&cx=f7b7aaf5b2f0e47e0&q=القارئ ${widget.reciter.name}&searchType=image';
      final res = await Dio().get(url);
      if (res.statusCode == 200 && res.data["items"] != null) {
        updateValue("${widget.reciter.name} photo url", res.data["items"][0]['link']);
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  List get _displayList {
    if (filteredSurahs.isNotEmpty) return filteredSurahs;
    if (selectedMode == "all") return surahs;
    return favoriteSurahs;
  }

  int get _downloadedCount =>
      surahs.where((s) => _isDownloaded(int.parse(s["surahNumber"]))).length;

  int get _favCount => favoriteSurahList
      .where((k) => surahs.any((s) => _favKey(int.parse(s["surahNumber"])) == k))
      .length;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 250.h,
              pinned: true,
              floating: true,
              backgroundColor: _kDarkGreen,
              automaticallyImplyLeading: false,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
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
                          colors: [Colors.black.withOpacity(0.3), _kDarkGreen],
                        ),
                      ),
                    ),
                    _buildHeaderContent(),
                  ],
                ),
              ),
            ),
          ],
          body: _buildList(),
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 0),
        child: Column(
          children: [
            // Title row
            Row(
              children: [
                _iconBtn(Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context)),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.reciter.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                          )),
                      Text(widget.mushaf.name,
                          style: TextStyle(
                            color: _kAccent,
                            fontSize: 11.sp,
                            fontFamily: 'Cairo',
                          )),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: Colors.white24,
                  backgroundImage: CachedNetworkImageProvider(
                    getValue("${widget.reciter.name} photo url") ??
                        "https://ghiras.app/logo.png",
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Stats
            Row(
              children: [
                _statBox("${surahs.length}", "سورة"),
                SizedBox(width: 8.w),
                _statBox("$_downloadedCount", "محملة"),
                SizedBox(width: 8.w),
                _statBox("$_favCount", "مفضلة"),
              ],
            ),
            SizedBox(height: 12.h),
            // Search
            Container(
              height: 38.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11.r),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _filterSurahs,
                style: TextStyle(color: Colors.white, fontSize: 13.sp, fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  hintText: "ابحث باسم السورة...",
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 13.sp, fontFamily: 'Cairo'),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.white38, size: 18.sp),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            // Tabs
            Row(
              children: [
                _tab("الكل", "all"),
                SizedBox(width: 7.w),
                _tab("المفضلة", "favorite"),
                SizedBox(width: 7.w),
                _tab("المحملة", "downloads"),
              ],
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String num, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.white.withOpacity(0.13)),
        ),
        child: Column(
          children: [
            Text(num,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: _kLightGreen,
                  fontFamily: 'Cairo',
                )),
            Text(label,
                style: TextStyle(
                  fontSize: 9.sp,
                  color: Colors.white54,
                  fontFamily: 'Cairo',
                )),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, String mode) {
    final active = selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => selectedMode = mode);
        if (mode == "favorite") _filterFavoritesOnly();
        if (mode == "downloads") _filterDownloadsOnly();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: active ? _kLightGreen : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: active ? _kDarkGreen : Colors.white60,
            )),
      ),
    );
  }

  Widget _iconBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34.w, height: 34.h,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(9.r),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: 16.sp),
      ),
    );
  }

  // ─── List ────────────────────────────────────────────────────────────────────
  Widget _buildList() {
    final list = _displayList;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48.sp, color: Colors.grey[400]),
            SizedBox(height: 10.h),
            Text("لا توجد نتائج",
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey[400], fontSize: 14.sp)),
          ],
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 30.h),
      children: [
        // Play all + Download all
        Row(
          children: [
            Expanded(
              child: _bigBtn(
                label: "تشغيل الكل",
                icon: Icons.play_arrow_rounded,
                bg: _kDarkGreen,
                labelColor: Colors.white,
                iconColor: _kLightGreen,
                onTap: () => playerPageBloc.add(StartPlaying(
                  moshaf: widget.mushaf,
                  reciter: widget.reciter,
                  suraNumber: -1,
                  initialIndex: 0,
                  buildContext: context,
                  jsonData: widget.jsonData,
                )),
              ),
            ),
            SizedBox(width: 8.w),
            Obx(() {
              final downloadController = Get.find<QuranDownloadController>();
              final isDownloadingAll = downloadController.isDownloadingAll.value;
              return _bigBtn(
                label: isDownloadingAll ? "إيقاف التحميل" : "تنزيل الكل",
                icon: isDownloadingAll ? Icons.stop_circle_rounded : Icons.download_rounded,
                bg: isDownloadingAll ? Colors.red[50]! : _kCard,
                labelColor: isDownloadingAll ? Colors.red : const Color(0xFF555555),
                iconColor: isDownloadingAll ? Colors.red : _kDlIcon,
                border: isDownloadingAll ? Colors.red[200] : _kBorder,
                onTap: () => downloadController.downloadAllSurahs(
                  reciter: widget.reciter,
                  moshaf: widget.mushaf,
                ),
              );
            }),
          ],
        ),
        SizedBox(height: 10.h),

        // Legend
        Row(
          children: [
            _legendDot(const Color(0xFF1B4332), "مدنية"),
            SizedBox(width: 12.w),
            _legendDot(const Color(0xFFE67E22), "مكية"),
          ],
        ),
        SizedBox(height: 10.h),

        // Surah rows
        ...list.map((surah) {
          final n = int.parse(surah["surahNumber"]);
          return _buildSurahRow(surah, n);
        }),
      ],
    );
  }

  Widget _bigBtn({
    required String label,
    required IconData icon,
    required Color bg,
    required Color labelColor,
    required Color iconColor,
    Color? border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 14.w),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(11.r),
          border: border != null ? Border.all(color: border) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 16.sp),
            SizedBox(width: 6.w),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: labelColor,
                )),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 7.w, height: 7.h, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 4.w),
        Text(label, style: TextStyle(fontSize: 10.sp, color: Colors.grey[500], fontFamily: 'Cairo')),
      ],
    );
  }

  // ─── Compact surah row ────────────────────────────────────────────────────────
  Widget _buildSurahRow(dynamic surah, int n) {
    final isMakkah = quran.getPlaceOfRevelation(n).toLowerCase() == "makkah";
    final isFav    = favoriteSurahList.contains(_favKey(n));
    final isDl     = _isDownloaded(n);
    
    final downloadController = Get.find<QuranDownloadController>();
    final fileKey = "${widget.reciter.name}-${widget.mushaf.id}-$n";

    return Container(
      height: 52.h,
      margin: EdgeInsets.only(bottom: 6.h),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          // Number badge
          Container(
            width: 44.w,
            height: double.infinity,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: _kInnerBorder)),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 28.w, height: 28.h,
              decoration: BoxDecoration(
                color: isMakkah ? _kMakkahBg : _kMadinahBg,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isMakkah ? _kMakkahBdr : _kMadinahBdr,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _toArabic(n),
                style: TextStyle(
                  fontSize: n > 99 ? 8.sp : 10.sp,
                  fontWeight: FontWeight.w700,
                  color: isMakkah ? _kMakkahText : _kDarkGreen,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),

          // Name + ayat count
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(surah["suraName"],
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: _kTextMain,
                        fontFamily: 'AmiriQuran',
                      )),
                  SizedBox(width: 4.w),
                  Text(
                    "${_toArabic(quran.getVerseCount(n))} آية",
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: _kTextMuted,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: EdgeInsets.only(left: 10.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionBtn(
                  bg: _kPlayBg,
                  icon: Icons.play_arrow_rounded,
                  color: _kPlayIcon,
                  onTap: () => _handlePlay(surah, n),
                ),
                SizedBox(width: 4.w),
                Obx(() {
                  final status = downloadController.downloadStatus[fileKey];
                  final progress = downloadController.downloadProgress[fileKey];

                  if (status == 'downloading' || status == 'paused') {
                    return GestureDetector(
                      onTap: () => downloadController.downloadSurah(
                        reciter: widget.reciter,
                        moshaf: widget.mushaf,
                        surahNum: n,
                      ),
                      child: Container(
                        width: 28.w, height: 28.h,
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: status == 'paused' ? Colors.orange[50] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: (progress ?? 0) / 100,
                              strokeWidth: 2,
                              color: status == 'paused' ? Colors.orange : Colors.blue,
                            ),
                            Icon(
                              status == 'paused' ? Icons.play_arrow_rounded : Icons.pause_rounded,
                              size: 10.sp,
                              color: status == 'paused' ? Colors.orange : Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  // إذا اكتمل التحميل الآن أو كان موجوداً مسبقاً
                  final isCurrentlyDl = isDl || status == 'completed';
                  
                  return _actionBtn(
                    bg: isCurrentlyDl ? _kDlDoneBg : _kDlBg,
                    icon: isCurrentlyDl ? Icons.check_rounded : Icons.download_rounded,
                    color: isCurrentlyDl ? _kDlDoneIcon : _kDlIcon,
                    onTap: () => _handleDownload(n),
                  );
                }),
                SizedBox(width: 4.w),
                _actionBtn(
                  bg: _kFavBg,
                  icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? _kFavOn : _kFavOff,
                  onTap: () => _toggleFavorite(n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required Color bg,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28.w, height: 28.h,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8.r)),
        child: Icon(icon, color: color, size: 14.sp),
      ),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────
  void _handlePlay(dynamic surah, int n) async {
    if (quranPagePlayerBloc.state is QuranPagePlayerPlaying) {
      final close = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: const Text("تنبيه", textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo')),
          content: const Text(
            "هل تريد إغلاق المشغل الحالي لبدء التلاوة الجديدة؟",
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("إلغاء", style: TextStyle(fontFamily: 'Cairo'))),
            TextButton(onPressed: () => Navigator.pop(ctx, true),  child: const Text("نعم",   style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF1B4332)))),
          ],
        ),
      );
      if (close != true) return;
      quranPagePlayerBloc.add(KillPlayerEvent());
    }

    playerPageBloc.add(StartPlaying(
      moshaf: widget.mushaf,
      reciter: widget.reciter,
      suraNumber: n,
      initialIndex: surahs.indexOf(surah),
      buildContext: context,
      jsonData: widget.jsonData,
    ));
  }

  void _handleDownload(int n) {
    final downloadController = Get.find<QuranDownloadController>();
    downloadController.downloadSurah(
      reciter: widget.reciter,
      moshaf: widget.mushaf,
      surahNum: n,
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() {});
    });
  }

  void _toggleFavorite(int n) {
    final key = _favKey(n);
    setState(() {
      favoriteSurahList.contains(key)
          ? favoriteSurahList.remove(key)
          : favoriteSurahList.add(key);
      updateValue("favoriteSurahList", json.encode(favoriteSurahList));
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────
  String _toArabic(int n) {
    const e = ['0','1','2','3','4','5','6','7','8','9'];
    const a = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    return n.toString().split('').map((d) => a[e.indexOf(d)]).join();
  }
}