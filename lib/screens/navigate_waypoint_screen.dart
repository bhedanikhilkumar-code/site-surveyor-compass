import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/waypoint_model.dart';
import '../services/gps_service.dart';
import '../providers/compass_provider.dart';
import '../utils/geo_utils.dart';

class NavigateWaypointScreen extends StatefulWidget {
  final Waypoint waypoint;

  const NavigateWaypointScreen({Key? key, required this.waypoint}) : super(key: key);

  @override
  State<NavigateWaypointScreen> createState() => _NavigateWaypointScreenState();
}

class _NavigateWaypointScreenState extends State<NavigateWaypointScreen> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Navigate to ${widget.waypoint.name}'),
        elevation: 0,
      ),
      body: Consumer2<GpsService, CompassProvider>(
        builder: (context, gpsService, compass, _) {
          final lat = gpsService.latitude;
          final lng = gpsService.longitude;
          final hasLocation = lat != null && lng != null;

          if (!hasLocation) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Waiting for GPS lock...'),
                ],
              ),
            );
          }

          final distance = GeoUtils.calculateDistance(
            lat, lng,
            widget.waypoint.latitude, widget.waypoint.longitude,
          );
          final bearing = GeoUtils.calculateBearing(
            lat, lng,
            widget.waypoint.latitude, widget.waypoint.longitude,
          );
          final compassHeading = compass.trueBearing.isNaN ? 0.0 : compass.trueBearing;
          final relativeBearing = (bearing - compassHeading + 360) % 360;
          final elevationDiff = widget.waypoint.altitude - (gpsService.altitude ?? 0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Navigation compass
                SizedBox(
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[700]!, width: 2),
                        ),
                      ),
                      // Direction arrow
                      Transform.rotate(
                        angle: relativeBearing * 3.14159 / 180,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.navigation, size: 80, color: Colors.cyan),
                            SizedBox(height: 4),
                          ],
                        ),
                      ),
                      // Center info
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 50),
                          Text(
                            '${bearing.toStringAsFixed(0)}°',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            GeoUtils.bearingToCompass(bearing),
                            style: const TextStyle(fontSize: 14, color: Colors.cyan),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Waypoint info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.waypoint.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statCard(
                            Icons.straighten,
                            GeoUtils.formatDistance(distance),
                            'Distance',
                            Colors.cyan,
                          ),
                          _statCard(
                            Icons.explore,
                            '${bearing.toStringAsFixed(1)}°',
                            'Bearing',
                            Colors.orange,
                          ),
                          _statCard(
                            Icons.height,
                            '${elevationDiff >= 0 ? '+' : ''}${elevationDiff.toStringAsFixed(0)}m',
                            'Elevation',
                            elevationDiff >= 0 ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Destination details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Destination',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      _detailRow('Latitude', widget.waypoint.latitude.toStringAsFixed(6)),
                      _detailRow('Longitude', widget.waypoint.longitude.toStringAsFixed(6)),
                      _detailRow('Altitude', '${widget.waypoint.altitude.toStringAsFixed(1)} m'),
                      if (widget.waypoint.notes.isNotEmpty)
                        _detailRow('Notes', widget.waypoint.notes),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Current position
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Position',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      _detailRow('Latitude', lat.toStringAsFixed(6)),
                      _detailRow('Longitude', lng.toStringAsFixed(6)),
                      _detailRow('Altitude', '${(gpsService.altitude ?? 0).toStringAsFixed(1)} m'),
                      _detailRow('Heading', '${compassHeading.toStringAsFixed(1)}° ${GeoUtils.bearingToCompass(compassHeading)}'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
