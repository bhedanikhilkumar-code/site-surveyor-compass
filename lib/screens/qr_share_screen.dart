import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/waypoint_model.dart';
import '../services/api_waypoint_service.dart';
import '../utils/geo_utils.dart';

class QrShareScreen extends StatefulWidget {
  const QrShareScreen({Key? key}) : super(key: key);

  @override
  State<QrShareScreen> createState() => _QrShareScreenState();
}

class _QrShareScreenState extends State<QrShareScreen> {
  List<Waypoint> _waypoints = [];
  Waypoint? _selectedWaypoint;
  String _qrData = '';

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

  void _selectWaypoint(Waypoint wp) {
    setState(() {
      _selectedWaypoint = wp;
      _qrData = 'GEO_WP:${wp.name}:${wp.latitude}:${wp.longitude}:${wp.altitude}:${wp.bearing}';
    });
  }

  void _shareAsText() {
    if (_selectedWaypoint == null) return;
    final wp = _selectedWaypoint!;
    Share.share(
      'Waypoint: ${wp.name}\n'
      'Lat: ${wp.latitude.toStringAsFixed(6)}\n'
      'Lng: ${wp.longitude.toStringAsFixed(6)}\n'
      'Alt: ${wp.altitude.toStringAsFixed(1)}m\n'
      'Bearing: ${wp.bearing.toStringAsFixed(1)}°\n'
      'Link: https://maps.google.com/?q=${wp.latitude},${wp.longitude}',
      subject: 'Waypoint: ${wp.name}',
    );
  }

  void _copyCoords() {
    if (_selectedWaypoint == null) return;
    final wp = _selectedWaypoint!;
    Clipboard.setData(ClipboardData(
      text: '${wp.latitude.toStringAsFixed(6)}, ${wp.longitude.toStringAsFixed(6)}',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coordinates copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Share'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // QR Code display
            if (_selectedWaypoint != null) ...[
              Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        _selectedWaypoint!.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(12),
                        child: QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_selectedWaypoint!.latitude.toStringAsFixed(6)}, ${_selectedWaypoint!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(color: Colors.cyan, fontFamily: 'monospace', fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _copyCoords,
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy'),
                          ),
                          FilledButton.icon(
                            onPressed: _shareAsText,
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text('Share'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Waypoint list
            const Text('Select a Waypoint', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            if (_waypoints.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('No waypoints available', style: TextStyle(color: Colors.grey[500])),
                ),
              )
            else
              ..._waypoints.map((wp) => Card(
                color: _selectedWaypoint?.id == wp.id ? Colors.cyan.withOpacity(0.2) : Colors.grey[900],
                child: ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: _selectedWaypoint?.id == wp.id ? Colors.cyan : Colors.grey,
                  ),
                  title: Text(wp.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${wp.latitude.toStringAsFixed(4)}, ${wp.longitude.toStringAsFixed(4)} | ${wp.altitude.toStringAsFixed(0)}m',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  trailing: _selectedWaypoint?.id == wp.id
                      ? const Icon(Icons.check_circle, color: Colors.cyan)
                      : null,
                  onTap: () => _selectWaypoint(wp),
                ),
              )),
          ],
        ),
      ),
    );
  }
}
