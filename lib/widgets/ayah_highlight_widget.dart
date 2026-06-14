import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/quran_models.dart';
import '../utils/quran_constants.dart';

class HighlightableAyah extends StatefulWidget {
  final Ayah ayah;
  final bool isHighlighted;
  final Function(bool) onHighlightChanged;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  const HighlightableAyah({
    Key? key,
    required this.ayah,
    required this.isHighlighted,
    required this.onHighlightChanged,
    this.onCopy,
    this.onShare,
  }) : super(key: key);

  @override
  State<HighlightableAyah> createState() => _HighlightableAyahState();
}

class _HighlightableAyahState extends State<HighlightableAyah> {
  late bool _isHighlighted;

  @override
  void initState() {
    super.initState();
    _isHighlighted = widget.isHighlighted;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        setState(() => _isHighlighted = !_isHighlighted);
        widget.onHighlightChanged(_isHighlighted);
      },
      child: Container(
        decoration: BoxDecoration(
          color: _isHighlighted
              ? Color(QuranConstants.highlightColor)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: _isHighlighted
                ? Colors.amber[800]!
                : Colors.transparent,
            width: 1,
          ),
        ),
        padding: EdgeInsets.all(8.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.ayah.text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: QuranConstants.quranFontFamily,
                fontSize: QuranConstants.quranFontSize.sp,
                height: QuranConstants.lineHeight,
                color: Color(QuranConstants.textColor),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              ' \ufd3f${widget.ayah.number}\ufd3e ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: QuranConstants.quranFontFamily,
                fontSize: QuranConstants.ayahNumberFontSize.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
