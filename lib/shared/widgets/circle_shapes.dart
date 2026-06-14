import 'dart:math';
import 'package:flutter/material.dart';

class QuarterCircle extends StatelessWidget {
  final Color color;
  final double size;

  const QuarterCircle({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: QuarterCirclePainter(color),
    );
  }
}

class HalfCircle extends StatelessWidget {
  final Color color;
  final double size;

  const HalfCircle({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: HalfCirclePainter(color),
    );
  }
}

class ThreeQuartersCircle extends StatelessWidget {
  final Color color;
  final double size;

  const ThreeQuartersCircle({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: ThreeQuartersCirclePainter(color),
    );
  }
}

class QuarterCirclePainter extends CustomPainter {
  final Color color;
  QuarterCirclePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const double startAngle = -pi / 2;
    const double sweepAngle = pi / 2;
    canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class HalfCirclePainter extends CustomPainter {
  final Color color;
  HalfCirclePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const double startAngle = -pi / 2;
    const double sweepAngle = pi;
    canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ThreeQuartersCirclePainter extends CustomPainter {
  final Color color;
  ThreeQuartersCirclePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const double startAngle = -pi / 2;
    const double sweepAngle = 3 * pi / 2;
    canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
