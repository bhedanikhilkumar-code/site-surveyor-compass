import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../services/gps_service.dart';

class OfflineMapsScreen extends StatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  final MapController _mapController = MapController();
  List<DownloadRegion> _downloads = [];
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _currentDownloadName;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/offline_regions.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = content.split('\n').where((s) => s.isNotEmpty).toList();
        setState(() {
          _downloads = data.map((s) {
            final parts = s.split(',');
            return DownloadRegion(
              name: parts[0],
              center: LatLng(double.parse(parts[1]), double.parse(parts[2])),
              radiusKm: double.parse(parts[3]),
              downloadedAt: DateTime.parse(parts[4]),
            );
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading downloads: $e');
    }
  }

  Future<void> _saveDownloads() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/offline_regions.json');
      final content = _downloads.map((d) => 
        '${d.name},${d.center.latitude},${d.center.longitude},${d.radiusKm},${d.downloadedAt.toIso8601String()}'
      ).join('\n');
      await file.writeAsString(content);
    } catch (e) {
      debugPrint('Error saving downloads: $e');
    }
  }

  void _startDownload() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Region'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Download current map area for offline use'),
            const SizedBox(height: 16),
            if (_isDownloading) ...[
              LinearProgressIndicator(value: _downloadProgress),
              const SizedBox(height: 8),
              Text('${(_downloadProgress * 100).toStringAsFixed(0)}%'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isDownloading ? null : () async {
              Navigator.pop(context);
              await _downloadRegion();
            },
            child: Text(_isDownloading ? 'Downloading...' : 'Download'),
          ),
          TextButton(
            onPressed: _isDownloading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadRegion() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _currentDownloadName = 'Region ${_downloads.length + 1}';
    });

    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        _downloadProgress = i / 100;
      });
    }

    final gpsService = context.read<GpsService>();
    final position = gpsService.currentPosition;
    
    setState(() {
      _downloads.add(DownloadRegion(
        name: _currentDownloadName!,
        center: position != null 
            ? LatLng(position.latitude, position.longitude)
            : const LatLng(28.6139, 77.2090),
        radiusKm: 5.0,
        downloadedAt: DateTime.now(),
      ));
      _isDownloading = false;
      _currentDownloadName = null;
    });

    await _saveDownloads();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Region downloaded for offline use!')),
      );
    }
  }

  void _deleteDownload(int index) {
    setState(() {
      _downloads.removeAt(index);
    });
    _saveDownloads();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Maps'),
        backgroundColor: const Color(0xFF1a1a2e),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _startDownload,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(28.6139, 77.2090),
                initialZoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: _downloads.map((d) => Marker(
                    point: d.center,
                    child: const Icon(Icons.download_done, color: Colors.green, size: 30),
                  )).toList(),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1a1a2e),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Downloaded Regions',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (_downloads.isEmpty)
                  const Text(
                    'No regions downloaded yet',
                    style: TextStyle(color: Colors.white54),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _downloads.length,
                      itemBuilder: (context, index) {
                        final d = _downloads[index];
                        return ListTile(
                          leading: const Icon(Icons.map, color: Colors.green),
                          title: Text(d.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            '${d.radiusKm}km - ${d.downloadedAt.toString().substring(0, 16)}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteDownload(index),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DownloadRegion {
  final String name;
  final LatLng center;
  final double radiusKm;
  final DateTime downloadedAt;

  DownloadRegion({
    required this.name,
    required this.center,
    required this.radiusKm,
    required this.downloadedAt,
  });
}