import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/gps_service.dart';
import '../providers/compass_provider.dart';
import '../utils/geo_utils.dart';

class CameraGpsScreen extends StatefulWidget {
  const CameraGpsScreen({Key? key}) : super(key: key);

  @override
  State<CameraGpsScreen> createState() => _CameraGpsScreenState();
}

class _CameraGpsScreenState extends State<CameraGpsScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<TaggedPhoto> _photos = [];

  Future<void> _takePhoto() async {
    final gps = context.read<GpsService>();
    final compass = context.read<CompassProvider>();

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo == null || !mounted) return;

    final tagged = TaggedPhoto(
      file: File(photo.path),
      latitude: gps.latitude,
      longitude: gps.longitude,
      altitude: gps.altitude,
      bearing: compass.trueBearing,
      accuracy: gps.accuracy,
      timestamp: DateTime.now(),
    );

    setState(() => _photos.insert(0, tagged));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo captured with GPS tag')),
    );
  }

  Future<void> _pickFromGallery() async {
    final gps = context.read<GpsService>();
    final compass = context.read<CompassProvider>();

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (photo == null || !mounted) return;

    final tagged = TaggedPhoto(
      file: File(photo.path),
      latitude: gps.latitude,
      longitude: gps.longitude,
      altitude: gps.altitude,
      bearing: compass.trueBearing,
      accuracy: gps.accuracy,
      timestamp: DateTime.now(),
    );

    setState(() => _photos.insert(0, tagged));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera GPS Tagging'),
        elevation: 0,
      ),
      body: _photos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 80, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text('Take a photo to tag with GPS data',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.file(
                        photo.file,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.cyan),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    photo.latitude != null
                                        ? '${photo.latitude!.toStringAsFixed(6)}, ${photo.longitude!.toStringAsFixed(6)}'
                                        : 'No GPS data',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (photo.altitude != null) ...[
                                  const Icon(Icons.height, size: 14, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text('${photo.altitude!.toStringAsFixed(1)}m',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(width: 16),
                                ],
                                const Icon(Icons.explore, size: 14, color: Colors.orange),
                                const SizedBox(width: 4),
                                Text('${photo.bearing.toStringAsFixed(1)}° ${GeoUtils.bearingToCompass(photo.bearing)}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${photo.timestamp.hour.toString().padLeft(2, '0')}:${photo.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'gallery',
            mini: true,
            onPressed: _pickFromGallery,
            backgroundColor: Colors.grey[800],
            child: const Icon(Icons.photo_library),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'camera',
            onPressed: _takePhoto,
            backgroundColor: Colors.cyan,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Capture'),
          ),
        ],
      ),
    );
  }
}

class TaggedPhoto {
  final File file;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double bearing;
  final double? accuracy;
  final DateTime timestamp;

  TaggedPhoto({
    required this.file,
    this.latitude,
    this.longitude,
    this.altitude,
    required this.bearing,
    this.accuracy,
    required this.timestamp,
  });
}
