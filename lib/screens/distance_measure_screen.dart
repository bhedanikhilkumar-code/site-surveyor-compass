import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gps_service.dart';
import '../utils/geo_utils.dart';

class DistanceMeasureScreen extends StatefulWidget {
  const DistanceMeasureScreen({Key? key}) : super(key: key);

  @override
  State<DistanceMeasureScreen> createState() => _DistanceMeasureScreenState();
}

class _DistanceMeasureScreenState extends State<DistanceMeasureScreen> {
  final List<_MeasurePoint> _points = [];
  double _totalDistance = 0;
  bool _isMeasuring = false;

  void _addPoint() {
    final gps = context.read<GpsService>();
    if (gps.latitude == null || gps.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS not available')),
      );
      return;
    }

    setState(() {
      _points.add(_MeasurePoint(
        latitude: gps.latitude!,
        longitude: gps.longitude!,
        altitude: gps.altitude ?? 0,
        timestamp: DateTime.now(),
      ));

      if (_points.length >= 2) {
        final last = _points[_points.length - 1];
        final prev = _points[_points.length - 2];
        _totalDistance += GeoUtils.calculateDistance(
          prev.latitude, prev.longitude,
          last.latitude, last.longitude,
        );
      }
      _isMeasuring = true;
    });
  }

  void _reset() {
    setState(() {
      _points.clear();
      _totalDistance = 0;
      _isMeasuring = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Distance Measurement'),
        elevation: 0,
        actions: [
          if (_points.isNotEmpty)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
        ],
      ),
      body: Column(
        children: [
          // Distance display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Colors.grey[900],
            child: Column(
              children: [
                Text(
                  GeoUtils.formatDistance(_totalDistance),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.cyan),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_points.length} points',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                if (_points.length >= 2) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Rise: ${(_points.last.altitude - _points.first.altitude).toStringAsFixed(1)}m',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ],
            ),
          ),
          // Points list
          Expanded(
            child: _points.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.straighten, size: 80, color: Colors.grey[700]),
                        const SizedBox(height: 16),
                        Text('Tap + to mark points',
                            style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _points.length,
                    itemBuilder: (context, index) {
                      final point = _points[index];
                      final segDist = index > 0
                          ? GeoUtils.calculateDistance(
                              _points[index - 1].latitude, _points[index - 1].longitude,
                              point.latitude, point.longitude,
                            )
                          : 0.0;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: index == 0 ? Colors.green : Colors.cyan,
                          child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        title: Text(
                          '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        subtitle: Text(
                          'Alt: ${point.altitude.toStringAsFixed(1)}m${segDist > 0 ? ' | +${GeoUtils.formatDistance(segDist)}' : ''}',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        trailing: index > 0
                            ? Text(GeoUtils.formatDistance(segDist),
                                style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold))
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPoint,
        backgroundColor: _isMeasuring ? Colors.orange : Colors.cyan,
        icon: Icon(_isMeasuring ? Icons.add_location : Icons.my_location),
        label: Text(_isMeasuring ? 'Add Point' : 'Start'),
      ),
    );
  }
}

class _MeasurePoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final DateTime timestamp;

  _MeasurePoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.timestamp,
  });
}
