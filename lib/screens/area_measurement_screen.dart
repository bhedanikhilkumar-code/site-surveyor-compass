import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/gps_service.dart';
import '../services/waypoint_service.dart';
import '../models/waypoint_model.dart';
import '../utils/geo_utils.dart';

class AreaMeasurementScreen extends StatefulWidget {
  const AreaMeasurementScreen({Key? key}) : super(key: key);

  @override
  State<AreaMeasurementScreen> createState() => _AreaMeasurementScreenState();
}

class _AreaMeasurementScreenState extends State<AreaMeasurementScreen> {
  final MapController _mapController = MapController();
  final List<LatLng> _points = [];
  bool _isMeasuring = false;
  double _area = 0.0;
  double _perimeter = 0.0;
  List<Waypoint> _waypoints = [];

  void _addPoint(GpsService gps) {
    if (gps.latitude == null || gps.longitude == null) return;
    setState(() {
      _points.add(LatLng(gps.latitude!, gps.longitude!));
      _calculateArea();
    });
  }

  void _addPointAtLocation(LatLng point) {
    setState(() {
      _points.add(point);
      _calculateArea();
    });
  }

  void _removeLastPoint() {
    if (_points.isNotEmpty) {
      setState(() {
        _points.removeLast();
        _calculateArea();
      });
    }
  }

  void _clearAll() {
    setState(() {
      _points.clear();
      _calculateArea();
    });
  }

  Future<void> _loadWaypoints() async {
    final service = WaypointService();
    await service.initialize();
    final waypoints = await service.getAllWaypoints();
    setState(() => _waypoints = waypoints);
  }

  void _showWaypointSelector() async {
    await _loadWaypoints();
    if (_waypoints.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No waypoints available')),
        );
      }
      return;
    }

    final selectedWaypoints = await showDialog<List<Waypoint>>(
      context: context,
      builder: (context) => WaypointSelectorDialog(waypoints: _waypoints),
    );

    if (selectedWaypoints != null && selectedWaypoints.length >= 3) {
      setState(() {
        _points.clear();
        _points.addAll(selectedWaypoints.map((w) => LatLng(w.latitude, w.longitude)));
        _calculateArea();
      });
    } else if (selectedWaypoints != null && selectedWaypoints.length < 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least 3 waypoints for area calculation')),
        );
      }
    }
  }

  void _calculateArea() {
    if (_points.length < 3) {
      _area = 0.0;
      _perimeter = 0.0;
      return;
    }

    // FIX: Use spherical polygon area calculation for better accuracy
    // Convert to the format expected by GeoUtils
    final polygonPoints = _points.map((p) => {'lat': p.latitude, 'lon': p.longitude}).toList();
    _area = GeoUtils.calculatePolygonArea(polygonPoints);

    // Calculate perimeter
    double totalPerimeter = 0.0;
    for (int i = 0; i < _points.length; i++) {
      final j = (i + 1) % _points.length;
      totalPerimeter += GeoUtils.calculateDistance(
        _points[i].latitude, _points[i].longitude,
        _points[j].latitude, _points[j].longitude,
      );
    }
    _perimeter = totalPerimeter;
  }

  String _formatArea(double sqMeters) {
    if (sqMeters < 10000) {
      return '${sqMeters.toStringAsFixed(1)} m²';
    } else {
      return '${(sqMeters / 10000).toStringAsFixed(4)} ha';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Area Measurement'),
        elevation: 0,
        actions: [
          if (_points.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _removeLastPoint,
              tooltip: 'Remove last point',
            ),
          if (_points.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAll,
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: Consumer<GpsService>(
        builder: (context, gps, _) {
          final lat = gps.latitude;
          final lng = gps.longitude;
          final hasLocation = lat != null && lng != null;

          return Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: hasLocation ? LatLng(lat, lng) : const LatLng(28.6139, 77.2090),
                    initialZoom: 17,
                    onTap: (tapPosition, point) {
                      if (_isMeasuring) {
                        _addPointAtLocation(point);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.surveyor.compass',
                    ),
                    if (_points.length >= 3)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: [..._points, _points.first],
                            color: Colors.cyan.withOpacity(0.2),
                            borderColor: Colors.cyan,
                            borderStrokeWidth: 3.0,
                          ),
                        ],
                      ),
                    if (_points.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [..._points, if (_points.length >= 3) _points.first],
                            color: Colors.cyan,
                            strokeWidth: 3.0,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (hasLocation)
                          Marker(
                            point: LatLng(lat, lng),
                            width: 30,
                            height: 30,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withOpacity(0.8),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Center(child: Icon(Icons.navigation, color: Colors.white, size: 16)),
                            ),
                          ),
                        ..._points.asMap().entries.map((entry) => Marker(
                          point: entry.value,
                          width: 30,
                          height: 30,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange.withOpacity(0.9),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              _buildInfoPanel(hasLocation),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'load_waypoints',
            onPressed: _showWaypointSelector,
            backgroundColor: Colors.purple,
            child: const Icon(Icons.bookmark),
            tooltip: 'Load from Waypoints',
          ),
          const SizedBox(height: 8),
          if (_isMeasuring)
            Consumer<GpsService>(
              builder: (context, gps, _) => FloatingActionButton(
                heroTag: 'add_point',
                onPressed: () => _addPoint(gps),
                backgroundColor: Colors.orange,
                child: const Icon(Icons.add_location),
              ),
            ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'measure',
            onPressed: () => setState(() => _isMeasuring = !_isMeasuring),
            backgroundColor: _isMeasuring ? Colors.red : Colors.green,
            icon: Icon(_isMeasuring ? Icons.stop : Icons.crop_free),
            label: Text(_isMeasuring ? 'Stop' : 'Start Measuring'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(bool hasLocation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _panelStat(Icons.crop_free, _formatArea(_area), 'Area', Colors.cyan),
          _panelStat(Icons.straighten, GeoUtils.formatDistance(_perimeter), 'Perimeter', Colors.orange),
          _panelStat(Icons.place, '${_points.length}', 'Points', Colors.green),
        ],
      ),
    );
  }

  Widget _panelStat(IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }
}

class WaypointSelectorDialog extends StatefulWidget {
  final List<Waypoint> waypoints;

  const WaypointSelectorDialog({Key? key, required this.waypoints}) : super(key: key);

  @override
  State<WaypointSelectorDialog> createState() => _WaypointSelectorDialogState();
}

class _WaypointSelectorDialogState extends State<WaypointSelectorDialog> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Waypoints for Area'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: widget.waypoints.length,
          itemBuilder: (context, index) {
            final waypoint = widget.waypoints[index];
            final isSelected = _selectedIds.contains(waypoint.id);
            return CheckboxListTile(
              title: Text(waypoint.name),
              subtitle: Text('${waypoint.latitude.toStringAsFixed(6)}, ${waypoint.longitude.toStringAsFixed(6)}'),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(waypoint.id);
                  } else {
                    _selectedIds.remove(waypoint.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final selected = widget.waypoints.where((w) => _selectedIds.contains(w.id)).toList();
            Navigator.of(context).pop(selected);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
