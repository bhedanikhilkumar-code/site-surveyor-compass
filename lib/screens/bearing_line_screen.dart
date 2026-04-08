import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/gps_service.dart';


class BearingLineScreen extends StatefulWidget {
  const BearingLineScreen({Key? key}) : super(key: key);

  @override
  State<BearingLineScreen> createState() => _BearingLineScreenState();
}

class _BearingLineScreenState extends State<BearingLineScreen> {
  final MapController _mapController = MapController();
  final _bearingController = TextEditingController(text: '90');
  final _distanceController = TextEditingController(text: '500');
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  LatLng? _startPoint;
  LatLng? _endPoint;
  List<LatLng> _boundaryPoints = [];
  final List<_BearingLine> _lines = [];

  void _setStartFromGps() {
    final gps = context.read<GpsService>();
    if (gps.latitude != null && gps.longitude != null) {
      setState(() {
        _startPoint = LatLng(gps.latitude!, gps.longitude!);
        _latController.text = gps.latitude!.toStringAsFixed(6);
        _lngController.text = gps.longitude!.toStringAsFixed(6);
      });
      _calculateEnd();
    }
  }

  void _setStartFromInput() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    if (lat != null && lng != null) {
      setState(() => _startPoint = LatLng(lat, lng));
      _calculateEnd();
    }
  }

  void _calculateEnd() {
    if (_startPoint == null) return;
    final bearing = double.tryParse(_bearingController.text) ?? 0;
    final distance = double.tryParse(_distanceController.text) ?? 100;

    final endLat = _calculateDestinationLat(_startPoint!.latitude, _startPoint!.longitude, bearing, distance);
    final endLng = _calculateDestinationLng(_startPoint!.latitude, _startPoint!.longitude, bearing, distance);

    setState(() {
      _endPoint = LatLng(endLat, endLng);
    });
  }

  void _addLine() {
    if (_startPoint == null || _endPoint == null) return;
    final bearing = double.tryParse(_bearingController.text) ?? 0;
    setState(() {
      _lines.add(_BearingLine(start: _startPoint!, end: _endPoint!, bearing: bearing));
    });
  }

  void _closeBoundary() {
    if (_lines.length < 2) return;
    final points = <LatLng>[];
    for (final line in _lines) {
      points.add(line.start);
    }
    setState(() => _boundaryPoints = points);
  }

  void _clearAll() {
    setState(() {
      _lines.clear();
      _boundaryPoints.clear();
      _startPoint = null;
      _endPoint = null;
    });
  }

  double _calculateDestinationLat(double lat, double lng, double bearingDeg, double distM) {
    final R = 6371000.0;
    final bearing = bearingDeg * pi / 180;
    final lat1 = lat * pi / 180;
    final lat2 = asin(sin(lat1) * cos(distM / R) + cos(lat1) * sin(distM / R) * cos(bearing));
    return lat2 * 180 / pi;
  }

  double _calculateDestinationLng(double lat, double lng, double bearingDeg, double distM) {
    final R = 6371000.0;
    final bearing = bearingDeg * pi / 180;
    final lat1 = lat * pi / 180;
    final lng1 = lng * pi / 180;
    final lat2 = asin(sin(lat1) * cos(distM / R) + cos(lat1) * sin(distM / R) * cos(bearing));
    final lng2 = lng1 + atan2(sin(bearing) * sin(distM / R) * cos(lat1), cos(distM / R) - sin(lat1) * sin(lat2));
    return lng2 * 180 / pi;
  }

  @override
  void dispose() {
    _bearingController.dispose();
    _distanceController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bearing Line Drawer'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _clearAll),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _startPoint ?? const LatLng(28.6139, 77.2090),
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.surveyor.compass',
                ),
                if (_boundaryPoints.length >= 3)
                  PolygonLayer(polygons: [
                    Polygon(points: _boundaryPoints, color: Colors.cyan.withOpacity(0.2), borderColor: Colors.cyan, borderStrokeWidth: 2),
                  ]),
                PolylineLayer(polylines: [
                  ..._lines.map((l) => Polyline(
                    points: [l.start, l.end],
                    color: Colors.orange,
                    strokeWidth: 3,
                  )),
                  if (_startPoint != null && _endPoint != null)
                    Polyline(points: [_startPoint!, _endPoint!], color: Colors.red, strokeWidth: 3),
                ]),
                MarkerLayer(markers: [
                  if (_startPoint != null)
                    Marker(point: _startPoint!, width: 30, height: 30, child: const Icon(Icons.location_on, color: Colors.green, size: 30)),
                  if (_endPoint != null)
                    Marker(point: _endPoint!, width: 20, height: 20, child: const Icon(Icons.place, color: Colors.red, size: 20)),
                ]),
              ],
            ),
          ),
          // Controls
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildField(_bearingController, 'Bearing °', Icons.explore)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildField(_distanceController, 'Distance m', Icons.straighten)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildField(_latController, 'Start Lat', Icons.location_on)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildField(_lngController, 'Start Lng', Icons.location_on)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _setStartFromGps,
                        icon: const Icon(Icons.gps_fixed, size: 16),
                        label: const Text('GPS Point'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _setStartFromInput,
                        icon: const Icon(Icons.edit_location, size: 16),
                        label: const Text('Manual'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _addLine,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Line'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.white),
                      ),
                    ),
                  ],
                ),
                if (_lines.length >= 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _closeBoundary,
                        icon: const Icon(Icons.crop_free, size: 16),
                        label: Text('Close Boundary (${_lines.length} lines)'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController c, String label, IconData icon) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 11),
        prefixIcon: Icon(icon, size: 16, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        isDense: true,
      ),
    );
  }
}

class _BearingLine {
  final LatLng start;
  final LatLng end;
  final double bearing;
  _BearingLine({required this.start, required this.end, required this.bearing});
}
