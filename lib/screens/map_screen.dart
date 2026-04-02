import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/gps_service.dart';
import '../services/api_waypoint_service.dart';
import '../services/track_service.dart';
import '../models/waypoint_model.dart';
import '../models/track_model.dart';
import '../utils/geo_utils.dart';
import 'navigate_waypoint_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TrackService _trackService = TrackService();
  bool _followUser = true;
  bool _showTracks = true;
  List<Waypoint> _waypoints = [];
  List<Track> _tracks = [];

  @override
  void initState() {
    super.initState();
    _loadWaypoints();
    _loadTracks();
  }

  Future<void> _loadWaypoints() async {
    final service = context.read<ApiWaypointService>();
    final waypoints = await service.getAllWaypoints();
    if (mounted) {
      setState(() => _waypoints = waypoints);
    }
  }

  Future<void> _loadTracks() async {
    await _trackService.initialize();
    final tracks = await _trackService.getAllTracks();
    if (mounted) {
      setState(() => _tracks = tracks);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showTracks ? Icons.timeline : Icons.timeline_outlined,
              color: _showTracks ? Colors.orange : Colors.grey,
            ),
            onPressed: () {
              setState(() => _showTracks = !_showTracks);
            },
            tooltip: 'Toggle tracks',
          ),
          IconButton(
            icon: Icon(
              _followUser ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: _followUser ? Colors.cyan : Colors.grey,
            ),
            onPressed: () {
              setState(() => _followUser = !_followUser);
              if (_followUser) {
                _centerOnUser();
              }
            },
            tooltip: 'Follow location',
          ),
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _showMapOptions,
            tooltip: 'Map options',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Offline map tiles download not implemented yet')),
              );
            },
            tooltip: 'Download offline tiles',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadWaypoints();
              _loadTracks();
            },
          ),
        ],
      ),
      body: Consumer<GpsService>(
        builder: (context, gpsService, _) {
          final lat = gpsService.latitude;
          final lng = gpsService.longitude;
          final hasLocation = lat != null && lng != null;

          if (_followUser && hasLocation) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _followUser) {
                _mapController.move(LatLng(lat, lng), _mapController.camera.zoom);
              }
            });
          }

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: hasLocation ? LatLng(lat, lng) : const LatLng(28.6139, 77.2090),
              initialZoom: 16,
              onTap: (_, __) {
                setState(() => _followUser = false);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.surveyor.compass',
              ),
              // Track polylines
              if (_showTracks)
                ..._tracks.where((t) => t.points.length >= 2).map((track) => PolylineLayer(
                  polylines: [
                    Polyline(
                      points: track.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
                      color: _parseColor(track.color).withOpacity(0.7),
                      strokeWidth: 3.0,
                    ),
                  ],
                )),
              // Waypoint markers
              MarkerLayer(
                markers: [
                  // Current position marker
                  if (hasLocation)
                    Marker(
                      point: LatLng(lat, lng),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.3),
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.navigation, color: Colors.blue, size: 20),
                        ),
                      ),
                    ),
                  // Waypoint markers
                  ..._waypoints.map((wp) => Marker(
                    point: LatLng(wp.latitude, wp.longitude),
                    width: 36,
                    height: 36,
                    child: GestureDetector(
                      onTap: () => _showWaypointOptions(wp),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.orange.withOpacity(0.8),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.location_on, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  )),
                ],
              ),
              // Info overlay
              if (hasLocation)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoItem(Icons.location_on, '${lat.toStringAsFixed(5)}', '${lng.toStringAsFixed(5)}'),
                        _infoItem(Icons.speed, '${gpsService.speed?.toStringAsFixed(1) ?? '--'}', 'km/h'),
                        _infoItem(Icons.height, '${gpsService.altitude?.toStringAsFixed(0) ?? '--'}', 'm'),
                        _infoItem(Icons.place, '${_waypoints.length}', 'wpts'),
                        _infoItem(Icons.timeline, '${_tracks.length}', 'tracks'),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'zoom_in',
            mini: true,
            onPressed: () {
              final zoom = _mapController.camera.zoom;
              _mapController.move(_mapController.camera.center, zoom + 1);
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoom_out',
            mini: true,
            onPressed: () {
              final zoom = _mapController.camera.zoom;
              _mapController.move(_mapController.camera.center, zoom - 1);
            },
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'center',
            onPressed: _centerOnUser,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String value, String unit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.cyan),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
        Text(unit, style: const TextStyle(fontSize: 9, color: Colors.white60)),
      ],
    );
  }

  void _centerOnUser() {
    final gpsService = context.read<GpsService>();
    if (gpsService.latitude != null && gpsService.longitude != null) {
      setState(() => _followUser = true);
      _mapController.move(
        LatLng(gpsService.latitude!, gpsService.longitude!),
        16,
      );
    }
  }

  void _showWaypointOptions(Waypoint waypoint) {
    final gpsService = context.read<GpsService>();
    final hasLocation = gpsService.latitude != null && gpsService.longitude != null;

    String distanceStr = '--';
    String bearingStr = '--';

    if (hasLocation) {
      final distance = GeoUtils.calculateDistance(
        gpsService.latitude!, gpsService.longitude!,
        waypoint.latitude, waypoint.longitude,
      );
      final bearing = GeoUtils.calculateBearing(
        gpsService.latitude!, gpsService.longitude!,
        waypoint.latitude, waypoint.longitude,
      );
      distanceStr = GeoUtils.formatDistance(distance);
      bearingStr = '${bearing.toStringAsFixed(1)}° ${GeoUtils.bearingToCompass(bearing)}';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(waypoint.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoItem(Icons.straighten, distanceStr, 'distance'),
                _infoItem(Icons.explore, bearingStr, 'bearing'),
                _infoItem(Icons.height, '${waypoint.altitude.toStringAsFixed(0)}m', 'alt'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NavigateWaypointScreen(waypoint: waypoint),
                        ),
                      );
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navigate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _mapController.move(LatLng(waypoint.latitude, waypoint.longitude), 18);
                    },
                    icon: const Icon(Icons.center_focus_strong),
                    label: const Text('Focus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMapOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.zoom_out_map),
              title: const Text('Show all waypoints'),
              onTap: () {
                Navigator.pop(context);
                _fitAllMarkers();
              },
            ),
            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('Center on my location'),
              onTap: () {
                Navigator.pop(context);
                _centerOnUser();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _fitAllMarkers() {
    if (_waypoints.isEmpty) return;

    final gpsService = context.read<GpsService>();
    final points = <LatLng>[
      ..._waypoints.map((wp) => LatLng(wp.latitude, wp.longitude)),
      if (gpsService.latitude != null && gpsService.longitude != null)
        LatLng(gpsService.latitude!, gpsService.longitude!),
    ];

    if (points.length < 2) return;

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

    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    // Calculate zoom level based on coordinate span
    // Each zoom level doubles the visible area; at zoom 0 the world is ~360° wide
    double zoom;
    if (maxDiff > 0) {
      zoom = (log(360 / maxDiff) / ln2).clamp(2.0, 18.0);
    } else {
      zoom = 16;
    }

    _mapController.move(center, zoom);
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.cyan;
    }
  }
}
