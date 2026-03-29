import 'package:flutter/material.dart';
import 'dart:math';

class CompassDial extends StatelessWidget {
  final double bearing;
  final double trueBearing;
  final bool showTrueBearing;

  const CompassDial({
    Key? key,
    required this.bearing,
    required this.trueBearing,
    this.showTrueBearing = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return CustomPaint(
      painter: CompassPainter(
        bearing: bearing,
        trueBearing: trueBearing,
        showTrueBearing: showTrueBearing,
        isDark: isDark,
      ),
      size: const Size(300, 300),
    );
  }
}

class CompassPainter extends CustomPainter {
  final double bearing;
  final double trueBearing;
  final bool showTrueBearing;
  final bool isDark;

  CompassPainter({
    required this.bearing,
    required this.trueBearing,
    required this.showTrueBearing,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw gradient background
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.grey[800]!,
          Colors.grey[900]!,
          Colors.black,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, gradientPaint);

    // Draw multiple rings for depth
    for (int i = 3; i >= 1; i--) {
      canvas.drawCircle(
        center,
        radius * (i / 3),
        Paint()
          ..color = Colors.cyan.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Draw outer glowing border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.cyan.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Draw cardinal directions
    _drawCardinalDirections(canvas, center, radius, isDark);

    // Draw degree markers
    _drawDegreeMarkers(canvas, center, radius, isDark);

    // Draw rotating background with grid
    _drawRotatingBackground(canvas, center, radius, bearing, isDark);

    // Draw bearing indicator (red needle)
    _drawBearingIndicator(canvas, center, radius, bearing, isDark);

    // Draw true bearing indicator if enabled (blue dashed line)
    if (showTrueBearing && trueBearing != bearing) {
      _drawTrueBearingIndicator(canvas, center, radius, trueBearing, isDark);
    }

    // Draw center circle
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill,
    );

    // Draw bearing text in center
    _drawBearingText(canvas, center, radius, bearing, isDark);
  }

  void _drawCardinalDirections(Canvas canvas, Offset center, double radius, bool isDark) {
    const directions = ['N', 'S', 'E', 'W'];
    const angles = [0, 180, 90, 270];

    for (int i = 0; i < directions.length; i++) {
      final angle = angles[i] * pi / 180;
      final x = center.dx + (radius * 0.6) * sin(angle);
      final y = center.dy - (radius * 0.6) * cos(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: directions[i],
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  void _drawDegreeMarkers(Canvas canvas, Offset center, double radius, bool isDark) {
    for (int i = 0; i < 360; i += 5) {
      final angle = i * pi / 180;
      final isRed = i == 0; // North, 12 o'clock
      final isMainMarker = i % 10 == 0;

      final startRadius = radius - 15;
      final endRadius = radius - 5;

      final startX = center.dx + startRadius * sin(angle);
      final startY = center.dy - startRadius * cos(angle);
      final endX = center.dx + endRadius * sin(angle);
      final endY = center.dy - endRadius * cos(angle);

      // Right side (east) cyan/light blue, rest white
      final isRightSide = i <= 180;
      final color = isRed ? Colors.red : isRightSide ? Colors.cyan.withOpacity(0.6) : Colors.white.withOpacity(0.7);

      final paint = Paint()
        ..color = color
        ..strokeWidth = isRed ? 4 : isMainMarker ? 2 : 1
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  void _drawRotatingBackground(Canvas canvas, Offset center, double radius, double bearing, bool isDark) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-bearing * pi / 180);

    final paint = Paint()
      ..color = (isDark ? Colors.blue[900] : Colors.blue[50])!
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;

    // Draw a wedge from -45 to +45 degrees (forward direction)
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(
      radius * 0.7 * sin(-45 * pi / 180),
      -radius * 0.7 * cos(-45 * pi / 180),
    );
    path.arcToPoint(
      Offset(
        radius * 0.7 * sin(45 * pi / 180),
        -radius * 0.7 * cos(45 * pi / 180),
      ),
      radius: Radius.circular(radius * 0.7),
    );
    path.close();

    canvas.drawPath(path, paint..color = isDark ? Colors.blue[900]! : Colors.blue[100]!);

    canvas.restore();
  }

  void _drawBearingIndicator(Canvas canvas, Offset center, double radius, double bearing, bool isDark) {
    final angle = bearing * pi / 180;

    // Red needle pointing to bearing
    final needleLength = radius - 30;
    final endX = center.dx + needleLength * sin(angle);
    final endY = center.dy - needleLength * cos(angle);

    canvas.drawLine(
      center,
      Offset(endX, endY),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Draw arrowhead
    final arrowSize = 15;
    final angle1 = angle + (150 * pi / 180);
    final angle2 = angle - (150 * pi / 180);

    final arrow1X = endX + arrowSize * cos(angle1);
    final arrow1Y = endY + arrowSize * sin(angle1);
    final arrow2X = endX + arrowSize * cos(angle2);
    final arrow2Y = endY + arrowSize * sin(angle2);

    final path = Path();
    path.moveTo(endX, endY);
    path.lineTo(arrow1X, arrow1Y);
    path.lineTo(arrow2X, arrow2Y);
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill,
    );
  }

  void _drawTrueBearingIndicator(Canvas canvas, Offset center, double radius, double trueBearing, bool isDark) {
    final angle = trueBearing * pi / 180;
    final needleLength = radius - 40;
    final endX = center.dx + needleLength * sin(angle);
    final endY = center.dy - needleLength * cos(angle);

    // Blue dashed line
    _drawDashedLine(
      canvas,
      center,
      Offset(endX, endY),
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 8;
    const dashSpace = 5;
    
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final steps = distance / (dashWidth + dashSpace);

    for (int i = 0; i < steps; i++) {
      final t1 = (i * (dashWidth + dashSpace)) / distance;
      final t2 = (i * (dashWidth + dashSpace) + dashWidth) / distance;

      if (t2 <= 1.0) {
        canvas.drawLine(
          Offset(start.dx + dx * t1, start.dy + dy * t1),
          Offset(start.dx + dx * t2, start.dy + dy * t2),
          paint,
        );
      }
    }
  }

  void _drawBearingText(Canvas canvas, Offset center, double radius, double bearing, bool isDark) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${bearing.toStringAsFixed(0)}°',
        style: TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }



  @override
  bool shouldRepaint(CompassPainter oldDelegate) {
    return oldDelegate.bearing != bearing ||
        oldDelegate.trueBearing != trueBearing;
  }
}
