import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import '../../core/constants/app_colors.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  bool _hasPermissions = false;
  bool _isLoading = true;
  Position? _currentPosition;
  double? _qiblaDirection;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        );

        final qibla = Qibla(Coordinates(position.latitude, position.longitude));

        if (mounted) {
          setState(() {
            _currentPosition = position;
            _qiblaDirection = qibla.direction;
            _hasPermissions = true;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _hasPermissions = true;
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _hasPermissions = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPrimary,
      appBar: AppBar(
        title: const Text(
          'اتجاة القبلة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : !_hasPermissions
              ? _buildPermissionError()
              : _buildCompass(),
    );
  }

  Widget _buildCompass() {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text("خطأ في قراءة البوصلة: ${snapshot.error}",
                style: const TextStyle(color: Colors.white)),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        double? direction = snapshot.data?.heading;

        if (direction == null) {
          return const Center(
            child: Text(
              "هذا الجهاز لا يدعم مستشعر البوصلة",
              style: TextStyle(fontFamily: 'Cairo', fontSize: 18, color: Colors.white),
            ),
          );
        }

        // تحويل الدرجات إلى دورات (Turns) لاستخدامها مع AnimatedRotation
        // القبلة بالنسبة للشمال هي _qiblaDirection
        // زاوية الهاتف الحالية هي direction
        // الزاوية المطلوبة للمؤشر ليشير للقبلة هي (qibla - direction)
        double qiblaOffset = (_qiblaDirection ?? 0) - direction;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // عرض زاوية القبلة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Text(
                      "زاوية القبلة",
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Cairo'),
                    ),
                    Text(
                      "${_qiblaDirection?.toStringAsFixed(0) ?? '0'}°",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              
              // البوصلة
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.width * 0.85,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // جسم البوصلة (يدور مع حركة الهاتف ليشير الشمال دائماً للأعلى في الصورة)
                    // أو العكس، حسب الرغبة. هنا سنجعل البوصلة تدور ليبقى N مشيراً للشمال الحقيقي
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 400),
                      turns: -direction / 360,
                      child: Image.asset(
                        "assets/images/compassn.png",
                        fit: BoxFit.contain,
                      ),
                    ),

                    // إبرة القبلة (تدور لتشير لاتجاه الكعبة دائماً)
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 400),
                      turns: qiblaOffset / 360,
                      child: SvgPicture.asset(
                        "assets/images/needle.svg",
                        height: MediaQuery.of(context).size.width * 0.6,
                        fit: BoxFit.contain,
                      ),
                    ),
                    
                    // أيقونة مسجد في المركز للجمالية
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mosque_rounded, color: Colors.amber, size: 30),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 50),
              const Text(
                "اجعل إبرة القبلة تشير للأعلى",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "ابعد الهاتف عن المعادن والمغناطيس",
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermissionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_rounded, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            const Text(
              "تحتاج البوصلة إلى إذن الموقع لتحديد اتجاه القبلة بدقة",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _checkPermissions,
              icon: const Icon(Icons.location_on),
              label: const Text("تفعيل الموقع", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
