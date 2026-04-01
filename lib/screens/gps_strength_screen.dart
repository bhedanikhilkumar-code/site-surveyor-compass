import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../services/gps_service.dart';

class GpsStrengthScreen extends StatefulWidget {
  const GpsStrengthScreen({Key? key}) : super(key: key);

  @override
  State<GpsStrengthScreen> createState() => _GpsStrengthScreenState();
}

class _GpsStrengthScreenState extends State<GpsStrengthScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final List<double> _accuracyHistory = [];
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final gps = context.read<GpsService>();
      if (gps.accuracy != null && mounted) {
        setState(() {
          _accuracyHistory.add(gps.accuracy!);
          if (_accuracyHistory.length > 30) _accuracyHistory.removeAt(0);
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GPS Signal Strength'), elevation: 0),
      body: Consumer<GpsService>(
        builder: (context, gps, _) {
          final accuracy = gps.accuracy ?? 0;
          final quality = _getQuality(accuracy);
          final bars = _getBars(accuracy);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Signal strength visual
                Card(
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            return Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: quality.color.withOpacity(0.1 + _pulseController.value * 0.1),
                                border: Border.all(color: quality.color, width: 3),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    accuracy > 0 ? '±${accuracy.toStringAsFixed(1)}' : '--',
                                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: quality.color),
                                  ),
                                  Text('meters', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(quality.label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: quality.color)),
                        const SizedBox(height: 8),
                        // Signal bars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            return Container(
                              width: 16,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height: 20.0 + i * 10,
                              decoration: BoxDecoration(
                                color: i < bars ? quality.color : Colors.grey[800],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Stats
                Card(
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _statRow('Status', gps.isListening ? 'Active' : 'Inactive', gps.isListening ? Colors.green : Colors.red),
                        _statRow('Latitude', gps.latitude?.toStringAsFixed(6) ?? '--', Colors.cyan),
                        _statRow('Longitude', gps.longitude?.toStringAsFixed(6) ?? '--', Colors.cyan),
                        _statRow('Altitude', gps.altitude != null ? '${gps.altitude!.toStringAsFixed(1)} m' : '--', Colors.blue),
                        _statRow('Speed', gps.speed != null ? '${(gps.speed! * 3.6).toStringAsFixed(1)} km/h' : '--', Colors.orange),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Accuracy chart
                if (_accuracyHistory.length >= 2)
                  Card(
                    color: Colors.grey[900],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Accuracy History', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 100,
                            child: CustomPaint(
                              painter: _AccuracyChartPainter(history: _accuracyHistory),
                              size: const Size(double.infinity, 100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Tips
                Card(
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tips to Improve GPS:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _tip('Go outdoors with clear sky view'),
                        _tip('Avoid tall buildings and trees'),
                        _tip('Wait 30-60 seconds for better lock'),
                        _tip('Enable High Accuracy in phone settings'),
                        _tip('Keep phone steady and upright'),
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

  _GpsQuality _getQuality(double accuracy) {
    if (accuracy <= 0) return _GpsQuality('No Signal', Colors.red);
    if (accuracy <= 5) return _GpsQuality('Excellent', Colors.green);
    if (accuracy <= 10) return _GpsQuality('Good', Colors.lightGreen);
    if (accuracy <= 20) return _GpsQuality('Fair', Colors.yellow);
    if (accuracy <= 50) return _GpsQuality('Poor', Colors.orange);
    return _GpsQuality('Very Poor', Colors.red);
  }

  int _getBars(double accuracy) {
    if (accuracy <= 0) return 0;
    if (accuracy <= 5) return 5;
    if (accuracy <= 10) return 4;
    if (accuracy <= 20) return 3;
    if (accuracy <= 50) return 2;
    return 1;
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }
}

class _GpsQuality {
  final String label;
  final Color color;
  _GpsQuality(this.label, this.color);
}

class _AccuracyChartPainter extends CustomPainter {
  final List<double> history;
  _AccuracyChartPainter({required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final maxVal = history.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);
    final paint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < history.length; i++) {
      final x = i / (history.length - 1) * size.width;
      final y = size.height - (history[i] / maxVal * size.height);
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    canvas.drawPath(path, paint);

    // Average line
    final avg = history.reduce((a, b) => a + b) / history.length;
    final avgY = size.height - (avg / maxVal * size.height);
    canvas.drawLine(
      Offset(0, avgY),
      Offset(size.width, avgY),
      Paint()..color = Colors.orange.withOpacity(0.5)..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _AccuracyChartPainter old) => old.history.length != history.length;
}
