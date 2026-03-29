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

    // Draw premium gradient background with multiple layers
    // Outer glow ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.cyan.withOpacity(0.1),
            Colors.transparent,
          ],
          stops: const [0.8, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // Main dial gradient
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3A3A3A), // Light gray center
          const Color(0xFF2A2A2A), // Medium gray
          const Color(0xFF1A1A1A), // Dark gray
          Colors.black, // Black edge
        ],
        stops: const [0.0, 0.4, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, gradientPaint);

    // Draw concentric rings for depth
    for (int i = 1; i <= 3; i++) {
      final ringRadius = radius * (i / 4);
      canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Inner highlight ring
    canvas.drawCircle(
      center,
      radius * 0.6,
      Paint()
        ..color = Colors.white.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

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

    // Draw geomagnetic north-south axis (4D scientific visualization)
    _drawGeomagneticAxis(canvas, center, radius, bearing, trueBearing);

    // Draw center circle with magnetic field visualization
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = Colors.red.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      center,
      8,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      center,
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Draw bearing text in center
    _drawBearingText(canvas, center, radius, bearing, isDark);
  }

  void _drawCardinalDirections(Canvas canvas, Offset center, double radius, bool isDark) {
    const directions = ['N', 'E', 'S', 'W'];
    const angles = [0, 90, 180, 270];
    const colors = [Colors.red, Colors.cyan, Colors.cyan, Colors.cyan]; // North in red, others cyan
    const scientificNames = ['Magnetic North', 'East', 'South', 'West'];

    for (int i = 0; i < directions.length; i++) {
      final angle = angles[i] * pi / 180;
      final textRadius = radius * 0.7;
      final x = center.dx + textRadius * sin(angle);
      final y = center.dy - textRadius * cos(angle);

      // Draw directional indicator lines (4D effect)
      final indicatorLength = radius * 0.15;
      for (int j = 0; j < 3; j++) {
        final lineRadius = radius * (0.8 + j * 0.05);
        final startX = center.dx + (lineRadius - indicatorLength) * sin(angle);
        final startY = center.dy - (lineRadius - indicatorLength) * cos(angle);
        final endX = center.dx + lineRadius * sin(angle);
        final endY = center.dy - lineRadius * cos(angle);

        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          Paint()
            ..color = colors[i].withOpacity(0.8 - j * 0.2)
            ..strokeWidth = (3 - j).toDouble()
            ..strokeCap = StrokeCap.round,
        );
      }

      // Enhanced arrowhead for North (scientific magnetic pole indicator)
      if (i == 0) { // North
        final arrowSize = 12;
        final arrowStartRadius = radius * 0.75;
        final arrowEndRadius = radius * 0.82;

        final startX = center.dx + arrowStartRadius * sin(angle);
        final startY = center.dy - arrowStartRadius * cos(angle);
        final endX = center.dx + arrowEndRadius * sin(angle);
        final endY = center.dy - arrowEndRadius * cos(angle);

        // Arrow shaft
        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          Paint()
            ..color = Colors.red
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );

        // Arrowhead
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

        // Glow effect
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.red.withOpacity(0.5)
            ..style = PaintingStyle.fill,
        );

        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.red
            ..style = PaintingStyle.fill,
        );
      }

      // Scientific direction labels
      final textPainter = TextPainter(
        text: TextSpan(
          text: directions[i],
          style: TextStyle(
            color: colors[i],
            fontSize: i == 0 ? 32 : 24, // North larger
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.7),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );

      // Add scientific subtitle for North
      if (i == 0) {
        final subtitlePainter = TextPainter(
          text: TextSpan(
            text: 'Magnetic',
            style: TextStyle(
              color: Colors.red.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        subtitlePainter.layout();
        subtitlePainter.paint(
          canvas,
          Offset(x - subtitlePainter.width / 2, y + 18),
        );
      }
    }
  }

  void _drawDegreeMarkers(Canvas canvas, Offset center, double radius, bool isDark) {
    // Draw main cardinal markers with numbers
    const cardinalAngles = [0, 90, 180, 270];
    const cardinalLabels = ['N', 'E', 'S', 'W'];

    for (int i = 0; i < cardinalAngles.length; i++) {
      final angle = cardinalAngles[i] * pi / 180;
      final startRadius = radius - 25;
      final endRadius = radius - 5;

      final startX = center.dx + startRadius * sin(angle);
      final startY = center.dy - startRadius * cos(angle);
      final endX = center.dx + endRadius * sin(angle);
      final endY = center.dy - endRadius * cos(angle);

      final paint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );

      // Draw numbers
      final textPainter = TextPainter(
        text: TextSpan(
          text: cardinalLabels[i],
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final labelRadius = radius - 40;
      final labelX = center.dx + labelRadius * sin(angle);
      final labelY = center.dy - labelRadius * cos(angle);
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
      );
    }

    // Draw degree markers every 30 degrees with numbers
    for (int i = 0; i < 360; i += 30) {
      if (cardinalAngles.contains(i)) continue; // Skip cardinal points
      final angle = i * pi / 180;
      final startRadius = radius - 15;
      final endRadius = radius - 5;

      final startX = center.dx + startRadius * sin(angle);
      final startY = center.dy - startRadius * cos(angle);
      final endX = center.dx + endRadius * sin(angle);
      final endY = center.dy - endRadius * cos(angle);

      // Longer tick
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );

      // Add degree numbers
      final textRadius = radius - 30;
      final textX = center.dx + textRadius * sin(angle);
      final textY = center.dy - textRadius * cos(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: i.toString(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );
    }

    // Draw smaller tick marks every 10 degrees
    for (int i = 0; i < 360; i += 10) {
      if (cardinalAngles.contains(i) || i % 30 == 0) continue; // Skip major marks
      final angle = i * pi / 180;
      final startRadius = radius - 10;
      final endRadius = radius - 5;

      final startX = center.dx + startRadius * sin(angle);
      final startY = center.dy - startRadius * cos(angle);
      final endX = center.dx + endRadius * sin(angle);
      final endY = center.dy - endRadius * cos(angle);

      final paint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 1
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

    // Main needle
    final needleLength = radius - 45;
    final endX = center.dx + needleLength * sin(angle);
    final endY = center.dy - needleLength * cos(angle);

    // Outer glow ring for needle
    canvas.drawLine(
      center,
      Offset(endX, endY),
      Paint()
        ..color = Colors.red.withOpacity(0.3)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Main red needle
    canvas.drawLine(
      center,
      Offset(endX, endY),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Inner white line for contrast
    canvas.drawLine(
      center,
      Offset(endX, endY),
      Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Enhanced arrowhead
    final arrowSize = 20;
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

    // Arrow glow
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..style = PaintingStyle.fill,
    );

    // Arrow fill
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill,
    );

    // Center dot
    canvas.drawCircle(
      center,
      6,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      center,
      4,
      Paint()
        ..color = Colors.white
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

  void _drawGeomagneticAxis(Canvas canvas, Offset center, double radius, double magneticBearing, double trueBearing) {
    // Scientific 4D geomagnetic field visualization
    final axisLength = radius * 0.9;

    // Always show geomagnetic field representation
    // Magnetic north-south meridian (red - Earth's magnetic field)
    final magAngle = magneticBearing * pi / 180;

    // Draw magnetic field meridian lines with higher opacity
    for (int i = 0; i < 4; i++) {
      final distance = axisLength * (0.3 + i * 0.2);
      final northX = center.dx + distance * sin(magAngle);
      final northY = center.dy - distance * cos(magAngle);
      final southX = center.dx - distance * sin(magAngle);
      final southY = center.dy + distance * cos(magAngle);

      canvas.drawLine(
        Offset(southX, southY),
        Offset(northX, northY),
        Paint()
          ..color = Colors.red.withOpacity(0.6 - i * 0.1)
          ..strokeWidth = 2 - i * 0.3
          ..strokeCap = StrokeCap.round,
      );
    }

    // True north-south geographic meridian (blue - Earth's rotational axis)
    final trueAngle = trueBearing * pi / 180;

    // Draw geographic meridian with different style
    final trueNorthX = center.dx + axisLength * sin(trueAngle);
    final trueNorthY = center.dy - axisLength * cos(trueAngle);
    final trueSouthX = center.dx - axisLength * sin(trueAngle);
    final trueSouthY = center.dy + axisLength * cos(trueAngle);

    // Dashed line for geographic north
    _drawDashedLine(
      canvas,
      Offset(center.dx, center.dy),
      Offset(trueNorthX, trueNorthY),
      Paint()
        ..color = Colors.blue.withOpacity(0.7)
        ..strokeWidth = 2,
    );

    // Solid line for geographic south
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(trueSouthX, trueSouthY),
      Paint()
        ..color = Colors.blue.withOpacity(0.7)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // 4D Declination visualization - show magnetic variation
    final declinationAngle = ((trueBearing - magneticBearing + 180) % 360 - 180);
    if (declinationAngle.abs() > 0.5) {
      final declinationRadius = radius * 0.7;

      // Draw declination angle indicator
      final rect = Rect.fromCircle(center: center, radius: declinationRadius);
      final startAngle = magneticBearing * pi / 180;
      final sweepAngle = declinationAngle * pi / 180;

      // Background arc
      canvas.drawArc(
        rect,
        0,
        2 * pi,
        false,
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );

      // Declination arc
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = Colors.yellow.withOpacity(0.8)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );

      // Declination angle text
      final declinationText = '${declinationAngle.abs().toStringAsFixed(1)}°';
      final textPainter = TextPainter(
        text: TextSpan(
          text: declinationText,
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final textAngle = (startAngle + sweepAngle / 2) % (2 * pi);
      final textRadius = radius * 0.8;
      final textX = center.dx + textRadius * sin(textAngle);
      final textY = center.dy - textRadius * cos(textAngle);

      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );
    }

    // Scientific field lines emanating from center (4D effect)
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * pi / 180;
      final fieldLength = radius * (0.4 + (i % 2) * 0.2);

      final endX = center.dx + fieldLength * sin(angle);
      final endY = center.dy - fieldLength * cos(angle);

      canvas.drawLine(
        Offset(center.dx, center.dy),
        Offset(endX, endY),
        Paint()
          ..color = Colors.cyan.withOpacity(0.3)
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round,
      );
    }
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
          fontSize: 50,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
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
