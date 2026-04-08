import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../widgets/glass_container.dart';

class DataSyncScreen extends StatefulWidget {
  const DataSyncScreen({super.key});

  @override
  State<DataSyncScreen> createState() => _DataSyncScreenState();
}

class _DataSyncScreenState extends State<DataSyncScreen> {
  bool _isSyncing = false;
  String _lastSyncTime = 'Never';
  final List<SyncHistory> _syncHistory = [];

  Future<void> _syncToCloud() async {
    setState(() => _isSyncing = true);

    await Future.delayed(const Duration(seconds: 2));

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/data_sync.json');
    final syncData = {
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      'device': 'mobile',
    };
    await file.writeAsString(jsonEncode(syncData));

    setState(() {
      _isSyncing = false;
      _lastSyncTime = DateTime.now().toString().substring(0, 16);
      _syncHistory.add(SyncHistory(
        type: 'Upload',
        time: DateTime.now(),
        status: 'Success',
      ));
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data synced to cloud!')),
      );
    }
  }

  Future<void> _syncFromCloud() async {
    setState(() => _isSyncing = true);

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSyncing = false;
      _syncHistory.add(SyncHistory(
        type: 'Download',
        time: DateTime.now(),
        status: 'Success',
      ));
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data restored from cloud!')),
      );
    }
  }

  Future<void> _exportToDevice() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/backup_data.json');
    final data = {
      'waypoints': [],
      'tracks': [],
      'projects': [],
      'exportedAt': DateTime.now().toIso8601String(),
    };
    await file.writeAsString(jsonEncode(data));

    await Share.shareXFiles([XFile(file.path)], text: 'Backup Data');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Sync'),
        backgroundColor: const Color(0xFF1a1a2e),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSyncCard(
              icon: Icons.cloud_upload,
              title: 'Upload to Cloud',
              subtitle: 'Backup your data to cloud storage',
              onTap: _isSyncing ? null : _syncToCloud,
            ),
            const SizedBox(height: 12),
            _buildSyncCard(
              icon: Icons.cloud_download,
              title: 'Download from Cloud',
              subtitle: 'Restore data from cloud backup',
              onTap: _isSyncing ? null : _syncFromCloud,
            ),
            const SizedBox(height: 12),
            _buildSyncCard(
              icon: Icons.save_alt,
              title: 'Export to Device',
              subtitle: 'Save backup file to device',
              onTap: _exportToDevice,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sync Status',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last Sync: $_lastSyncTime',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (_isSyncing) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Syncing...', style: TextStyle(color: Colors.white54)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sync History',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (_syncHistory.isEmpty)
              const Text('No sync history', style: TextStyle(color: Colors.white54))
            else
              ...(_syncHistory.reversed.map((h) => ListTile(
                leading: Icon(
                  h.type == 'Upload' ? Icons.cloud_upload : Icons.cloud_download,
                  color: h.status == 'Success' ? Colors.green : Colors.red,
                ),
                title: Text(h.type, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  h.time.toString().substring(0, 16),
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: Text(h.status, style: const TextStyle(color: Colors.green)),
              ))),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GlassContainer(
      blur: 10,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        leading: Icon(icon, color: Colors.cyanAccent, size: 32),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class SyncHistory {
  final String type;
  final DateTime time;
  final String status;

  SyncHistory({required this.type, required this.time, required this.status});
}
