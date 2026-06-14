import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran_meta;
import 'mushaf_screen.dart';

class SurahDetailsScreen extends StatefulWidget {
  final int surahNumber;
  const SurahDetailsScreen({super.key, required this.surahNumber});

  @override
  State<SurahDetailsScreen> createState() => _SurahDetailsScreenState();
}

class _SurahDetailsScreenState extends State<SurahDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // This screen is now a redirector to the MushafScreen with the correct page
  }

  @override
  Widget build(BuildContext context) {
    final initialPage = quran_meta.getSurahPages(widget.surahNumber)[0];
    return MushafScreen(initialPage: initialPage);
  }
}
