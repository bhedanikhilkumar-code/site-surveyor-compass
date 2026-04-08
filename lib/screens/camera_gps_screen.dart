import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:exif/exif.dart';
import '../services/gps_service.dart';
import '../providers/compass_provider.dart';
import '../utils/geo_utils.dart';
import '../models/tagged_photo.dart';

class CameraGpsScreen extends StatefulWidget {
  const CameraGpsScreen({Key? key}) : super(key: key);

  @override
  State<CameraGpsScreen> createState() => _CameraGpsScreenState();
}

class _CameraGpsScreenState extends State<CameraGpsScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<TaggedPhoto> _photos = [];
  Box<TaggedPhoto>? _photosBox;
  bool _isLoading = true;

  static const String _boxName = 'tagged_photos';

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      _photosBox = await Hive.openBox<TaggedPhoto>(_boxName);
      final savedPhotos = _photosBox!.values.toList();
      setState(() {
        _photos.clear();
        _photos.addAll(savedPhotos.reversed);
        _isLoading = false;
      });
    } on Exception catch (e) {
      debugPrint('Error loading photos: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePhoto(TaggedPhoto photo) async {
    try {
      if (_photosBox == null) {
        _photosBox = await Hive.openBox<TaggedPhoto>(_boxName);
      }
      await _photosBox!.add(photo);
    } on Exception catch (e) {
      debugPrint('Error saving photo: $e');
    }
  }

  Future<void> _deletePhoto(int index) async {
    try {
      final photo = _photos[index];
      final file = File(photo.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      final boxIndex = _photosBox!.length - 1 - index;
      await _photosBox!.deleteAt(boxIndex);
      setState(() => _photos.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted')),
      );
    } on Exception catch (e) {
      debugPrint('Error deleting photo: $e');
    }
  }

  Future<String?> _copyImageToAppDir(String originalPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = '${photosDir.path}/$fileName';
      final sourceFile = File(originalPath);
      await sourceFile.copy(newPath);
      return newPath;
    } catch (e) {
      debugPrint('Error copying image: $e');
      return null;
    }
  }

  Future<void> _writeExifGpsData(String filePath, TaggedPhoto photo) async {
    try {
      if (photo.latitude == null || photo.longitude == null) return;
      final file = File(filePath);
      if (!await file.exists()) return;
      final bytes = await file.readAsBytes();

      try {} on Exception catch (e) {
      debugPrint('GPS EXIF writing not available in this version');
    }
    try {} catch (e) {
      debugPrint('GPS EXIF writing not available in this version');
    }
    try {} catch (e) {
      debugPrint('GPS EXIF writing not available in this version');
    }
      
      await file.writeAsBytes(bytes);
    } on Exception catch (e) {
      debugPrint('Error writing EXIF data: $e');
    }
  }





  Future<void> _takePhoto() async {
    final gps = context.read<GpsService>();
    final compass = context.read<CompassProvider>();
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo == null || !mounted) return;
    final appPath = await _copyImageToAppDir(photo.path);
    if (appPath == null) return;
    final tagged = TaggedPhoto(
      filePath: appPath,
      latitude: gps.latitude,
      longitude: gps.longitude,
      altitude: gps.altitude,
      bearing: compass.trueBearing,
      accuracy: gps.accuracy,
      timestamp: DateTime.now(),
    );
    await _writeExifGpsData(appPath, tagged);
    await _savePhoto(tagged);
    setState(() => _photos.insert(0, tagged));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo captured with GPS tag')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final gps = context.read<GpsService>();
    final compass = context.read<CompassProvider>();
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (photo == null || !mounted) return;
    final appPath = await _copyImageToAppDir(photo.path);
    if (appPath == null) return;
    final tagged = TaggedPhoto(
      filePath: appPath,
      latitude: gps.latitude,
      longitude: gps.longitude,
      altitude: gps.altitude,
      bearing: compass.trueBearing,
      accuracy: gps.accuracy,
      timestamp: DateTime.now(),
    );
    await _writeExifGpsData(appPath, tagged);
    await _savePhoto(tagged);
    setState(() => _photos.insert(0, tagged));
  }

  Future<void> _viewPhoto(TaggedPhoto photo) async {
    final file = File(photo.filePath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo file not found')),
        );
      }
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PhotoViewerScreen(photo: photo),
      ),
    );
  }

  Future<void> _sharePhoto(TaggedPhoto photo) async {
    try {
      final file = File(photo.filePath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo file not found')),
          );
        }
        return;
      }
      await Share.shareXFiles(
        [XFile(photo.filePath)],
        text:
            'GPS Location: ${photo.latitude?.toStringAsFixed(6)}, ${photo.longitude?.toStringAsFixed(6)}\nAltitude: ${photo.altitude?.toStringAsFixed(1)}m\nBearing: ${photo.bearing.toStringAsFixed(1)}°',
      );
    } on Exception catch (e) {
      debugPrint('Error sharing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing photo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera GPS Tagging'),
        elevation: 0,
        actions: [
          if (_photos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _confirmDeleteAll,
              tooltip: 'Delete all photos',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 80, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text(
                        'Take a photo to tag with GPS data',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
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
                          GestureDetector(
                            onTap: () => _viewPhoto(photo),
                            child: Image.file(
                              File(photo.filePath),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[800],
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.cyan,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        photo.latitude != null
                                            ? '${photo.latitude!.toStringAsFixed(6)}, ${photo.longitude!.toStringAsFixed(6)}'
                                            : 'No GPS data',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (photo.altitude != null) ...[
                                      const Icon(
                                        Icons.height,
                                        size: 14,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${photo.altitude!.toStringAsFixed(1)}m',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                    ],
                                    const Icon(
                                      Icons.explore,
                                      size: 14,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${photo.bearing.toStringAsFixed(1)}° ${GeoUtils.bearingToCompass(photo.bearing)}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${photo.timestamp.hour.toString().padLeft(2, '0')}:${photo.timestamp.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility,
                                        color: Colors.cyan,
                                        size: 20,
                                      ),
                                      onPressed: () => _viewPhoto(photo),
                                      tooltip: 'View full size',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.share,
                                        color: Colors.cyan,
                                        size: 20,
                                      ),
                                      onPressed: () => _sharePhoto(photo),
                                      tooltip: 'Share photo',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      onPressed: () => _confirmDelete(index),
                                      tooltip: 'Delete photo',
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

  Future<void> _confirmDelete(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deletePhoto(index);
    }
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Photos'),
        content: Text(
          'Are you sure you want to delete all ${_photos.length} photos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        for (final photo in _photos) {
          final file = File(photo.filePath);
          if (await file.exists()) {
            await file.delete();
          }
        }
        await _photosBox?.clear();
        setState(() => _photos.clear());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All photos deleted')),
          );
        }
      } catch (e) {
        debugPrint('Error deleting all photos: $e');
      }
    }
  }
}

class _PhotoViewerScreen extends StatelessWidget {
  final TaggedPhoto photo;

  const _PhotoViewerScreen({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.cyan),
        title: Text(
          '${photo.timestamp.hour.toString().padLeft(2, '0')}:${photo.timestamp.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              try {
                await Share.shareXFiles(
                  [XFile(photo.filePath)],
                  text:
                      'GPS Location: ${photo.latitude?.toStringAsFixed(6)}, ${photo.longitude?.toStringAsFixed(6)}\nAltitude: ${photo.altitude?.toStringAsFixed(1)}m\nBearing: ${photo.bearing.toStringAsFixed(1)}°',
                );
              } catch (e) {
                debugPrint('Error sharing: $e');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            File(photo.filePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black87,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photo.latitude != null)
              _buildInfoRow(
                Icons.location_on,
                'Location',
                '${photo.latitude!.toStringAsFixed(6)}, ${photo.longitude!.toStringAsFixed(6)}',
              ),
            if (photo.altitude != null)
              _buildInfoRow(
                Icons.height,
                'Altitude',
                '${photo.altitude!.toStringAsFixed(1)}m',
              ),
            _buildInfoRow(
              Icons.explore,
              'Bearing',
              '${photo.bearing.toStringAsFixed(1)}° ${GeoUtils.bearingToCompass(photo.bearing)}',
            ),
            _buildInfoRow(
              Icons.access_time,
              'Time',
              '${photo.timestamp.year}-${photo.timestamp.month.toString().padLeft(2, '0')}-${photo.timestamp.day.toString().padLeft(2, '0')} ${photo.timestamp.hour.toString().padLeft(2, '0')}:${photo.timestamp.minute.toString().padLeft(2, '0')}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.cyan),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
