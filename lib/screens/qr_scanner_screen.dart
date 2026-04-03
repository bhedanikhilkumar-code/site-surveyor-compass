import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import '../models/waypoint_model.dart';
import '../services/api_waypoint_service.dart';
import '../services/gps_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  String? _lastScannedData;
  String? _scanResult;
  Waypoint? _importedWaypoint;
  bool _showScanner = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code == _lastScannedData) return;

    setState(() {
      _lastScannedData = code;
      _isProcessing = true;
      _showScanner = false;
    });

    controller.stop();

    _processScannedData(code);
  }

  Future<void> _processScannedData(String data) async {
    try {
      if (data.startsWith('GEO_WP:')) {
        final parts = data.split(':');
        if (parts.length >= 6) {
          final name = parts[1];
          final lat = double.tryParse(parts[2]);
          final lng = double.tryParse(parts[3]);
          final alt = double.tryParse(parts[4]);
          final bearing = double.tryParse(parts[5]);

          if (lat != null && lng != null) {
            final waypoint = Waypoint(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              latitude: lat,
              longitude: lng,
              altitude: alt ?? 0,
              bearing: bearing ?? 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            setState(() {
              _scanResult = 'Waypoint Scanned';
              _importedWaypoint = waypoint;
            });
            return;
          }
        }
      }

      if (data.startsWith('geo:')) {
        final uri = Uri.parse(data);
        final lat = double.tryParse(uri.queryParameters['q']?.split(',')[0] ?? '');
        final lng = double.tryParse(uri.queryParameters['q']?.split(',')[1] ?? '');

        if (lat != null && lng != null) {
          final waypoint = Waypoint(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: 'Scanned Location',
            latitude: lat,
            longitude: lng,
            altitude: 0,
            bearing: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          setState(() {
            _scanResult = 'Location Scanned';
            _importedWaypoint = waypoint;
          });
          return;
        }
      }

      setState(() {
        _scanResult = data;
        _importedWaypoint = null;
      });
    } catch (e) {
      setState(() {
        _scanResult = 'Error: $e';
        _importedWaypoint = null;
      });
    }
  }

  Future<void> _saveWaypoint() async {
    if (_importedWaypoint == null) return;

    try {
      final service = context.read<ApiWaypointService>();
      await service.createWaypoint(
        name: _importedWaypoint!.name,
        bearing: _importedWaypoint!.bearing,
        latitude: _importedWaypoint!.latitude,
        longitude: _importedWaypoint!.longitude,
        altitude: _importedWaypoint!.altitude ?? 0,
        notes: _importedWaypoint!.notes ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waypoint saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyToClipboard() {
    if (_scanResult != null) {
      Clipboard.setData(ClipboardData(text: _scanResult!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }
  }

  void _resetScanner() {
    setState(() {
      _showScanner = true;
      _scanResult = null;
      _importedWaypoint = null;
      _lastScannedData = null;
      _isProcessing = false;
    });
    controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
        elevation: 0,
        actions: [
          if (!_showScanner)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetScanner,
              tooltip: 'Scan Again',
            ),
        ],
      ),
      body: _showScanner ? _buildScannerView() : _buildResultView(),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: _handleBarcode,
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
          child: Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyan, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, size: 64, color: Colors.cyan.withOpacity(0.8)),
                  const SizedBox(height: 16),
                  const Text(
                    'Point camera at QR code',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              const Text(
                'Supports: GeoCompass waypoints, geo: URIs, plain text',
                style: TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.grey[900],
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        _scanResult ?? 'No data',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_importedWaypoint != null) ...[
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text(
                      'Waypoint Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyan),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Name', _importedWaypoint!.name),
                    _buildDetailRow('Latitude', _importedWaypoint!.latitude.toStringAsFixed(6)),
                    _buildDetailRow('Longitude', _importedWaypoint!.longitude.toStringAsFixed(6)),
                    _buildDetailRow('Altitude', '${_importedWaypoint!.altitude.toStringAsFixed(1)} m'),
                    _buildDetailRow('Bearing', '${_importedWaypoint!.bearing.toStringAsFixed(1)}°'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _saveWaypoint,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Waypoint'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final url = 'https://maps.google.com/?q=${_importedWaypoint!.latitude},${_importedWaypoint!.longitude}';
                              SystemChrome.setApplicationSwitcherDescription(
                                ApplicationSwitcherDescription(
                                  label: 'Opening Maps',
                                  primaryColor: 0xFF000000,
                                ),
                              );
                            },
                            icon: const Icon(Icons.map),
                            label: const Text('View on Map'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_importedWaypoint == null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copyToClipboard,
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _resetScanner,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Another Code'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
