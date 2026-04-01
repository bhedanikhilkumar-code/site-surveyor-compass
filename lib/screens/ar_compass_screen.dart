import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/waypoint_model.dart';
import '../providers/compass_provider.dart';
import '../services/gps_service.dart';
import '../services/api_waypoint_service.dart';
import '../utils/geo_utils.dart';

class ArCompassScreen extends StatefulWidget {
  const ArCompassScreen({Key? key}) : super(key: key);

  @override
  State<ArCompassScreen> createState() => _ArCompassScreenState();
}

class _ArCompassScreenState extends State<ArCompassScreen> {
  List<Waypoint> _waypoints = [];

  @override
  void initState() {
    super.initState();
    _loadWaypoints();
  }

  Future<void> _loadWaypoints() async {
    final service = context.read<ApiWaypointService>();
    final waypoints = await service.getAllWaypoints();
    if (mounted) setState(() => _waypoints = waypoints);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Compass AR'),
        backgroundColor: Colors.black54,
        elevation: 0,
      ),
      body: Consumer2<CompassProvider, GpsService>(
        builder: (context, compass, gps, _) {
          final heading = compass.trueBearing;
          final hasLocation = gps.latitude != null && gps.longitude != null;

          if (!hasLocation) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.cyan),
                  SizedBox(height: 16),
                  Text('Waiting for GPS...', style: TextStyle(color: Colors.white)),
                ],
              ),
            );
          }

          final visibleWaypoints = _getVisibleWaypoints(gps, heading);

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey[900]!, Colors.black],
                  ),
                ),
              ),
              Center(
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
                  painter: ArCompassPainter(
                    heading: heading,
                    waypoints: visibleWaypoints,
                    userLat: gps.latitude!,
                    userLng: gps.longitude!,
                    userAltitude: gps.altitude ?? 0,
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoChip(Icons.explore, '${heading.toStringAsFixed(0)}°', GeoUtils.bearingToCompass(heading), Colors.cyan),
                      _infoChip(Icons.place, '${_waypoints.length}', 'waypoints', Colors.orange),
                      _infoChip(Icons.visibility, '${visibleWaypoints.length}', 'visible', Colors.green),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_VisibleWaypoint> _getVisibleWaypoints(GpsService gps, double heading) {
    if (gps.latitude == null || gps.longitude == null) return [];
    
    final visible = <_VisibleWaypoint>[];
    for (final wp in _waypoints) {
      final bearing = GeoUtils.calculateBearing(gps.latitude!, gps.longitude!, wp.latitude, wp.longitude);
      final distance = GeoUtils.calculateDistance(gps.latitude!, gps.longitude!, wp.latitude, wp.longitude);
      final relativeBearing = (bearing - heading + 360) % 360;
      
      if (relativeBearing <= 90 || relativeBearing >= 270) {
        visible.add(_VisibleWaypoint(
          waypoint: wp,
          bearing: bearing,
          distance: distance,
          relativeBearing: relativeBearing,
        ));
      }
    }
    visible.sort((a, b) => a.distance.compareTo(b.distance));
    return visible.take(10).toList();
  }

  Widget _infoChip(IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }
}

class _VisibleWaypoint {
  final Waypoint waypoint;
  final double bearing;
  final double distance;
  final double relativeBearing;

  _VisibleWaypoint({
    required this.waypoint,
    required this.bearing,
    required this.distance,
    required this.relativeBearing,
  });
}

class ArCompassPainter extends CustomPainter {
  final double heading;
  final List<_VisibleWaypoint> waypoints;
  final double userLat;
  final double userLng;
  final double userAltitude;

  ArCompassPainter({
    required this.heading,
    required this.waypoints,
    required this.userLat,
    required this.userLng,
    required this.userAltitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final topY = size.height * 0.3;

    final headingPaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final headingText = TextPainter(
      text: TextSpan(
        text: '${heading.toStringAsFixed(0)}° ${GeoUtils.bearingToCompass(heading)}',
        style: const TextStyle(color: Colors.cyan, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    headingText.paint(canvas, Offset(centerX - headingText.width / 2, topY - 60));

    final compassBarWidth = size.width * 0.8;
    final compassBarLeft = centerX - compassBarWidth / 2;
    final compassBarY = topY;

    canvas.drawLine(
      Offset(compassBarLeft, compassBarY),
      Offset(compassBarLeft + compassBarWidth, compassBarY),
      Paint()..color = Colors.white.withOpacity(0.3)..strokeWidth = 1,
    );

    final directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final dirBearings = [0, 45, 90, 135, 180, 225, 270, 315];

    for (int i = 0; i < directions.length; i++) {
      double diff = (dirBearings[i] - heading + 360) % 360;
      if (diff > 180) diff -= 360;
      
      if (diff.abs() <= 90) {
        final x = centerX + (diff / 90) * (compassBarWidth / 2);
        final isCardinal = dirBearings[i] % 90 == 0;
        
        final text = TextPainter(
          text: TextSpan(
            text: directions[i],
            style: TextStyle(
              color: dirBearings[i] == 0 ? Colors.red : Colors.white.withOpacity(0.8),
              fontSize: isCardinal ? 16 : 12,
              fontWeight: isCardinal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(canvas, Offset(x - text.width / 2, compassBarY + 8));
      }
    }

    for (final wp in waypoints) {
      double diff = (wp.bearing - heading + 360) % 360;
      if (diff > 180) diff -= 360;
      
      final x = centerX + (diff / 90) * (compassBarWidth / 2);
      if (x < compassBarLeft - 20 || x > compassBarLeft + compassBarWidth + 20) continue;

      final dotPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, compassBarY), 6, dotPaint);

      final linePaint = Paint()
        ..color = Colors.orange.withOpacity(0.5)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(x, compassBarY + 6), Offset(x, compassBarY + 40), linePaint);

      final nameText = TextPainter(
        text: TextSpan(
          text: wp.waypoint.name,
          style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      nameText.paint(canvas, Offset(x - nameText.width / 2, compassBarY + 42));

      final distText = TextPainter(
        text: TextSpan(
          text: GeoUtils.formatDistance(wp.distance),
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      distText.paint(canvas, Offset(x - distText.width / 2, compassBarY + 56));
    }

    final centerIndicator = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final trianglePath = Path();
    trianglePath.moveTo(centerX, compassBarY - 15);
    trianglePath.lineTo(centerX - 6, compassBarY - 25);
    trianglePath.lineTo(centerX + 6, compassBarY - 25);
    trianglePath.close();
    canvas.drawPath(trianglePath, centerIndicator);
  }

  @override
  bool shouldRepaint(covariant ArCompassPainter oldDelegate) {
    return oldDelegate.heading != heading || oldDelegate.waypoints != waypoints;
  }
}
