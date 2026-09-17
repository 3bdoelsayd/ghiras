import 'package:flutter/material.dart';
import 'dart:math';

// ==========================================================
// 1) تعيين أيقونة ولون لكل درس (بدل الصور الفوتوغرافية)
// ==========================================================
class LessonVisual {
  final IconData icon;
  final Color color;
  const LessonVisual(this.icon, this.color);
}

class LessonIcons {
  static const Map<String, LessonVisual> map = {
    'lesson_pillars_islam': LessonVisual(Icons.mosque, Color(0xFF2E7D5B)),
    'lesson_pillars_iman': LessonVisual(Icons.auto_awesome, Color(0xFF4A6FA5)),
    'lesson_tawheed': LessonVisual(Icons.brightness_high, Color(0xFFC9982A)),
    'lesson_wudu': LessonVisual(Icons.water_drop, Color(0xFF2AA3C9)),
    'lesson_prayer': LessonVisual(Icons.self_improvement, Color(0xFF6B4C9A)),
    'lesson_akhlaq': LessonVisual(Icons.favorite, Color(0xFFC9524A)),
    'lesson_seerah': LessonVisual(Icons.menu_book, Color(0xFF8A5A2E)),
    'lesson_faq': LessonVisual(Icons.help_outline, Color(0xFF555555)),
  };

  static LessonVisual of(String lessonId) =>
      map[lessonId] ?? const LessonVisual(Icons.school, Color(0xFF2E7D5B));
}

// ==========================================================
// 2) بطاقة الدرس في القائمة الرئيسية (مع progress bar متحرك)
// ==========================================================
class LessonCard extends StatelessWidget {
  final String lessonId;
  final String title;
  final double progress; // 0.0 -> 1.0
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.lessonId,
    required this.title,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = LessonIcons.of(lessonId);
    final isDone = progress >= 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: visual.color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // خلفية تجميلية خفيفة جداً (أيقونة كبيرة باهتة في الزاوية)
              Positioned(
                left: -20,
                bottom: -20,
                child: Icon(
                  visual.icon,
                  size: 100,
                  color: visual.color.withOpacity(0.03),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'cairo',
                              color: Color(0xFF2D3436),
                            ),
                          ),
                        ),
                        if (isDone)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  "مكتمل",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontFamily: 'cairo',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: progress),
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutExpo,
                              builder: (context, value, _) => LinearProgressIndicator(
                                value: value,
                                minHeight: 8,
                                backgroundColor: const Color(0xFFF1F2F6),
                                valueColor: AlwaysStoppedAnimation(visual.color),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${(progress * 100).toInt()}%",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'cairo',
                            color: visual.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// 3) بطاقة اختيار الإجابة (بتتلوّن صح/غلط مع اهتزاز خفيف للغلط)
// ==========================================================
class AnswerOptionCard extends StatefulWidget {
  final String text;
  final bool isSelected;
  final bool? isCorrectAnswer; // null = مفيش إجابة اتحددت لسه
  final bool showResult;
  final VoidCallback onTap;

  const AnswerOptionCard({
    super.key,
    required this.text,
    required this.isSelected,
    required this.isCorrectAnswer,
    required this.showResult,
    required this.onTap,
  });

  @override
  State<AnswerOptionCard> createState() => _AnswerOptionCardState();
}

class _AnswerOptionCardState extends State<AnswerOptionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(covariant AnswerOptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // اهتزاز لو الاختيار ده غلط
    if (widget.showResult &&
        widget.isSelected &&
        widget.isCorrectAnswer == false &&
        !oldWidget.showResult) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Color _bgColor() {
    if (!widget.showResult || !widget.isSelected) {
      return widget.isSelected
          ? Colors.blue.withOpacity(0.08)
          : Colors.grey.withOpacity(0.06);
    }
    return widget.isCorrectAnswer == true
        ? Colors.green.withOpacity(0.15)
        : Colors.red.withOpacity(0.12);
  }

  Color _borderColor() {
    if (!widget.showResult) {
      return widget.isSelected ? Colors.blue : Colors.transparent;
    }
    return widget.isCorrectAnswer == true ? Colors.green : Colors.red;
  }

  IconData? _trailingIcon() {
    if (!widget.showResult || !widget.isSelected) return null;
    return widget.isCorrectAnswer == true
        ? Icons.check_circle
        : Icons.cancel;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shake = sin(_shakeController.value * pi * 4) * 6 *
            (1 - _shakeController.value);
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: GestureDetector(
        onTap: widget.showResult ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _bgColor(),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor(), width: 1.6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(widget.text, style: const TextStyle(fontSize: 15, fontFamily: 'cairo')),
              ),
              if (_trailingIcon() != null)
                Icon(_trailingIcon(),
                    color: widget.isCorrectAnswer == true
                        ? Colors.green
                        : Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// 4) صندوق التفسير اللي يظهر بعد الإجابة (Fade + Slide)
// ==========================================================
class ExplanationBox extends StatelessWidget {
  final String explanation;
  final bool isCorrect;
  final bool visible;

  const ExplanationBox({
    super.key,
    required this.explanation,
    required this.isCorrect,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.15), end: Offset.zero)
              .animate(anim),
          child: child,
        ),
      ),
      child: !visible
          ? const SizedBox.shrink(key: ValueKey('empty'))
          : Container(
              key: const ValueKey('explanation'),
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (isCorrect ? Colors.green : Colors.orange)
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isCorrect ? Colors.green : Colors.orange)
                      .withOpacity(0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isCorrect ? Icons.lightbulb : Icons.info_outline,
                    color: isCorrect ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(explanation,
                          style: const TextStyle(fontSize: 14, height: 1.4, fontFamily: 'cairo'))),
                ],
              ),
            ),
    );
  }
}

// ==========================================================
// 5) شاشة الاحتفال بإكمال الدرس (Scale + Icon pop، بدون مكتبات خارجية)
// ==========================================================
class LessonCompletionView extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final VoidCallback onFinish;

  const LessonCompletionView({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.onFinish,
  });

  @override
  State<LessonCompletionView> createState() => _LessonCompletionViewState();
}

class _LessonCompletionViewState extends State<LessonCompletionView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _message {
    final ratio =
        widget.totalQuestions == 0 ? 1.0 : widget.score / widget.totalQuestions;
    if (ratio >= 0.8) return 'ممتاز! فهمك للدرس رائع 🌟';
    if (ratio >= 0.5) return 'أحسنت! تقدر تراجع الدرس تاني لو حابب';
    return 'خلصت الدرس! جرّب تراجعه تاني عشان تثبّت المعلومة';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events,
                    color: Colors.green, size: 52),
              ),
            ),
            const SizedBox(height: 20),
            Text(_message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'cairo')),
            if (widget.totalQuestions > 0) ...[
              const SizedBox(height: 10),
              Text('${widget.score} من ${widget.totalQuestions} إجابات صحيحة',
                  style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'cairo')),
            ],
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: widget.onFinish,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('رجوع للدروس', style: TextStyle(fontFamily: 'cairo')),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// 6) الانتقال بين الخطوات (PageView + شريط تقدم أعلى الشاشة)
// ==========================================================
class StepProgressHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color color;

  const StepProgressHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final active = i <= currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 5,
            decoration: BoxDecoration(
              color: active ? color : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
