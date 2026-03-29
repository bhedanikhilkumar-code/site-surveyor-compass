import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/compass_provider.dart';

class LevelScreen extends StatelessWidget {
  const LevelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'LEVEL',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<CompassProvider>(
        builder: (context, compassProvider, _) {
          return Column(
            children: [
              const SizedBox(height: 40),
              // Level display
              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.grey[800]!,
                        Colors.grey[900]!,
                        Colors.black,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.cyan.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: LevelBubble(
                    pitch: compassProvider.pitch,
                    roll: compassProvider.roll,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Readings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildReading('Pitch', '${compassProvider.pitch.toStringAsFixed(1)}°'),
                    _buildReading('Roll', '${compassProvider.roll.toStringAsFixed(1)}°'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReading(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.cyan,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class LevelBubble extends StatelessWidget {
  final double pitch;
  final double roll;

  const LevelBubble({
    Key? key,
    required this.pitch,
    required this.roll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Grid lines
        CustomPaint(
          size: const Size(300, 300),
          painter: LevelGridPainter(),
        ),
        // Bubble
        Transform.translate(
          offset: Offset(
            roll * 2, // Scale the movement
            pitch * 2,
          ),
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.cyan,
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        // Center target
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}

class LevelGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);

    // Horizontal lines
    for (int i = -4; i <= 4; i++) {
      final y = center.dy + i * 20;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Vertical lines
    for (int i = -4; i <= 4; i++) {
      final x = center.dx + i * 20;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Center cross
    paint.strokeWidth = 2;
    canvas.drawLine(
      Offset(center.dx - 30, center.dy),
      Offset(center.dx + 30, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 30),
      Offset(center.dx, center.dy + 30),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}