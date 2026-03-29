import 'package:flutter/material.dart';
import 'dart:math';

class CompassDial extends StatefulWidget {
  final double bearing;

  const CompassDial({
    Key? key,
    required this.bearing,
  }) : super(key: key);

  @override
  State<CompassDial> createState() => _CompassDialState();
}

class _CompassDialState extends State<CompassDial> {
  late double _initialBearing;
  double _targetBearing = 0;

  @override
  void initState() {
    super.initState();
    _initialBearing = widget.bearing;
    _targetBearing = widget.bearing;
  }

  @override
  void didUpdateWidget(CompassDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bearing != widget.bearing) {
      // Calculate shortest path rotation
      double delta = widget.bearing - (_targetBearing % 360);
      if (delta > 180) delta -= 360;
      if (delta < -180) delta += 360;
      _targetBearing += delta;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // By keeping begin constant and only changing end, 
      // TweenAnimationBuilder will always animate from its CURRENT value to the new end.
      tween: Tween<double>(begin: _initialBearing, end: _targetBearing),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      builder: (context, animatedBearing, child) {
        return RepaintBoundary(
          child: CustomPaint(
            painter: CompassPainter(bearing: animatedBearing),
            size: const Size(300, 300),
          ),
        );
      },
    );
  }
}

class CompassPainter extends CustomPainter {
  final double bearing;

  // Cache TextPainters to avoid expensive layout calls in paint()
  static final Map<String, TextPainter> _textCache = {};

  CompassPainter({required this.bearing});

  TextPainter _getOrCreateText(String text, TextStyle style) {
    final key = '$text-${style.fontSize}-${style.fontWeight}-${style.color?.value}';
    if (!_textCache.containsKey(key)) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      _textCache[key] = tp;
    }
    return _textCache[key]!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Normalize bearing for display text
    final displayBearing = (bearing % 360 + 360) % 360;

    // 1. Static background - Black circle
    canvas.drawCircle(center, radius, Paint()..color = Colors.black);

    // 2. Outer circle border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ROTATING DIAL
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-bearing * pi / 180);

    final majorTickPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    
    final minorTickPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final northTickPaint = Paint()
      ..color = const Color(0xFF00BCD4)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 360; i += 5) {
      final angle = i * pi / 180;
      final bool isMajor = i % 30 == 0;
      final bool isCardinal = i % 90 == 0;
      final bool isNorth = i == 0;

      final outerRadius = radius - 10;
      final innerRadius = radius - (isMajor ? 30 : 20);

      final x1 = outerRadius * sin(angle);
      final y1 = -outerRadius * cos(angle);
      final x2 = innerRadius * sin(angle);
      final y2 = -innerRadius * cos(angle);

      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        isNorth ? northTickPaint : (isMajor ? majorTickPaint : minorTickPaint),
      );

      if (isMajor && !isCardinal) {
        final numberRadius = radius - 45;
        final nx = numberRadius * sin(angle);
        final ny = -numberRadius * cos(angle);

        final textPainter = _getOrCreateText(
          i.toString(),
          TextStyle(
            color: isNorth ? const Color(0xFF00BCD4) : Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        );
        
        textPainter.paint(
          canvas,
          Offset(nx - textPainter.width / 2, ny - textPainter.height / 2),
        );
      }
    }

    const directions = ['N', 'E', 'S', 'W'];
    const dirAngles = [0, 90, 180, 270];
    final labelRadius = radius - 55;

    for (int i = 0; i < 4; i++) {
      final angle = dirAngles[i] * pi / 180;
      final x = labelRadius * sin(angle);
      final y = -labelRadius * cos(angle);

      final textPainter = _getOrCreateText(
        directions[i],
        TextStyle(
          color: directions[i] == 'N' ? const Color(0xFF00BCD4) : Colors.white,
          fontSize: directions[i] == 'N' ? 22 : 18,
          fontWeight: FontWeight.w700,
        ),
      );

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    canvas.restore();

    // FIXED RED HEADING INDICATOR
    final indicatorY = center.dy - radius + 5;
    final trianglePath = Path();
    trianglePath.moveTo(center.dx, indicatorY);
    trianglePath.lineTo(center.dx - 8, indicatorY - 30);
    trianglePath.lineTo(center.dx + 8, indicatorY - 30);
    trianglePath.close();

    canvas.drawPath(trianglePath, Paint()..color = Colors.red);

    // CENTER DISPLAY
    final headingText = _getOrCreateText(
      '${displayBearing.round()}°',
      const TextStyle(
        color: Colors.white,
        fontSize: 48,
        fontWeight: FontWeight.w900,
      ),
    );
    
    headingText.paint(
      canvas,
      Offset(center.dx - headingText.width / 2, center.dy - headingText.height / 2),
    );
  }

  @override
  bool shouldRepaint(CompassPainter oldDelegate) {
    return oldDelegate.bearing != bearing;
  }
}
