import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

class GeofencingScreen extends StatefulWidget {
  const GeofencingScreen({super.key});

  @override
  State<GeofencingScreen> createState() => _GeofencingScreenState();
}

class _GeofencingScreenState extends State<GeofencingScreen> {
  final List<GeofenceZone> _zones = [];
  final _uuid = const Uuid();
  bool _isMonitoring = false;
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
  }

  Future<void> _getCurrentPosition() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('Error getting position: $e');
    }
  }

  void _startMonitoring() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services disabled')),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    setState(() => _isMonitoring = true);

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((position) {
      setState(() => _currentPosition = position);
      _checkGeofences(position);
    });
  }

  void _stopMonitoring() {
    _positionSubscription?.cancel();
    setState(() => _isMonitoring = false);
  }

  void _checkGeofences(Position position) {
    for (final zone in _zones) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );

      if (distance <= zone.radiusMeters) {
        if (!zone.isInside) {
          _showAlert('Entered ${zone.name}', 'You have entered the geofence zone');
          setState(() {
            final index = _zones.indexOf(zone);
            _zones[index].isInside = true;
          });
        }
      } else {
        if (zone.isInside) {
          _showAlert('Exited ${zone.name}', 'You have left the geofence zone');
          setState(() {
            final index = _zones.indexOf(zone);
            _zones[index].isInside = false;
          });
        }
      }
    }
  }

  void _showAlert(String title, String body) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _addZone() async {
    final currentPos = await Geolocator.getCurrentPosition();
    
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final radiusController = TextEditingController(text: '100');
        return AlertDialog(
          title: const Text('Add Geofence Zone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Zone Name')),
              const SizedBox(height: 8),
              TextField(controller: radiusController, decoration: const InputDecoration(labelText: 'Radius (meters)'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _zones.add(GeofenceZone(
                      id: _uuid.v4(),
                      name: nameController.text,
                      latitude: currentPos.latitude,
                      longitude: currentPos.longitude,
                      radiusMeters: double.tryParse(radiusController.text) ?? 100,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add at Current Location'),
            ),
          ],
        );
      },
    );
  }

  void _deleteZone(String id) {
    setState(() => _zones.removeWhere((z) => z.id == id));
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofencing'),
        backgroundColor: const Color(0xFF1a1a2e),
        actions: [
          IconButton(
            icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
            onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: _addZone),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: _isMonitoring ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              child: Row(
                children: [
                  Icon(_isMonitoring ? Icons.gps_fixed : Icons.gps_off, color: _isMonitoring ? Colors.green : Colors.red),
                  const SizedBox(width: 12),
                  Text(
                    _isMonitoring ? 'Monitoring Active' : 'Monitoring Stopped',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  if (_currentPosition != null) ...[
                    const Spacer(),
                    Text(
                      'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _zones.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off, size: 64, color: Colors.white38),
                          SizedBox(height: 16),
                          Text('No geofence zones', style: TextStyle(color: Colors.white54, fontSize: 16)),
                          SizedBox(height: 8),
                          Text('Tap + to add a zone', style: TextStyle(color: Colors.white38)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _zones.length,
                      itemBuilder: (context, index) {
                        final zone = _zones[index];
                        return Card(
                          color: Colors.white.withOpacity(0.1),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(
                              zone.isInside ? Icons.check_circle : Icons.location_on,
                              color: zone.isInside ? Colors.green : Colors.cyanAccent,
                            ),
                            title: Text(zone.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${zone.radiusMeters}m radius',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteZone(zone.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class GeofenceZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  bool isInside;

  GeofenceZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.isInside = false,
  });
}