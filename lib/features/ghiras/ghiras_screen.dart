import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/glass_container.dart';
import '../athkar/data/athkar_model.dart';
import '../../shared/widgets/circle_shapes.dart';
import '../../shared/widgets/circle_shapes.dart';

class GhirasScreen extends StatefulWidget {
  const GhirasScreen({super.key});

  @override
  State<GhirasScreen> createState() => _GhirasScreenState();
}

class _GhirasScreenState extends State<GhirasScreen> {
  int _treeStage = 0; // 0 to 4
  int _totalTrees = 0;
  int _todayTrees = 0;
  String _currentStatus = 'اغرس نخلتك الآن في الجنة';
  late Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings');
    _totalTrees = _settingsBox.get('total_palm_trees', defaultValue: 0);
    _loadTodayTrees();
  }

  void _loadTodayTrees() {
    final todayKey = 'palm_trees_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    _todayTrees = _settingsBox.get(todayKey, defaultValue: 0);
  }

  void _onTasbeehTap() {
    if (_treeStage >= 4) return;

    setState(() {
      _treeStage++;
      if (_treeStage == 4) {
        _totalTrees++;
        _todayTrees++;
        
        // حفظ البيانات في Hive
        _settingsBox.put('total_palm_trees', _totalTrees);
        final todayKey = 'palm_trees_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
        _settingsBox.put(todayKey, _todayTrees);

        _currentStatus = 'مبارك! غُرست لك نخلة في الجنة';
        // Reset after delay to start a new tree
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _treeStage = 0;
              _currentStatus = 'اغرس نخلة جديدة بذكر الله';
            });
          }
        });
      } else {
        _currentStatus = 'استمر.. نخلتك تكبر وتزهر';
      }
    });
  }

  String _getCurrentZikir() {
    switch (_treeStage) {
      case 0: return 'سبحان الله';
      case 1: return 'الحمد لله';
      case 2: return 'لا إله إلا الله';
      case 3: return 'الله أكبر';
      default: return 'ما شاء الله';
    }
  }

  String _getCurrentStep() {
    switch (_treeStage) {
      case 0: return 'تثبيت الغرس';
      case 1: return 'سقيا النماء';
      case 2: return 'نمو الجذع';
      case 3: return 'تمام النخلة';
      default: return 'اكتملت';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'غِراس الجنة',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/zikrbkg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Decorative Gradients
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.2),
                    AppColors.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    _buildTreeCounter(),
                    const SizedBox(height: 25),
                    _buildVisualPalmTree(),
                    const SizedBox(height: 25),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        _currentStatus,
                        key: ValueKey(_currentStatus),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          fontFamily: 'Cairo',
                          shadows: [
                            Shadow(
                              color: Colors.white,
                              blurRadius: 10,
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildTasbeehButton(),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeCounter() {
    return GlassContainer(
      opacity: 0.1,
      blur: 15,
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_totalTrees نخلة',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.wb_sunny_rounded, color: Colors.orangeAccent, size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualPalmTree() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Circular Progress Indicator using the imported shapes
          Positioned(
            bottom: 30,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _buildProgressCircle(),
            ),
          ),

          // Ground - أصغر وألطف
          Positioned(
            bottom: 0,
            child: Container(
              width: 120,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          // Trunk - أنحف وأكثر أناقة
          Positioned(
            bottom: 4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              height: _treeStage >= 3 ? 120 : (_treeStage >= 2 ? 60 : 0),
              width: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF795548),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          // Palm Fronds - تصميم أصغر وأكثر تناسقاً
          Positioned(
            bottom: _treeStage >= 3 ? 110 : 55,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 800),
              scale: _treeStage >= 4 ? 0.8 : (_treeStage >= 3 ? 0.3 : 0.0), // تصغير المقياس النهائي
              curve: Curves.easeOutBack,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildLeaf(angle: -0.7, offset: const Offset(-30, -30)),
                  _buildLeaf(angle: 0.7, offset: const Offset(30, -30)),
                  _buildLeaf(angle: -1.8, offset: const Offset(-40, 5)),
                  _buildLeaf(angle: 1.8, offset: const Offset(40, 5)),
                  _buildLeaf(angle: 0, offset: const Offset(0, -45)),
                  
                  // Center core
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Growth Sprout
          if (_treeStage > 0 && _treeStage < 3)
            Positioned(
              bottom: 5,
              child: Icon(Icons.eco_rounded, 
                size: _treeStage * 20.0, 
                color: Colors.green.shade400
              ),
            ),

          if (_treeStage >= 4)
            ...List.generate(8, (index) => _buildSparkle(index)),
        ],
      ),
    );
  }

  Widget _buildProgressCircle() {
    const double circleSize = 160.0;
    final Color progressColor = AppColors.primary.withValues(alpha: 0.1);
    
    switch (_treeStage) {
      case 1:
        return QuarterCircle(color: progressColor, size: circleSize);
      case 2:
        return HalfCircle(color: progressColor, size: circleSize);
      case 3:
        return ThreeQuartersCircle(color: progressColor, size: circleSize);
      case 4:
        return Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: progressColor,
            shape: BoxShape.circle,
          ),
        );
      default:
        return const SizedBox(width: circleSize, height: circleSize);
    }
  }

  Widget _buildLeaf({required double angle, required Offset offset}) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 60, // تصغير السعف
          height: 22,
          decoration: BoxDecoration(
            color: Colors.green.shade700,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
              topRight: Radius.circular(5),
              bottomLeft: Radius.circular(5),
            ),
            gradient: LinearGradient(
              colors: [Colors.green.shade800, Colors.green.shade400],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSparkle(int index) {
    return Positioned(
      bottom: 180 + (index * 8.0),
      left: 80 + (index % 4 * 40.0),
      child: Icon(Icons.auto_awesome, color: Colors.amber.withValues(alpha: 0.8), size: 12 + (index % 3 * 4.0)),
    );
  }

  Widget _buildTasbeehButton() {
    return GestureDetector(
      onTap: _onTasbeehTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 25),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(35),
          image: const DecorationImage(
            image: AssetImage('assets/images/tasbeehbackground.png'),
            opacity: 0.05,
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            )
          ],
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 2),
        ),
        child: Column(
          children: [
            Text(
              _getCurrentZikir(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getCurrentStep(),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGrey.withValues(alpha: 0.8),
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Text(
                'اضغط هنا للتسبيح والغرس',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
