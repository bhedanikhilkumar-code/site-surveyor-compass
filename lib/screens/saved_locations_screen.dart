import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../services/gps_service.dart';
import '../utils/geo_utils.dart';

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({Key? key}) : super(key: key);

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  late Box _box;
  List<Map<String, dynamic>> _bookmarks = [];
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _initBox();
  }

  Future<void> _initBox() async {
    _box = await Hive.openBox('bookmarks');
    _loadBookmarks();
  }

  void _loadBookmarks() {
    setState(() {
      _bookmarks = _box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _isLoaded = true;
    });
  }

  Future<void> _addBookmark() async {
    final gps = context.read<GpsService>();
    if (gps.latitude == null || gps.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPS not available')));
      return;
    }

    final nameController = TextEditingController();
    String selectedCategory = 'Site';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Save Location'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Location Name', hintText: 'e.g. Site Office'),
                ),
                const SizedBox(height: 12),
                const Text('Category:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Home', 'Site', 'Office', 'Landmark', 'Other'].map((c) =>
                    ChoiceChip(
                      label: Text(c),
                      selected: selectedCategory == c,
                      onSelected: (_) => setDialogState(() => selectedCategory = c),
                    )
                  ).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(context, {
                  'name': nameController.text.isNotEmpty ? nameController.text : 'Location',
                  'category': selectedCategory,
                }),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    final bookmark = {
      'id': const Uuid().v4(),
      'name': result['name']!,
      'category': result['category']!,
      'latitude': gps.latitude,
      'longitude': gps.longitude,
      'altitude': gps.altitude ?? 0,
      'address': gps.address ?? '',
      'timestamp': DateTime.now().toIso8601String(),
      'icon': _getIconName(result['category']!),
      'color': _getColorName(result['category']!),
    };

    await _box.put(bookmark['id'], bookmark);
    _loadBookmarks();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location saved!')));
    }
  }

  Future<void> _deleteBookmark(String id) async {
    await _box.delete(id);
    _loadBookmarks();
  }

  String _getIconName(String category) {
    switch (category) {
      case 'Home': return 'home';
      case 'Site': return 'construction';
      case 'Office': return 'business';
      case 'Landmark': return 'flag';
      default: return 'place';
    }
  }

  String _getColorName(String category) {
    switch (category) {
      case 'Home': return '#4CAF50';
      case 'Site': return '#FF9800';
      case 'Office': return '#2196F3';
      case 'Landmark': return '#9C27B0';
      default: return '#607D8B';
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'home': return Icons.home;
      case 'construction': return Icons.construction;
      case 'business': return Icons.business;
      case 'flag': return Icons.flag;
      default: return Icons.place;
    }
  }

  Color _getColor(String colorName) {
    return Color(int.parse(colorName.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Locations'), elevation: 0),
      body: !_isLoaded
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 80, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text('No saved locations', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, index) {
                    final b = _bookmarks[index];
                    final color = _getColor(b['color'] as String? ?? '#607D8B');
                    return Card(
                      color: Colors.grey[900],
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColor(b['color'] as String? ?? '#607D8B').withOpacity(0.2),
                          child: Icon(_getIcon(b['icon'] as String? ?? 'place'), color: _getColor(b['color'] as String? ?? '#607D8B'), size: 20),
                        ),
                        title: Text(b['name'] as String? ?? 'Location', style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          '${(b['latitude'] as num?)?.toStringAsFixed(5) ?? '?'}, ${(b['longitude'] as num?)?.toStringAsFixed(5) ?? '?'}\n${b['category'] as String? ?? ''} | ${b['address'] as String? ?? ''}',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                          maxLines: 2,
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => _deleteBookmark(b['id'] as String),
                        ),
                        onTap: () => _viewOnMap(b.cast<String, dynamic>()),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBookmark,
        backgroundColor: Colors.cyan,
        icon: const Icon(Icons.bookmark_add),
        label: const Text('Save Here'),
      ),
    );
  }

  void _viewOnMap(Map<String, dynamic> bookmark) {
    final lat = bookmark['latitude'] as double?;
    final lng = bookmark['longitude'] as double?;
    if (lat == null || lng == null) return;

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(bookmark['name'] as String? ?? 'Location')),
        body: FlutterMap(
          options: MapOptions(initialCenter: LatLng(lat, lng), initialZoom: 17),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.surveyor.compass'),
            MarkerLayer(markers: [
              Marker(
                point: LatLng(lat, lng),
                width: 40, height: 40,
                child: Icon(Icons.location_on, color: _getColor(bookmark['color'] as String? ?? '#607D8B'), size: 40),
              ),
            ]),
          ],
        ),
      ),
    ));
  }
}
