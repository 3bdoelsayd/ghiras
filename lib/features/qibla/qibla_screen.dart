import 'dart:async';
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
  bool _isLoading = true;
  double _qiblaDirection = 140.0; 
  bool _isAligned = false;

  @override
  void initState() {
    super.initState();
    _initQibla();
  }

  Future<void> _initQibla() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      ).catchError((_) => null);

      if (position != null) {
        final qibla = Qibla(Coordinates(position.latitude, position.longitude));
        if (mounted) {
          setState(() {
            _qiblaDirection = qibla.direction;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('اتجاه القبلة', 
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppColors.primary)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : StreamBuilder<CompassEvent>(
            stream: FlutterCompass.events,
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('خطأ في المستشعر: ${snapshot.error}'));
              
              final double? direction = snapshot.data?.heading;
              if (direction == null) return const Center(child: Text('البوصلة غير مدعومة'));

              // حساب الانحراف
              double currentHeading = direction < 0 ? direction + 360 : direction;
              double qiblaOffset = _qiblaDirection - currentHeading;
              
              // التحقق من المحاذاة (إذا كان الفرق أقل من 10 درجات)
              bool aligned = (qiblaOffset.abs() % 360) < 10 || (qiblaOffset.abs() % 360) > 350;
              
              if (aligned && !_isAligned) {
                HapticFeedback.lightImpact();
                _isAligned = true;
              } else if (!aligned && _isAligned) {
                _isAligned = false;
              }

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isAligned ? "الجهاز يشير إلى اتجاه القبلة" : "قم بتدوير الجهاز حتى يتغير السهم للأخضر",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: _isAligned ? Colors.green : Colors.grey[600],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 50),
                    
                    // جسم البوصلة
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // الدائرة الخارجية والاتجاهات
                          AnimatedRotation(
                            turns: -currentHeading / 360,
                            duration: const Duration(milliseconds: 200),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                                    border: Border.all(color: Colors.white, width: 10),
                                  ),
                                ),
                                // رسم النقاط البسيطة
                                ...List.generate(36, (i) => Transform.rotate(
                                  angle: i * 10 * (pi / 180),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 15),
                                      width: 2, height: 8,
                                      color: Colors.grey.withOpacity(0.2),
                                    ),
                                  ),
                                )),
                                _buildDir('N', 0, Colors.red),
                                _buildDir('E', 90, AppColors.primary),
                                _buildDir('S', 180, AppColors.primary),
                                _buildDir('W', 270, AppColors.primary),
                              ],
                            ),
                          ),

                          // سهم القبلة (مربوط في السنتر بالمللي)
                          AnimatedRotation(
                            turns: qiblaOffset / 360,
                            duration: const Duration(milliseconds: 200),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.width * 0.8,
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // السهم: القاعدة بتاعته في السنتر بالظبط
                                  Transform.translate(
                                    offset: Offset(0, -MediaQuery.of(context).size.width * 0.125), // نصف طول السهم للأعلى
                                    child: SvgPicture.asset(
                                      "assets/images/needle.svg",
                                      height: MediaQuery.of(context).size.width * 0.25,
                                      fit: BoxFit.contain,
                                      colorFilter: ColorFilter.mode(
                                        _isAligned ? Colors.green : const Color(0xFFF39C12),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  // أيقونة الكعبة: راكبة فوق رأس السهم بالظبط
                                  Transform.translate(
                                    offset: Offset(0, -MediaQuery.of(context).size.width * 0.25), 
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: _isAligned ? Colors.green : const Color(0xFFF39C12),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                      ),
                                      child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 18),
                                    ),
                                  ),
                                  // نقطة تثبيت في المركز عشان الشكل يكمل
                                  Container(
                                    width: 10, height: 10,
                                    decoration: const BoxDecoration(color: Color(0xFFF39C12), shape: BoxShape.circle),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // نقطة ارتكاز صغيرة في المركز (اختياري لجمال التصميم)
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 80),
                    Text("اتجاه القبلة من الشمال", style: TextStyle(fontFamily: 'Cairo', color: Colors.grey[600], fontSize: 16)),
                    Text("${_qiblaDirection.toInt()}°", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildDir(String text, double angle, Color color) {
    return Transform.rotate(
      angle: angle * (pi / 180),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 25),
          child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 22)),
        ),
      ),
    );
  }
}
