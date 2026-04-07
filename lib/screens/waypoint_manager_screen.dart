import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/waypoint_model.dart';
import '../services/api_waypoint_service.dart';
import '../services/gps_service.dart';
import '../widgets/glass_container.dart';
import 'navigate_waypoint_screen.dart';
import 'package:intl/intl.dart';

class WaypointManagerScreen extends StatefulWidget {
  const WaypointManagerScreen({Key? key}) : super(key: key);

  @override
  State<WaypointManagerScreen> createState() => _WaypointManagerScreenState();
}

class _WaypointManagerScreenState extends State<WaypointManagerScreen> {
  late Future<List<Waypoint>> _waypoints;
  final searchController = TextEditingController();
  bool _isSearching = false;
  String _sortBy = 'date';
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    final waypointService = context.read<ApiWaypointService>();
    _waypoints = waypointService.getWaypointsSortedByDate();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _refreshWaypoints() {
    setState(() {
      final waypointService = context.read<ApiWaypointService>();
      if (_isSearching && searchController.text.isNotEmpty) {
        _waypoints = waypointService.searchWaypoints(searchController.text).then((list) => _sortWaypoints(list));
      } else {
        _waypoints = waypointService.getWaypointsSortedByDate().then((list) => _sortWaypoints(list));
      }
    });
  }

  List<Waypoint> _sortWaypoints(List<Waypoint> list) {
    switch (_sortBy) {
      case 'name':
        list.sort((a, b) => _sortDescending ? b.name.compareTo(a.name) : a.name.compareTo(b.name));
        break;
      case 'altitude':
        list.sort((a, b) => _sortDescending ? b.altitude.compareTo(a.altitude) : a.altitude.compareTo(b.altitude));
        break;
      case 'bearing':
        list.sort((a, b) => _sortDescending ? b.bearing.compareTo(a.bearing) : a.bearing.compareTo(b.bearing));
        break;
      default:
        list.sort((a, b) => _sortDescending ? b.createdAt.compareTo(a.createdAt) : a.createdAt.compareTo(b.createdAt));
    }
    return list;
  }

  void _deleteWaypoint(String id) async {
    final waypointService = context.read<ApiWaypointService>();
    await waypointService.deleteWaypoint(id);
    _refreshWaypoints();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waypoint deleted'), duration: Duration(seconds: 2)),
      );
    }
  }

  void _showDeleteConfirmation(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Waypoint?'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteWaypoint(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waypoint Manager'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _sortDescending = !_sortDescending;
                } else {
                  _sortBy = value;
                  _sortDescending = true;
                }
              });
              _refreshWaypoints();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'date', child: Text('Sort by Date ${_sortBy == 'date' ? (_sortDescending ? '↓' : '↑') : ''}')),
              PopupMenuItem(value: 'name', child: Text('Sort by Name ${_sortBy == 'name' ? (_sortDescending ? '↓' : '↑') : ''}')),
              PopupMenuItem(value: 'altitude', child: Text('Sort by Altitude ${_sortBy == 'altitude' ? (_sortDescending ? '↓' : '↑') : ''}')),
              PopupMenuItem(value: 'bearing', child: Text('Sort by Bearing ${_sortBy == 'bearing' ? (_sortDescending ? '↓' : '↑') : ''}')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshWaypoints),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
              const Color(0xFF0f3460),
            ],
          ),
        ),
        child: Column(
          children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() => _isSearching = value.isNotEmpty);
                _refreshWaypoints();
              },
              decoration: InputDecoration(
                hintText: 'Search waypoints...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() => _isSearching = false);
                          _refreshWaypoints();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Waypoint>>(
              future: _waypoints,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }
                final waypoints = snapshot.data ?? [];
                if (waypoints.isEmpty) {
                  return const Center(child: Text('No waypoints'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: waypoints.length,
                  itemBuilder: (context, index) => _buildWaypointCard(waypoints[index]),
                );
              },
            ),
          ),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _showAddWaypointDialog(),
      tooltip: 'Add Waypoint',
      child: const Icon(Icons.add),
    ),
  );
  }

  Widget _buildWaypointCard(Waypoint waypoint) {
    final dateFormat = DateFormat('MMM dd, yyyy - HH:mm');
    return GlassContainer(
      blur: 10,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(8)),
          child: Center(
            child: Text(
              '${waypoint.bearing.toInt()}°',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[900]),
            ),
          ),
        ),
        title: Text(waypoint.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              '${waypoint.latitude.toStringAsFixed(5)}, ${waypoint.longitude.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text('Alt: ${waypoint.altitude.toStringAsFixed(1)}m', style: const TextStyle(fontSize: 12)),
            Text(dateFormat.format(waypoint.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
        trailing: PopupMenuButton<dynamic>(
          itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
            PopupMenuItem<dynamic>(
              child: const Row(children: [Icon(Icons.navigation, size: 18, color: Colors.cyan), SizedBox(width: 8), Text('Navigate')]),
              onTap: () {
                Future.delayed(Duration.zero, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NavigateWaypointScreen(waypoint: waypoint)),
                  );
                });
              },
            ),
            PopupMenuItem<dynamic>(child: const Text('Edit'), onTap: () => _showEditWaypointDialog(waypoint)),
            PopupMenuItem<dynamic>(child: const Text('View Details'), onTap: () => _showWaypointDetails(waypoint)),
            const PopupMenuDivider(),
            PopupMenuItem<dynamic>(child: const Text('Delete', style: TextStyle(color: Colors.red)), onTap: () => _showDeleteConfirmation(waypoint.id, waypoint.name)),
          ],
        ),
        onTap: () => _showWaypointDetails(waypoint),
      ),
    );
  }

  void _showAddWaypointDialog() {
    showDialog(
      context: context,
      builder: (context) => AddWaypointDialog(onWaypointAdded: () => _refreshWaypoints()),
    );
  }

  void _showEditWaypointDialog(Waypoint waypoint) {
    final nameController = TextEditingController(text: waypoint.name);
    final notesController = TextEditingController(text: waypoint.notes);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Waypoint'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Waypoint Name')),
              const SizedBox(height: 12),
              TextField(controller: notesController, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                final waypointService = context.read<ApiWaypointService>();
                await waypointService.updateWaypoint(
                  waypoint.id,
                  waypoint.copyWith(name: nameController.text, notes: notesController.text),
                );
                if (mounted) {
                  Navigator.pop(context);
                  _refreshWaypoints();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Waypoint updated')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWaypointDetails(Waypoint waypoint) {
    final dateFormat = DateFormat('MMM dd, yyyy - HH:mm:ss');
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(waypoint.name, style: Theme.of(context).textTheme.headlineSmall),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(height: 20),
            _detailRow('Bearing', '${waypoint.bearing.toStringAsFixed(1)}°'),
            _detailRow('Latitude', waypoint.latitude.toStringAsFixed(6)),
            _detailRow('Longitude', waypoint.longitude.toStringAsFixed(6)),
            _detailRow('Altitude', '${waypoint.altitude.toStringAsFixed(1)} m'),
            _detailRow('Created', dateFormat.format(waypoint.createdAt)),
            if (waypoint.updatedAt != null) _detailRow('Last Updated', dateFormat.format(waypoint.updatedAt!)),
            if (waypoint.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(waypoint.notes),
            ],
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton.tonal(onPressed: () => Navigator.pop(context), child: const Text('Close'))),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class AddWaypointDialog extends StatefulWidget {
  final VoidCallback onWaypointAdded;
  const AddWaypointDialog({Key? key, required this.onWaypointAdded}) : super(key: key);

  @override
  State<AddWaypointDialog> createState() => _AddWaypointDialogState();
}

class _AddWaypointDialogState extends State<AddWaypointDialog> {
  final nameController = TextEditingController();
  final bearingController = TextEditingController(text: '0');
  final latController = TextEditingController();
  final lngController = TextEditingController();
  final altController = TextEditingController(text: '0');
  final notesController = TextEditingController();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _fillCurrentLocation();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _fillCurrentLocation() async {
    try {
      final gpsService = context.read<GpsService>();
      if (gpsService.latitude != null && gpsService.longitude != null) {
        setState(() {
          latController.text = gpsService.latitude!.toStringAsFixed(6);
          lngController.text = gpsService.longitude!.toStringAsFixed(6);
          if (gpsService.altitude != null) {
            altController.text = gpsService.altitude!.toStringAsFixed(1);
          }
        });
      }
    } catch (e) {
      // GPS not available
    }
  }

  Future<void> _startListening() async {
    if (!_isListening && _speechAvailable) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() => notesController.text = result.recognizedWords.toString());
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      );
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    bearingController.dispose();
    latController.dispose();
    lngController.dispose();
    altController.dispose();
    notesController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Waypoint'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Waypoint Name', hintText: 'e.g., North Corner'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bearingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Bearing (°)', suffixText: '°'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Latitude',
                hintText: '28.6139',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location, size: 18),
                  tooltip: 'Use current GPS location',
                  onPressed: _fillCurrentLocation,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lngController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Longitude', hintText: '77.2090'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: altController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Altitude (m)', suffixText: 'm'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText: 'Additional information...',
                suffixIcon: IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  color: _isListening ? Colors.red : null,
                  onPressed: _speechAvailable ? _startListening : null,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            try {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a waypoint name')));
                return;
              }
              final bearing = double.tryParse(bearingController.text) ?? 0;
              final lat = double.tryParse(latController.text) ?? 0;
              final lng = double.tryParse(lngController.text) ?? 0;
              final alt = double.tryParse(altController.text) ?? 0;
              final waypointService = context.read<ApiWaypointService>();
              await waypointService.createWaypoint(
                name: name,
                bearing: bearing,
                latitude: lat,
                longitude: lng,
                altitude: alt,
                notes: notesController.text,
              );
              Navigator.pop(context);
              widget.onWaypointAdded();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Waypoint added successfully')));
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding waypoint: $e')));
              }
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
