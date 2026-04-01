import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/track_model.dart';
import '../services/gps_service.dart';
import '../services/track_service.dart';
import '../utils/geo_utils.dart';

class TrackRecordingScreen extends StatefulWidget {
  const TrackRecordingScreen({Key? key}) : super(key: key);

  @override
  State<TrackRecordingScreen> createState() => _TrackRecordingScreenState();
}

class _TrackRecordingScreenState extends State<TrackRecordingScreen> {
  final TrackService _trackService = TrackService();
  final MapController _mapController = MapController();
  bool _isRecording = false;
  String _recordingTime = '00:00:00';
  double _totalDistance = 0.0;
  int _pointCount = 0;
  Timer? _timer;
  DateTime? _startTime;
  final List<TrackPoint> _recordedPoints = [];
  List<Track> _savedTracks = [];

  @override
  void initState() {
    super.initState();
    _initTrackService();
  }

  Future<void> _initTrackService() async {
    await _trackService.initialize();
    final tracks = await _trackService.getTracksSortedByDate();
    if (mounted) setState(() => _savedTracks = tracks);
  }

  void _startRecording() {
    final name = 'Track ${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
    _trackService.startRecording(name: name);
    setState(() {
      _isRecording = true;
      _startTime = DateTime.now();
      _totalDistance = 0.0;
      _pointCount = 0;
      _recordedPoints.clear();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null) {
        final elapsed = DateTime.now().difference(_startTime!);
        setState(() {
          _recordingTime = '${elapsed.inHours.toString().padLeft(2, '0')}:'
              '${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}:'
              '${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
        });
      }
    });
  }

  void _addPoint(GpsService gps) {
    if (!_isRecording || gps.latitude == null || gps.longitude == null) return;
    final point = TrackPoint(
      latitude: gps.latitude!,
      longitude: gps.longitude!,
      altitude: gps.altitude ?? 0,
      timestamp: DateTime.now(),
      speed: gps.speed,
      accuracy: gps.accuracy,
    );
    _trackService.addPoint(point);
    setState(() {
      _recordedPoints.add(point);
      _pointCount = _recordedPoints.length;
      _totalDistance = _trackService.currentDistance;
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final track = await _trackService.stopRecording();
    setState(() {
      _isRecording = false;
      _recordingTime = '00:00:00';
    });
    if (track != null && mounted) {
      final tracks = await _trackService.getTracksSortedByDate();
      setState(() => _savedTracks = tracks);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Track "${track.name}" saved (${GeoUtils.formatDistance(track.totalDistance)})')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Recording'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showTrackHistory,
          ),
        ],
      ),
      body: Consumer<GpsService>(
        builder: (context, gps, _) {
          final lat = gps.latitude;
          final lng = gps.longitude;
          final hasLocation = lat != null && lng != null;

          if (_isRecording && hasLocation) {
            _addPoint(gps);
          }

          return Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: hasLocation ? LatLng(lat, lng) : const LatLng(28.6139, 77.2090),
                    initialZoom: 17,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.surveyor.compass',
                    ),
                    if (_recordedPoints.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _recordedPoints.map((p) => LatLng(p.latitude, p.longitude)).toList(),
                            color: Colors.cyan,
                            strokeWidth: 4.0,
                          ),
                        ],
                      ),
                    if (hasLocation)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(lat, lng),
                            width: 30,
                            height: 30,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isRecording ? Colors.red.withOpacity(0.8) : Colors.blue.withOpacity(0.8),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Center(
                                child: Icon(Icons.navigation, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              _buildRecordingPanel(hasLocation),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isRecording ? _stopRecording : _startRecording,
        backgroundColor: _isRecording ? Colors.red : Colors.green,
        icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
        label: Text(_isRecording ? 'Stop' : 'Start Recording'),
      ),
    );
  }

  Widget _buildRecordingPanel(bool hasLocation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _panelStat(Icons.timer, _recordingTime, 'Time', _isRecording ? Colors.red : Colors.grey),
          _panelStat(Icons.straighten, GeoUtils.formatDistance(_totalDistance), 'Distance', Colors.cyan),
          _panelStat(Icons.place, '$_pointCount', 'Points', Colors.orange),
          _panelStat(
            hasLocation ? Icons.gps_fixed : Icons.gps_off,
            hasLocation ? 'OK' : 'No GPS',
            'Status',
            hasLocation ? Colors.green : Colors.red,
          ),
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

  void _showTrackHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Saved Tracks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('${_savedTracks.length} tracks', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _savedTracks.length,
                itemBuilder: (context, index) {
                  final track = _savedTracks[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(int.parse(track.color.replaceFirst('#', '0xFF'))),
                      child: const Icon(Icons.timeline, color: Colors.white, size: 20),
                    ),
                    title: Text(track.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '${GeoUtils.formatDistance(track.totalDistance)} | ${track.points.length} pts | ${track.duration.inMinutes}min',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () async {
                        await _trackService.deleteTrack(track.id);
                        final tracks = await _trackService.getTracksSortedByDate();
                        if (mounted) setState(() => _savedTracks = tracks);
                        Navigator.pop(context);
                      },
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _viewTrackOnMap(track);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewTrackOnMap(Track track) {
    if (track.points.isEmpty) return;
    final points = track.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    setState(() {
      _recordedPoints.clear();
      _recordedPoints.addAll(track.points);
      _totalDistance = track.totalDistance;
      _pointCount = track.points.length;
    });

    if (points.length >= 2) {
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;
      for (final p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
      _mapController.move(center, 15);
    }
  }
}
