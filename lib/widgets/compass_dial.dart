import 'package:flutter/material.dart';
import 'dart:math';

class CompassDial extends StatefulWidget {
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
  State<CompassDial> createState() => _CompassDialState();
}

class _CompassDialState extends State<CompassDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _previousBearing = 0.0;

  @override
  void initState() {
    super.initState();
    _previousBearing = widget.bearing;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: _previousBearing,
      end: widget.bearing,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(CompassDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bearing != widget.bearing) {
      _previousBearing = _animation.value;
      _animation = Tween<double>(
        begin: _previousBearing,
        end: widget.bearing,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: CompassPainter(
            bearing: _animation.value,
            trueBearing: widget.trueBearing,
            showTrueBearing: widget.showTrueBearing,
            isDark: isDark,
          ),
          size: const Size(300, 300),
        );
      },
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

    // Draw gradient background like iCompass
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF2C2C2C),
          const Color(0xFF1A1A1A),
          Colors.black,
        ],
        stops: const [0.0, 0.7, 1.0],
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
    const directions = ['N', 'E', 'S', 'W'];
    const angles = [0, 90, 180, 270];

    for (int i = 0; i < directions.length; i++) {
      final angle = angles[i] * pi / 180;
      final x = center.dx + (radius * 0.5) * sin(angle);
      final y = center.dy - (radius * 0.5) * cos(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: directions[i],
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
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

    // Draw smaller tick marks every 10 degrees
    for (int i = 0; i < 360; i += 10) {
      if (cardinalAngles.contains(i)) continue; // Skip cardinal points
      final angle = i * pi / 180;
      final startRadius = radius - 10;
      final endRadius = radius - 5;

      final startX = center.dx + startRadius * sin(angle);
      final startY = center.dy - startRadius * cos(angle);
      final endX = center.dx + endRadius * sin(angle);
      final endY = center.dy - endRadius * cos(angle);

      final paint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..strokeWidth = 1.5
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
    final needleLength = radius - 40;
    final endX = center.dx + needleLength * sin(angle);
    final endY = center.dy - needleLength * cos(angle);

    // Shadow/glow effect
    canvas.drawLine(
      Offset(center.dx + 2, center.dy + 2),
      Offset(endX + 2, endY + 2),
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    // Red needle
    canvas.drawLine(
      center,
      Offset(endX, endY),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // Arrowhead with glow
    final arrowSize = 18;
    final angle1 = angle + (160 * pi / 180);
    final angle2 = angle - (160 * pi / 180);

    final arrow1X = endX + arrowSize * cos(angle1);
    final arrow1Y = endY + arrowSize * sin(angle1);
    final arrow2X = endX + arrowSize * cos(angle2);
    final arrow2Y = endY + arrowSize * sin(angle2);

    final path = Path();
    path.moveTo(endX, endY);
    path.lineTo(arrow1X, arrow1Y);
    path.lineTo(arrow2X, arrow2Y);
    path.close();

    // Shadow
    canvas.drawPath(
      path.shift(const Offset(2, 2)),
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );

    // Arrow
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
