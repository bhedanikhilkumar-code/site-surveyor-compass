import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gps_service.dart';
import '../services/waypoint_service.dart';
import '../models/waypoint_model.dart';
import '../utils/geo_utils.dart';

class TerrainViewerScreen extends StatefulWidget {
  const TerrainViewerScreen({Key? key}) : super(key: key);

  @override
  State<TerrainViewerScreen> createState() => _TerrainViewerScreenState();
}

class _TerrainViewerScreenState extends State<TerrainViewerScreen> {
  List<Waypoint> _waypoints = [];
  double _rotationX = 0.6;
  double _rotationZ = 0.3;
  double _scale = 1.0;
  Offset _panOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadWaypoints();
  }

  Future<void> _loadWaypoints() async {
    final service = WaypointService();
    await service.initialize();
    final wps = await service.getAllWaypoints();
    if (mounted) setState(() => _waypoints = wps);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Terrain Viewer'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWaypoints,
          ),
        ],
      ),
      body: GestureDetector(
        onScaleUpdate: (details) {
          setState(() {
            _rotationZ += details.focalPointDelta.dx * 0.005;
            _rotationX -= details.focalPointDelta.dy * 0.005;
            _rotationX = _rotationX.clamp(0.1, 1.5);
            _scale = (_scale * details.scale).clamp(0.3, 3.0);
          });
        },
        child: Container(
          color: Colors.black,
          child: CustomPaint(
            painter: _Terrain3DPainter(
              waypoints: _waypoints,
              rotationX: _rotationX,
              rotationZ: _rotationZ,
              scale: _scale,
            ),
            size: Size.infinite,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.grey[900],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _infoChip('${_waypoints.length} points', Colors.cyan),
            _infoChip('Pinch to zoom', Colors.grey),
            _infoChip('Drag to rotate', Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontSize: 11));
  }
}

class _Terrain3DPainter extends CustomPainter {
  final List<Waypoint> waypoints;
  final double rotationX;
  final double rotationZ;
  final double scale;

  _Terrain3DPainter({
    required this.waypoints,
    required this.rotationX,
    required this.rotationZ,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waypoints.isEmpty) {
      final tp = TextPainter(
        text: const TextSpan(text: 'No waypoints to display\nAdd waypoints first', style: TextStyle(color: Colors.grey, fontSize: 16)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height / 2 - tp.height / 2));
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx, center.dy);

    // Find bounds
    double minLat = waypoints.first.latitude, maxLat = waypoints.first.latitude;
    double minLng = waypoints.first.longitude, maxLng = waypoints.first.longitude;
    double minAlt = waypoints.first.altitude, maxAlt = waypoints.first.altitude;

    for (final wp in waypoints) {
      if (wp.latitude < minLat) minLat = wp.latitude;
      if (wp.latitude > maxLat) maxLat = wp.latitude;
      if (wp.longitude < minLng) minLng = wp.longitude;
      if (wp.longitude > maxLng) maxLng = wp.longitude;
      if (wp.altitude < minAlt) minAlt = wp.altitude;
      if (wp.altitude > maxAlt) maxAlt = wp.altitude;
    }

    final latRange = (maxLat - minLat).abs() + 0.0001;
    final lngRange = (maxLng - minLng).abs() + 0.0001;
    final altRange = (maxAlt - minAlt).abs() + 1.0;
    final range = max(latRange, lngRange);
    final displayScale = (min(size.width, size.height) * 0.35) / range * scale;

    // Project 3D to 2D
    Offset project(double x, double y, double z) {
      final cosX = cos(rotationX), sinX = sin(rotationX);
      final cosZ = cos(rotationZ), sinZ = sin(rotationZ);

      final rx = x * cosZ - y * sinZ;
      final ry = x * sinZ + y * cosZ;
      final rz = z;

      final ry2 = ry * cosX - rz * sinX;
      final rz2 = ry * sinX + rz * cosX;

      final perspective = 500.0 / (500.0 + rz2);
      return Offset(rx * displayScale * perspective, -ry2 * displayScale * perspective * 0.6);
    }

    // Normalize and project all points
    final points = waypoints.map((wp) {
      final x = (wp.longitude - (minLng + maxLng) / 2) / range;
      final y = (wp.latitude - (minLat + maxLat) / 2) / range;
      final z = (wp.altitude - minAlt) / altRange;
      return {'pos': project(x, y, z), 'wp': wp, 'z': z};
    }).toList();

    // Sort by z-depth for proper rendering
    points.sort((a, b) {
      final az = (a['pos'] as Offset).dy;
      final bz = (b['pos'] as Offset).dy;
      return az.compareTo(bz);
    });

    // Draw grid floor
    final gridPaint = Paint()..color = Colors.cyan.withOpacity(0.1)..strokeWidth = 0.5;
    for (double i = -1; i <= 1; i += 0.2) {
      final start = project(i, -1, 0);
      final end = project(i, 1, 0);
      canvas.drawLine(start, end, gridPaint);
      final start2 = project(-1, i, 0);
      final end2 = project(1, i, 0);
      canvas.drawLine(start2, end2, gridPaint);
    }

    // Draw connections between nearest points
    final linePaint = Paint()..color = Colors.cyan.withOpacity(0.3)..strokeWidth = 1;
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final p1 = points[i]['pos'] as Offset;
        final p2 = points[j]['pos'] as Offset;
        if ((p1 - p2).distance < 100) {
          canvas.drawLine(p1, p2, linePaint);
        }
      }
    }

    // Draw points with height-based coloring
    for (final point in points) {
      final pos = point['pos'] as Offset;
      final z = point['z'] as double;
      final wp = point['wp'] as Waypoint;

      // Color based on height: blue (low) -> green -> red (high)
      final color = Color.lerp(Colors.blue, Colors.red, z)!;

      // Draw vertical line from ground
      final groundPos = project(
        (wp.longitude - (minLng + maxLng) / 2) / range,
        (wp.latitude - (minLat + maxLat) / 2) / range,
        0,
      );
      canvas.drawLine(
        pos,
        groundPos,
        Paint()..color = color.withOpacity(0.4)..strokeWidth = 1,
      );

      // Draw point
      canvas.drawCircle(pos, 6, Paint()..color = color);
      canvas.drawCircle(pos, 6, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1);

      // Draw label
      final tp = TextPainter(
        text: TextSpan(
          text: '${wp.name}\n${wp.altitude.toStringAsFixed(1)}m',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx + 8, pos.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _Terrain3DPainter old) =>
      old.rotationX != rotationX || old.rotationZ != rotationZ || old.scale != scale || old.waypoints.length != waypoints.length;
}
