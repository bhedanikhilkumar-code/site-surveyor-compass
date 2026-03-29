import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/compass_provider.dart';
import '../services/gps_service.dart';
import '../services/waypoint_service.dart';
import '../widgets/compass_dial.dart';
import 'waypoint_manager_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showTrueBearing = true;
  bool _levelCalibrationMode = false;

  @override
  void initState() {
    super.initState();
    // Request permissions and initialize GPS on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gpsService = context.read<GpsService>();
      gpsService.getInitialPosition();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Surveyor Compass'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsBottomSheet(context),
          ),
        ],
      ),
      body: Consumer3<CompassProvider, GpsService, WaypointService>(
        builder: (context, compassProvider, gpsService, waypointService, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Main Compass Dial
                Center(
                  child: CompassDial(
                    bearing: compassProvider.bearing,
                    trueBearing: compassProvider.trueBearing,
                    showTrueBearing: _showTrueBearing,
                    cardinalDirection: compassProvider.getCardinalDirection(
                      compassProvider.bearing,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),

                // Bearing Info Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildBearingInfoColumn(
                                'Magnetic Bearing',
                                '${compassProvider.bearing.toStringAsFixed(1)}°',
                                Colors.red,
                              ),
                              _buildBearingInfoColumn(
                                'True Bearing',
                                '${compassProvider.trueBearing.toStringAsFixed(1)}°',
                                Colors.blue,
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Text(
                            'Cardinal: ${compassProvider.getCardinalDirection(compassProvider.bearing)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // GPS Location Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GPS Location',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (gpsService.locationError != null)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning, size: 16, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      gpsService.locationError!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (gpsService.currentPosition != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLocationRow(
                                  '📍',
                                  'Location',
                                  gpsService.getLocationString(),
                                ),
                                const SizedBox(height: 8),
                                _buildLocationRow(
                                  '📏',
                                  'Altitude',
                                  gpsService.getAltitudeString(),
                                ),
                                const SizedBox(height: 8),
                                _buildLocationRow(
                                  '🎯',
                                  'Accuracy',
                                  gpsService.getAccuracyString(),
                                ),
                              ],
                            )
                          else
                            const Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Orientation Info (Pitch & Roll)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Surface Level (Accelerometer)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildOrientationColumn(
                                'Pitch',
                                '${compassProvider.pitch.toStringAsFixed(1)}°',
                                compassProvider.pitch.abs() < 2,
                              ),
                              _buildOrientationColumn(
                                'Roll',
                                '${compassProvider.roll.toStringAsFixed(1)}°',
                                compassProvider.roll.abs() < 2,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Bubble Level Visualization
                _buildBubbleLevel(compassProvider),

                const SizedBox(height: 30),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () {
                            setState(() {
                              _showTrueBearing = !_showTrueBearing;
                            });
                          },
                          child: Text(
                            _showTrueBearing ? 'Hide True N' : 'Show True N',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Calibration placeholder'),
                              ),
                            );
                          },
                          child: const Text('Calibrate'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Waypoint Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WaypointManagerScreen(
                              waypointService: waypointService,
                            ),
                          ),
                        );
                      },
                      child: const Text('📍 Manage Waypoints'),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Save Waypoint Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _showQuickSaveDialog(
                        context,
                        waypointService,
                        compassProvider,
                        gpsService,
                      ),
                      child: const Text('⭐ Save Current Location'),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationRow(String icon, String label, String value) {
    return Row(
      children: [
        Text(icon),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildBearingInfoColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildOrientationColumn(String label, String value, bool isLevel) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isLevel ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildBubbleLevel(CompassProvider compassProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Digital Bubble Level',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: CustomPaint(
                  painter: BubbleLevelPainter(
                    pitch: compassProvider.pitch,
                    roll: compassProvider.roll,
                  ),
                  size: Size.infinite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    final compassProvider = Provider.of<CompassProvider>(context, listen: false);
    final gpsService = Provider.of<GpsService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Magnetic Declination'),
                subtitle: Text(
                  '${compassProvider.magneticDeclination.toStringAsFixed(1)}°',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  Navigator.pop(context);
                  _showDeclinationDialog(context, compassProvider);
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('GPS Status'),
                subtitle: gpsService.isListening
                    ? const Text('Tracking location')
                    : const Text('Tap to enable tracking'),
                trailing: Icon(
                  gpsService.isListening ? Icons.location_on : Icons.location_off,
                ),
                onTap: () {
                  if (gpsService.isListening) {
                    gpsService.stopLocationUpdates();
                  } else {
                    gpsService.startLocationUpdates();
                  }
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Calibrate Compass'),
                subtitle: const Text('Reduce magnetic interference'),
                onTap: () {
                  Navigator.pop(context);
                  compassProvider.startCalibration();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeclinationDialog(BuildContext context, CompassProvider compassProvider) {
    final controller = TextEditingController(
      text: compassProvider.magneticDeclination.toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Magnetic Declination'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            decoration: const InputDecoration(
              hintText: 'Enter declination in degrees',
              suffixText: '°',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text) ?? 0;
                compassProvider.setMagneticDeclination(value);
                Navigator.pop(context);
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
  }

  void _showQuickSaveDialog(
    BuildContext context,
    WaypointService waypointService,
    CompassProvider compassProvider,
    GpsService gpsService,
  ) {
    if (gpsService.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS location not available yet'),
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Waypoint'),
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
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add any additional information...',
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

                await waypointService.createWaypoint(
                  name: name,
                  bearing: compassProvider.bearing,
                  latitude: gpsService.currentPosition!.latitude,
                  longitude: gpsService.currentPosition!.longitude,
                  altitude: gpsService.currentPosition!.altitude,
                  notes: notesController.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Waypoint saved successfully'),
                      duration: Duration(seconds: 2),
                    ),
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
}

class BubbleLevelPainter extends CustomPainter {
  final double pitch;
  final double roll;

  BubbleLevelPainter({
    required this.pitch,
    required this.roll,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw crosshair center
    canvas.drawLine(
      Offset(center.dx - 20, center.dy),
      Offset(center.dx + 20, center.dy),
      Paint()..color = Colors.grey[300]!,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 20),
      Offset(center.dx, center.dy + 20),
      Paint()..color = Colors.grey[300]!,
    );

    // Calculate bubble position from pitch and roll
    final bubbleX = center.dx + (roll * 1.5).clamp(-30, 30);
    final bubbleY = center.dy + (pitch * 1.5).clamp(-30, 30);

    // Draw bubble
    final isLevel = pitch.abs() < 2 && roll.abs() < 2;
    canvas.drawCircle(
      Offset(bubbleX, bubbleY),
      12,
      Paint()
        ..color = isLevel ? Colors.green : Colors.orange
        ..style = PaintingStyle.fill,
    );

    // Draw bubble border
    canvas.drawCircle(
      Offset(bubbleX, bubbleY),
      12,
      Paint()
        ..color = isLevel ? Colors.green[700]! : Colors.orange[700]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(BubbleLevelPainter oldDelegate) {
    return oldDelegate.pitch != pitch || oldDelegate.roll != roll;
  }
}
