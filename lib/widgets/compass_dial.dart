import 'package:flutter/material.dart';
import 'dart:math';

class CompassDial extends StatelessWidget {
  final double bearing;

  const CompassDial({
    Key? key,
    required this.bearing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CompassPainter(bearing: bearing),
      size: const Size(300, 300),
    );
  }
}

class CompassPainter extends CustomPainter {
  final double bearing;

  CompassPainter({required this.bearing});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Black background
    canvas.drawCircle(center, radius, Paint()..color = Colors.black);

    // Outer circle border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ROTATING DIAL - save and rotate
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-bearing * pi / 180);

    // Draw tick marks and degree numbers
    for (int i = 0; i < 360; i += 5) {
      final angle = i * pi / 180;
      final bool isMajor = i % 30 == 0;
      final bool isCardinal = i % 90 == 0;
      final bool isNorth = i == 0;

      // Tick mark lengths
      final outerRadius = radius - 10;
      final innerRadius = radius - (isMajor ? 30 : 20);

      final x1 = outerRadius * sin(angle);
      final y1 = -outerRadius * cos(angle);
      final x2 = innerRadius * sin(angle);
      final y2 = -innerRadius * cos(angle);

      // Tick color: North in Cyan, others in White
      Color tickColor;
      if (isNorth) {
        tickColor = const Color(0xFF00BCD4); // Cyan/Light Blue for North
      } else if (isMajor) {
        tickColor = Colors.white;
      } else {
        tickColor = Colors.white.withOpacity(0.5);
      }

      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = tickColor
          ..strokeWidth = isMajor ? 2.5 : 1.0
          ..strokeCap = StrokeCap.round,
      );

      // Draw degree numbers at major ticks (0, 30, 60...330)
      if (isMajor && !isCardinal) {
        final numberRadius = radius - 45;
        final nx = numberRadius * sin(angle);
        final ny = -numberRadius * cos(angle);

        final textPainter = TextPainter(
          text: TextSpan(
            text: i.toString(),
            style: TextStyle(
              color: isNorth ? const Color(0xFF00BCD4) : Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(nx - textPainter.width / 2, ny - textPainter.height / 2),
        );
      }
    }

    // Draw cardinal directions (N, E, S, W) inside tick marks
    const directions = ['N', 'E', 'S', 'W'];
    const dirAngles = [0, 90, 180, 270];
    final labelRadius = radius - 55;

    for (int i = 0; i < 4; i++) {
      final angle = dirAngles[i] * pi / 180;
      final x = labelRadius * sin(angle);
      final y = -labelRadius * cos(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: directions[i],
          style: TextStyle(
            color: directions[i] == 'N'
                ? const Color(0xFF00BCD4) // Cyan for North
                : Colors.white,
            fontSize: directions[i] == 'N' ? 22 : 18,
            fontWeight: FontWeight.w700,
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

    canvas.restore(); // End rotating dial

    // FIXED RED HEADING INDICATOR at top-center (does NOT rotate)
    final indicatorLength = 30.0;
    final indicatorY = center.dy - radius + 5;

    // Red triangle at top
    final trianglePath = Path();
    trianglePath.moveTo(center.dx, indicatorY);
    trianglePath.lineTo(center.dx - 8, indicatorY - indicatorLength);
    trianglePath.lineTo(center.dx + 8, indicatorY - indicatorLength);
    trianglePath.close();

    canvas.drawPath(
      trianglePath,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill,
    );

    // CENTER DISPLAY - Current heading in degrees
    final headingText = TextPainter(
      text: TextSpan(
        text: '${bearing.round()}°',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    headingText.layout();
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
