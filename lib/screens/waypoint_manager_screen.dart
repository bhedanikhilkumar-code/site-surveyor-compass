import 'package:flutter/material.dart';
import '../models/waypoint_model.dart';
import '../services/waypoint_service.dart';
import 'package:intl/intl.dart';

class WaypointManagerScreen extends StatefulWidget {
  final WaypointService waypointService;

  const WaypointManagerScreen({
    Key? key,
    required this.waypointService,
  }) : super(key: key);

  @override
  State<WaypointManagerScreen> createState() => _WaypointManagerScreenState();
}

class _WaypointManagerScreenState extends State<WaypointManagerScreen> {
  late Future<List<Waypoint>> _waypoints;
  final searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _waypoints = widget.waypointService.getWaypointsSortedByDate();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _refreshWaypoints() {
    setState(() {
      if (_isSearching && searchController.text.isNotEmpty) {
        _waypoints = widget.waypointService.searchWaypoints(searchController.text);
      } else {
        _waypoints = widget.waypointService.getWaypointsSortedByDate();
      }
    });
  }

  void _deleteWaypoint(String id) async {
    await widget.waypointService.deleteWaypoint(id);
    _refreshWaypoints();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waypoint deleted'),
          duration: Duration(seconds: 2),
        ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshWaypoints,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
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
                          setState(() {
                            _isSearching = false;
                          });
                          _refreshWaypoints();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Waypoints List
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching ? 'No waypoints found' : 'No waypoints saved yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                        const SizedBox(height: 8),
                        if (!_isSearching)
                          Text(
                            'Tap the + button to create your first waypoint',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: waypoints.length,
                  itemBuilder: (context, index) {
                    final waypoint = waypoints[index];
                    return _buildWaypointCard(waypoint);
                  },
                );
              },
            ),
          ),
        ],
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
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${waypoint.bearing.toInt()}°',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ),
        ),
        title: Text(
          waypoint.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              '📍 ${waypoint.latitude.toStringAsFixed(5)}, ${waypoint.longitude.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '📏 Alt: ${waypoint.altitude.toStringAsFixed(1)}m',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              dateFormat.format(waypoint.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
            PopupMenuItem<dynamic>(
              child: const Text('Edit'),
              onTap: () => _showEditWaypointDialog(waypoint),
            ),
            PopupMenuItem<dynamic>(
              child: const Text('View Details'),
              onTap: () => _showWaypointDetails(waypoint),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<dynamic>(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () => _showDeleteConfirmation(waypoint.id, waypoint.name),
            ),
          ],
        ),
        onTap: () => _showWaypointDetails(waypoint),
      ),
    );
  }

  void _showAddWaypointDialog() {
    final nameController = TextEditingController();
    final bearingController = TextEditingController(text: '0');
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final altController = TextEditingController(text: '0');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Waypoint'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Waypoint Name',
                  hintText: 'e.g., North Corner',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bearingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bearing (°)',
                  suffixText: '°',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: latController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: '28.6139',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lngController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: '77.2090',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: altController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Altitude (m)',
                  suffixText: 'm',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Additional information...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a waypoint name')),
                  );
                  return;
                }

                final bearing = double.tryParse(bearingController.text) ?? 0;
                final lat = double.tryParse(latController.text) ?? 0;
                final lng = double.tryParse(lngController.text) ?? 0;
                final alt = double.tryParse(altController.text) ?? 0;

                await widget.waypointService.createWaypoint(
                  name: name,
                  bearing: bearing,
                  latitude: lat,
                  longitude: lng,
                  altitude: alt,
                  notes: notesController.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                  _refreshWaypoints();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Waypoint added successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
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
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Waypoint Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await widget.waypointService.updateWaypoint(
                  waypoint.id,
                  waypoint.copyWith(
                    name: nameController.text,
                    notes: notesController.text,
                  ),
                );

                if (mounted) {
                  Navigator.pop(context);
                  _refreshWaypoints();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Waypoint updated')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
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
                Text(
                  waypoint.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),
            _detailRow('Bearing', '${waypoint.bearing.toStringAsFixed(1)}°'),
            _detailRow('Latitude', waypoint.latitude.toStringAsFixed(6)),
            _detailRow('Longitude', waypoint.longitude.toStringAsFixed(6)),
            _detailRow('Altitude', '${waypoint.altitude.toStringAsFixed(1)} m'),
            _detailRow('Created', dateFormat.format(waypoint.createdAt)),
            if (waypoint.updatedAt != null)
              _detailRow('Last Updated', dateFormat.format(waypoint.updatedAt!)),
            if (waypoint.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Notes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(waypoint.notes),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
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
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
