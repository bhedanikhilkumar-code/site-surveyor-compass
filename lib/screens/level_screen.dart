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

class LevelBubble extends StatefulWidget {
  final double pitch;
  final double roll;

  const LevelBubble({
    Key? key,
    required this.pitch,
    required this.roll,
  }) : super(key: key);

  @override
  State<LevelBubble> createState() => _LevelBubbleState();
}

class _LevelBubbleState extends State<LevelBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  Offset _currentOffset = Offset.zero;
  Offset _targetOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _currentOffset = Offset(widget.roll * 2.5, widget.pitch * 2.5);
    _targetOffset = _currentOffset;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _animation = Tween<Offset>(begin: _currentOffset, end: _targetOffset).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(LevelBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pitch != widget.pitch || oldWidget.roll != widget.roll) {
      _currentOffset = _animation.value;
      _targetOffset = Offset(widget.roll * 2.5, widget.pitch * 2.5);
      _animation = Tween<Offset>(begin: _currentOffset, end: _targetOffset).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            size: const Size(300, 300),
            painter: LevelGridPainter(),
          ),
        ),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            return Transform.translate(
              offset: _animation.value,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.cyan,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan,
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Container(
          width: 6,
          height: 6,
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
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);

    // Simplified grid - major lines only
    for (int i = -2; i <= 2; i++) {
      if (i == 0) continue; // Skip center lines, drawn separately
      final y = center.dy + i * 30;
      final x = center.dx + i * 30;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Center cross
    paint.strokeWidth = 2;
    paint.color = Colors.white.withOpacity(0.3);
    canvas.drawLine(
      Offset(center.dx - 40, center.dy),
      Offset(center.dx + 40, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 40),
      Offset(center.dx, center.dy + 40),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}