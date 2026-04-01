import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/waypoint_model.dart';
import '../models/track_model.dart';
import '../services/api_waypoint_service.dart';
import '../services/track_service.dart';
import '../services/gps_service.dart';

class CloudBackupScreen extends StatefulWidget {
  const CloudBackupScreen({Key? key}) : super(key: key);

  @override
  State<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends State<CloudBackupScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String _status = 'Ready';
  int _localWaypoints = 0;
  int _localTracks = 0;
  int _cloudWaypoints = 0;
  DateTime? _lastBackup;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final wpService = context.read<ApiWaypointService>();
      final trService = TrackService();
      await trService.initialize();

      final wps = await wpService.getAllWaypoints();
      final trs = await trService.getAllTracks();

      int cloudCount = 0;
      try {
        final snapshot = await FirebaseFirestore.instance.collection('waypoints').get();
        cloudCount = snapshot.docs.length;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _localWaypoints = wps.length;
          _localTracks = trs.length;
          _cloudWaypoints = cloudCount;
          _status = 'Ready';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Error loading data');
    }
  }

  Future<void> _backupToCloud() async {
    setState(() {
      _isBackingUp = true;
      _status = 'Backing up...';
    });

    try {
      final wpService = context.read<ApiWaypointService>();
      final wps = await wpService.getAllWaypoints();
      final firestore = FirebaseFirestore.instance;

      int count = 0;
      for (final wp in wps) {
        await firestore.collection('waypoints').doc(wp.id).set({
          'id': wp.id,
          'name': wp.name,
          'latitude': wp.latitude,
          'longitude': wp.longitude,
          'altitude': wp.altitude,
          'bearing': wp.bearing,
          'notes': wp.notes,
          'createdAt': wp.createdAt.toIso8601String(),
          'updatedAt': wp.updatedAt?.toIso8601String(),
          'backupTime': DateTime.now().toIso8601String(),
        });
        count++;
      }

      if (mounted) {
        setState(() {
          _isBackingUp = false;
          _status = 'Backup complete! $count waypoints uploaded';
          _lastBackup = DateTime.now();
          _cloudWaypoints = count;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backed up $count waypoints to cloud')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
          _status = 'Backup failed: ${e.toString().length > 50 ? e.toString().substring(0, 50) : e.toString()}';
        });
      }
    }
  }

  Future<void> _restoreFromCloud() async {
    setState(() {
      _isRestoring = true;
      _status = 'Restoring from cloud...';
    });

    try {
      final wpService = context.read<ApiWaypointService>();
      final snapshot = await FirebaseFirestore.instance.collection('waypoints').get();

      int count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final existing = await wpService.getWaypoint(data['id'] as String? ?? '');
        if (existing == null) {
          await wpService.createWaypoint(
            name: (data['name'] as String?) ?? 'Restored',
            bearing: (data['bearing'] as num?)?.toDouble() ?? 0,
            latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
            longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
            altitude: (data['altitude'] as num?)?.toDouble() ?? 0,
            notes: (data['notes'] as String?) ?? '',
          );
          count++;
        }
      }

      await _loadCounts();

      if (mounted) {
        setState(() {
          _isRestoring = false;
          _status = 'Restored $count new waypoints';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restored $count waypoints from cloud')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRestoring = false;
          _status = 'Restore failed: ${e.toString().length > 50 ? e.toString().substring(0, 50) : e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Backup'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      _isBackingUp || _isRestoring ? Icons.cloud_sync : Icons.cloud,
                      size: 60,
                      color: _isBackingUp || _isRestoring ? Colors.orange : Colors.cyan,
                    ),
                    const SizedBox(height: 12),
                    Text(_status, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    if (_lastBackup != null)
                      Text(
                        'Last backup: ${_lastBackup!.day}/${_lastBackup!.month} ${_lastBackup!.hour}:${_lastBackup!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Data counts
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _countRow('Local Waypoints', '$_localWaypoints', Colors.blue),
                    const Divider(color: Colors.grey),
                    _countRow('Cloud Waypoints', '$_cloudWaypoints', Colors.cyan),
                    const Divider(color: Colors.grey),
                    _countRow('Local Tracks', '$_localTracks', Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isBackingUp ? null : _backupToCloud,
                icon: _isBackingUp
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_upload),
                label: Text(_isBackingUp ? 'Backing up...' : 'Backup to Cloud'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isRestoring ? null : _restoreFromCloud,
                icon: _isRestoring
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_download),
                label: Text(_isRestoring ? 'Restoring...' : 'Restore from Cloud'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Info
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('How it works:', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _info('Backup uploads all local waypoints to Firebase Cloud'),
                    _info('Restore downloads cloud waypoints that don\'t exist locally'),
                    _info('Data is synced across all your devices'),
                    _info('Requires internet connection'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countRow(String label, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400])),
          Text(count, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _info(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }
}
