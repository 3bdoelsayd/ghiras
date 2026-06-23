import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  double _qiblaDirection = 140.0; // fallback لو GPS فشل
  bool _isAligned = false;

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
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        final qibla = Qibla(Coordinates(position.latitude, position.longitude));

        if (mounted) {
          setState(() {
            _qiblaDirection = qibla.direction; // ← الزاوية الحقيقية
            _hasPermissions = true;
            _isLoading = false;
          });
        }
      } catch (_) {
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
      backgroundColor: const Color(0xFFF5F3EE),
      body: Stack(
        children: [
          Positioned(
            top: -120, right: -100,
            child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.01),
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -50, left: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFC9A84C).withValues(alpha: 0.1),
                  const Color(0xFFC9A84C).withValues(alpha: 0.01),
                ]),
              ),
            ),
          ),
          ..._buildDecorativeParticles(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : !_hasPermissions
                      ? _buildPermissionError()
                      : _buildCompass(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
          Column(children: [
            const Text(
              'اتجاه القبلة',
              style: TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.w900,
                color: AppColors.primary, fontSize: 22,
              ),
            ),
            Container(
              width: 30, height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFC9A84C),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ]),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  List<Widget> _buildDecorativeParticles() {
    return [
      Positioned(top: 150, left: 40, child: _particle(6, AppColors.primary.withValues(alpha: 0.12))),
      Positioned(bottom: 200, right: 50, child: _particle(4, const Color(0xFFC9A84C).withValues(alpha: 0.15))),
      Positioned(top: 400, right: 30, child: _particle(5, AppColors.primary.withValues(alpha: 0.08))),
    ];
  }

  Widget _particle(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildCompass() {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("خطأ في قراءة البوصلة: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final double? direction = snapshot.data?.heading;

        if (direction == null) {
          return const Center(
            child: Text(
              "هذا الجهاز لا يدعم مستشعر البوصلة",
              style: TextStyle(fontFamily: 'Cairo', fontSize: 18, color: Color(0xFF2C3E50)),
            ),
          );
        }

        // ✅ الحساب الصح: القبلة الحقيقية ناقص اتجاه الهاتف
        final double qiblaOffset = _qiblaDirection - direction;
        final bool currentlyAligned = (qiblaOffset.abs() % 360) < 5 || (qiblaOffset.abs() % 360) > 355;

        if (currentlyAligned && !_isAligned) {
          HapticFeedback.lightImpact();
          _isAligned = true;
        } else if (!currentlyAligned && _isAligned) {
          _isAligned = false;
        }

        final double currentHeading = direction < 0 ? direction + 360 : direction;
        final double qiblaDeg = _qiblaDirection < 0 ? _qiblaDirection + 360 : _qiblaDirection;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge الاتجاه
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                decoration: BoxDecoration(
                  color: currentlyAligned
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: currentlyAligned
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(children: [
                  const Text(
                    "اتجاه الهاتف الحالي",
                    style: TextStyle(
                      color: AppColors.primary, fontSize: 13,
                      fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${currentHeading.toInt()}°",
                    style: TextStyle(
                      fontSize: 52, fontWeight: FontWeight.w900, fontFamily: 'Cairo',
                      color: currentlyAligned ? AppColors.primary : const Color(0xFF2C3E50),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 8),

              Text(
                "القبلة عند زاوية ${qiblaDeg.toInt()}°",
                style: TextStyle(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  fontSize: 14, fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 28),

              // البوصلة
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.82,
                height: MediaQuery.of(context).size.width * 0.82,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // الدائرة الدوارة (الأرقام)
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      turns: -direction / 360,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  blurRadius: 30, offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                          ),
                          // خطوط الدرجات الصغيرة
                          ...List.generate(36, (i) {
                            final angle = i * 10.0;
                            final bool isMajor = i % 3 == 0;
                            return Transform.rotate(
                              angle: angle * (pi / 180),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  width: isMajor ? 2 : 1,
                                  height: isMajor ? 14 : 8,
                                  color: isMajor
                                      ? AppColors.primary.withValues(alpha: 0.35)
                                      : Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                            );
                          }),
                          // الأرقام الرئيسية
                          ...List.generate(12, (index) {
                            final double angle = index * 30.0;
                            return Transform.rotate(
                              angle: angle * (pi / 180),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 26),
                                  child: Text(
                                    index == 0 ? 'N' : '${angle.toInt()}',
                                    style: TextStyle(
                                      color: index == 0 ? AppColors.primary : Colors.grey.withValues(alpha: 0.65),
                                      fontWeight: index == 0 ? FontWeight.w900 : FontWeight.bold,
                                      fontSize: index == 0 ? 17 : 10,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // ✅ الإبرة تدور بالزاوية الصح
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      turns: qiblaOffset / 360,
                      child: SvgPicture.asset(
                        "assets/images/needle.svg",
                        height: MediaQuery.of(context).size.width * 0.52,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          currentlyAligned ? const Color(0xFFC9A84C) : AppColors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),

                    // أيقونة الكعبة
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12, offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFC9A84C).withValues(alpha: 0.25), width: 1.5,
                        ),
                      ),
                      child: const Icon(Icons.mosque_rounded, color: Color(0xFFC9A84C), size: 30),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  key: ValueKey(_isAligned),
                  _isAligned ? "✓  أنت الآن باتجاه القبلة" : "وجه الهاتف نحو زاوية ${qiblaDeg.toInt()}°",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: _isAligned ? AppColors.primary : const Color(0xFF2C3E50),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_rounded, size: 60, color: Color(0xFFC9A84C)),
            const SizedBox(height: 24),
            const Text(
              "تحديد القبلة يتطلب الوصول للموقع",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo', fontSize: 20,
                color: Color(0xFF2C3E50), fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _checkPermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text("تفعيل الموقع",
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}