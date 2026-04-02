import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/compass_provider.dart';
import '../providers/theme_provider.dart';
import '../services/gps_service.dart';
import '../services/waypoint_service.dart';
import '../services/track_service.dart';
import '../services/project_service.dart';
import '../screens/project_manager_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _waypointCount = 0;
  int _trackCount = 0;
  int _projectCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final waypointService = WaypointService();
      final trackService = TrackService();
      final projectService = ProjectService();

      await waypointService.initialize();
      await trackService.initialize();
      await projectService.initialize();

      final wpCount = await waypointService.getWaypointCount();
      final trCount = await trackService.getTrackCount();
      final pjCount = await projectService.getProjectCount();

      if (mounted) {
        setState(() {
          _waypointCount = wpCount;
          _trackCount = trCount;
          _projectCount = pjCount;
        });
      }
    } catch (e) {
      // Hive boxes may already be open from other services - that's fine
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Compass', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyan)),
            const SizedBox(height: 8),
            Consumer<CompassProvider>(
              builder: (context, compass, _) => Card(
                color: Colors.grey[900],
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.compass_calibration, color: Colors.cyan),
                      title: const Text('Magnetic Calibration', style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                        'Declination: ${compass.magneticDeclination.toStringAsFixed(2)}°',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      trailing: OutlinedButton(
                        onPressed: () {
                          compass.resetCalibration();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Magnetometer calibration reset')),
                          );
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.grey),
                    ListTile(
                      leading: const Icon(Icons.explore, color: Colors.orange),
                      title: const Text('Declination', style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                        '${compass.magneticDeclination.toStringAsFixed(2)}° (auto-calculated)',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('GPS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyan)),
            const SizedBox(height: 8),
            Consumer<GpsService>(
              builder: (context, gps, _) => Card(
                color: Colors.grey[900],
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        gps.isListening ? Icons.gps_fixed : Icons.gps_off,
                        color: gps.isListening ? Colors.green : Colors.red,
                      ),
                      title: const Text('GPS Status', style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                        gps.isListening ? 'Active - ${gps.accuracy?.toStringAsFixed(0) ?? "?"}m accuracy' : 'Inactive',
                        style: TextStyle(color: gps.isListening ? Colors.green : Colors.red, fontSize: 12),
                      ),
                    ),
                    if (gps.latitude != null && gps.longitude != null)
                      ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.blue),
                        title: const Text('Current Position', style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          '${gps.latitude!.toStringAsFixed(6)}, ${gps.longitude!.toStringAsFixed(6)}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyan)),
            const SizedBox(height: 8),
            Card(
              color: Colors.grey[900],
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.place, color: Colors.cyan),
                    title: const Text('Waypoints', style: TextStyle(color: Colors.white)),
                    trailing: Text('$_waypointCount', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  ListTile(
                    leading: const Icon(Icons.timeline, color: Colors.orange),
                    title: const Text('Tracks', style: TextStyle(color: Colors.white)),
                    trailing: Text('$_trackCount', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  ListTile(
                    leading: const Icon(Icons.folder, color: Colors.green),
                    title: const Text('Projects', style: TextStyle(color: Colors.white)),
                    trailing: Text('$_projectCount', style: const TextStyle(color: Colors.white, fontSize: 16)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProjectManagerScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
             const SizedBox(height: 24),
             const Text('Theme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyan)),
             const SizedBox(height: 8),
             Consumer<ThemeProvider>(
               builder: (context, themeProvider, _) => Card(
                 color: Colors.grey[900],
                 child: Column(
                   children: [
                     ListTile(
                       leading: const Icon(Icons.brightness_6, color: Colors.amber),
                       title: const Text('Dark Mode', style: TextStyle(color: Colors.white)),
                       trailing: Switch(
                         value: themeProvider.isDarkMode,
                         onChanged: (_) => themeProvider.toggleTheme(),
                         activeColor: themeProvider.primaryColor,
                       ),
                     ),
                     const Divider(height: 1, color: Colors.grey),
                     ListTile(
                       leading: const Icon(Icons.color_lens, color: Colors.blueAccent),
                       title: const Text('Theme Color', style: TextStyle(color: Colors.white)),
                       subtitle: const Text('Customize primary color', style: TextStyle(color: Colors.grey, fontSize: 12)),
                       trailing: PopupMenuButton<Color>(
                         onSelected: (color) => themeProvider.setPrimaryColor(color),
                         itemBuilder: (context) => [
                           PopupMenuItem(
                             value: Colors.blueAccent,
                             child: Row(
                               children: [
                                 Container(
                                   width: 20,
                                   height: 20,
                                   decoration: BoxDecoration(
                                     color: Colors.blueAccent,
                                     borderRadius: BorderRadius.circular(4),
                                   ),
                                 ),
                                 const SizedBox(width: 8),
                                 const Text('Blue'),
                               ],
                             ),
                           ),
                           PopupMenuItem(
                             value: Colors.green,
                             child: Row(
                               children: [
                                 Container(
                                   width: 20,
                                   height: 20,
                                   decoration: BoxDecoration(
                                     color: Colors.green,
                                     borderRadius: BorderRadius.circular(4),
                                   ),
                                 ),
                                 const SizedBox(width: 8),
                                 const Text('Green'),
                               ],
                             ),
                           ),
                           PopupMenuItem(
                             value: Colors.orange,
                             child: Row(
                               children: [
                                 Container(
                                   width: 20,
                                   height: 20,
                                   decoration: BoxDecoration(
                                     color: Colors.orange,
                                     borderRadius: BorderRadius.circular(4),
                                   ),
                                 ),
                                 const SizedBox(width: 8),
                                 const Text('Orange'),
                               ],
                             ),
                           ),
                           PopupMenuItem(
                             value: Colors.purple,
                             child: Row(
                               children: [
                                 Container(
                                   width: 20,
                                   height: 20,
                                   decoration: BoxDecoration(
                                     color: Colors.purple,
                                     borderRadius: BorderRadius.circular(4),
                                   ),
                                 ),
                                 const SizedBox(width: 8),
                                 const Text('Purple'),
                               ],
                             ),
                           ),
                           PopupMenuItem(
                             value: Colors.red,
                             child: Row(
                               children: [
                                 Container(
                                   width: 20,
                                   height: 20,
                                   decoration: BoxDecoration(
                                     color: Colors.red,
                                     borderRadius: BorderRadius.circular(4),
                                   ),
                                 ),
                                 const SizedBox(width: 8),
                                 const Text('Red'),
                               ],
                             ),
                           ),
                         ],
                       ),
                     ),
                   ],
                 ),
               ),
             ),
             const SizedBox(height: 24),
             const Text('Danger Zone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            Card(
              color: Colors.grey[900],
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Delete All Waypoints', style: TextStyle(color: Colors.red)),
                    onTap: () => _confirmDelete('waypoints'),
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Delete All Tracks', style: TextStyle(color: Colors.red)),
                    onTap: () => _confirmDelete('tracks'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'GeoCompass Pro v2.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Precision Site Surveying Tool',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete All $type?'),
        content: Text('This will permanently delete all $type. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (type == 'waypoints') {
                final service = WaypointService();
                await service.initialize();
                await service.deleteAllWaypoints();
              } else {
                final service = TrackService();
                await service.initialize();
                await service.deleteAllTracks();
              }
              if (mounted) {
                Navigator.pop(context);
                _loadCounts();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('All $type deleted')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}
