import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/compass_provider.dart';


class HeightMeasureScreen extends StatefulWidget {
  const HeightMeasureScreen({Key? key}) : super(key: key);

  @override
  State<HeightMeasureScreen> createState() => _HeightMeasureScreenState();
}

class _HeightMeasureScreenState extends State<HeightMeasureScreen> {
  final _distanceController = TextEditingController();
  double _estimatedHeight = 0;
  double _currentAngle = 0;
  bool _angleLocked = false;
  double _lockedAngle = 0;
  double _lockedDistance = 0;

  @override
  void initState() {
    super.initState();
    _distanceController.text = '10';
  }

  void _lockAngle() {
    final compass = context.read<CompassProvider>();
    final dist = double.tryParse(_distanceController.text) ?? 10;
    setState(() {
      _angleLocked = true;
      _lockedAngle = compass.pitch;
      _lockedDistance = dist;
      _estimatedHeight = dist * tan(_lockedAngle.abs() * pi / 180);
    });
  }

  void _unlock() {
    setState(() => _angleLocked = false);
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Height Measurement'), elevation: 0),
      body: Consumer<CompassProvider>(
        builder: (context, compass, _) {
          _currentAngle = compass.pitch;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Visual angle indicator
                Card(
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: CustomPaint(
                            painter: _AnglePainter(
                              angle: _angleLocked ? _lockedAngle : _currentAngle,
                              isLocked: _angleLocked,
                            ),
                            size: const Size(double.infinity, 200),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${(_angleLocked ? _lockedAngle : _currentAngle).toStringAsFixed(1)}°',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: _angleLocked ? Colors.green : Colors.cyan,
                          ),
                        ),
                        Text(
                          _angleLocked ? 'Angle Locked' : 'Tilt phone to aim top of object',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Distance input
                Card(
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.straighten, color: Colors.cyan),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _distanceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                            decoration: InputDecoration(
                              labelText: 'Distance from base (meters)',
                              labelStyle: TextStyle(color: Colors.grey[500]),
                              filled: true,
                              fillColor: Colors.grey[850],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Lock/Unlock button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _angleLocked ? _unlock : _lockAngle,
                    icon: Icon(_angleLocked ? Icons.lock_open : Icons.lock),
                    label: Text(_angleLocked ? 'Unlock & Re-measure' : 'Lock Angle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _angleLocked ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Result
                if (_angleLocked && _estimatedHeight > 0)
                  Card(
                    color: Colors.green.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.height, size: 40, color: Colors.green),
                          const SizedBox(height: 8),
                          const Text('Estimated Height', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          Text(
                            '${_estimatedHeight.toStringAsFixed(2)} m',
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Distance: ${_lockedDistance.toStringAsFixed(1)}m | Angle: ${_lockedAngle.abs().toStringAsFixed(1)}°',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                          Text(
                            'Formula: ${_lockedDistance.toStringAsFixed(1)} × tan(${_lockedAngle.abs().toStringAsFixed(1)}°) = ${_estimatedHeight.toStringAsFixed(2)}m',
                            style: TextStyle(color: Colors.grey[600], fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Instructions
                Card(
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('How to use:', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _instruction('1', 'Stand at a known distance from the object'),
                        _instruction('2', 'Point phone at the TOP of the object'),
                        _instruction('3', 'Tap "Lock Angle" to capture the angle'),
                        _instruction('4', 'Height is calculated automatically'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _instruction(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(radius: 10, backgroundColor: Colors.cyan, child: Text(num, style: const TextStyle(fontSize: 10, color: Colors.white))),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ],
      ),
    );
  }
}

class _AnglePainter extends CustomPainter {
  final double angle;
  final bool isLocked;

  _AnglePainter({required this.angle, required this.isLocked});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.8);
    final paint = Paint()
      ..color = isLocked ? Colors.green : Colors.cyan
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw ground line
    canvas.drawLine(
      Offset(20, center.dy),
      Offset(size.width - 20, center.dy),
      Paint()..color = Colors.grey.withOpacity(0.5)..strokeWidth = 1,
    );

    // Draw angle line
    final rad = -angle.abs() * pi / 180;
    final length = 120.0;
    final endX = center.dx + length * cos(rad);
    final endY = center.dy + length * sin(rad);
    canvas.drawLine(center, Offset(endX, endY), paint);

    // Draw vertical reference
    canvas.drawLine(
      center,
      Offset(center.dx, center.dy - length),
      Paint()..color = Colors.grey.withOpacity(0.3)..strokeWidth = 1..strokeCap = StrokeCap.round,
    );

    // Draw angle arc
    final arcPaint = Paint()
      ..color = (isLocked ? Colors.green : Colors.cyan).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Rect.fromCenter(center: center, width: 60, height: 60);
    canvas.drawArc(rect, -pi / 2, rad, false, arcPaint);

    // Draw object silhouette
    final objectPaint = Paint()..color = Colors.orange.withOpacity(0.5)..strokeWidth = 2;
    final objX = center.dx + 100;
    canvas.drawLine(Offset(objX, center.dy), Offset(objX, center.dy - 150), objectPaint);

    // Label
    final tp = TextPainter(
      text: TextSpan(text: 'OBJECT', style: TextStyle(color: Colors.orange.withOpacity(0.7), fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(objX - tp.width / 2, center.dy - 165));
  }

  @override
  bool shouldRepaint(covariant _AnglePainter old) => old.angle != angle || old.isLocked != isLocked;
}
