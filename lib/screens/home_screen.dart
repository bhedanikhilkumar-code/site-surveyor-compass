import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/compass_provider.dart';
import '../providers/theme_provider.dart';
import '../services/gps_service.dart';
import '../widgets/compass_dial.dart';
import '../utils/geo_utils.dart';
import 'waypoint_manager_screen.dart';
import 'level_screen.dart';
import 'map_screen.dart';
import 'tools_screen.dart';
import 'track_recording_screen.dart';
import 'area_measurement_screen.dart';
import 'ar_compass_screen.dart';
import 'project_manager_screen.dart';
import 'import_export_screen.dart';
import 'settings_screen.dart';
import 'camera_gps_screen.dart';
import 'slope_calculator_screen.dart';
import 'distance_measure_screen.dart';
import 'qr_share_screen.dart';
import 'voice_notes_screen.dart';
import 'height_measure_screen.dart';
import 'terrain_viewer_screen.dart';
import 'pdf_report_screen.dart';
import 'coordinate_converter_screen.dart';
import 'bearing_line_screen.dart';
import 'gps_strength_screen.dart';
import 'saved_locations_screen.dart';
import 'cloud_backup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showTrueBearing = true;
  String _currentTime = '';
  String _currentDate = '';
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final gpsService = context.read<GpsService>();
      await gpsService.getInitialPosition();
      await gpsService.startLocationUpdates(
        accuracy: LocationAccuracy.bestForNavigation,
        intervalMs: 1000,
        distanceFilterMeters: 5,
      );
    });
  }

  void _updateClock() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _currentDate = '${now.day.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60), // Space for indicators

                const SizedBox(height: 24),

                // COMPASS SECTION - Only this part rebuilds on bearing change
                Selector<CompassProvider, double>(
                  selector: (_, provider) => _showTrueBearing ? provider.trueBearing : provider.bearing,
                  builder: (context, bearing, _) {
                    return Column(
                      children: [
                        Center(
                          child: CompassDial(bearing: bearing),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.read<CompassProvider>().getCardinalDirection(bearing),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            fontFamily: 'sans-serif',
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // GPS COORDINATES - Only rebuilds when GPS changes
                Consumer<GpsService>(
                  builder: (context, gpsService, _) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCoordinateColumn(
                              'NL',
                              gpsService.latitude != null
                                  ? _formatCoordinate(gpsService.latitude!.abs(), isLatitude: true) +
                                    (gpsService.latitude! >= 0 ? ' N' : ' S')
                                  : '--',
                            ),
                            _buildCoordinateColumn(
                              'EL',
                              gpsService.longitude != null
                                  ? _formatCoordinate(gpsService.longitude!.abs(), isLatitude: false) +
                                    (gpsService.longitude! >= 0 ? ' E' : ' W')
                                  : '--',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Address and GPS Info
                        if (gpsService.address != null)
                          Text(
                            gpsService.address!,
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // GPS STATUS & NAV DATA - Rebuilds on compass changes
                Selector<CompassProvider, _NavData>(
                  selector: (_, p) => _NavData(
                    speed: p.speed,
                    accuracy: p.accuracy,
                    hasGpsLock: p.hasGpsLock,
                    declination: p.magneticDeclination,
                  ),
                  builder: (context, navData, child) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.gps_fixed,
                                size: 14,
                                color: navData.hasGpsLock ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                navData.accuracy > 0
                                    ? '${navData.accuracy.toStringAsFixed(0)}m accuracy'
                                    : 'No GPS lock',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: navData.hasGpsLock ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildNavDataColumn(
                                Icons.speed,
                                '${navData.speed.toStringAsFixed(1)}',
                                'km/h',
                                navData.hasGpsLock ? Colors.green : Colors.orange,
                              ),
                              _buildNavDataColumn(
                                Icons.gps_fixed,
                                navData.accuracy > 0
                                    ? '${navData.accuracy.toStringAsFixed(0)}'
                                    : '--',
                                'meters',
                                navData.hasGpsLock ? Colors.green : Colors.red,
                              ),
                              _buildNavDataColumn(
                                Icons.compass_calibration,
                                '${navData.declination.toStringAsFixed(1)}°',
                                'decl.',
                                Colors.cyan,
                              ),
                              child!, // altitude from GpsService
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  child: Consumer<GpsService>(
                    builder: (context, gpsService, _) => _buildNavDataColumn(
                      Icons.height,
                      gpsService.altitude != null
                          ? '${gpsService.altitude!.toStringAsFixed(0)}'
                          : '--',
                      'meters',
                      gpsService.altitude != null ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Time & Bearing Info Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavDataColumn(
                        Icons.access_time,
                        _currentTime,
                        _currentDate,
                        Colors.amber,
                      ),
                      Selector<CompassProvider, bool>(
                        selector: (_, p) => _showTrueBearing,
                        builder: (context, isTrue, _) => _buildNavDataColumn(
                          isTrue ? Icons.explore : Icons.compass_calibration,
                          isTrue ? 'TRUE' : 'MAG',
                          'north',
                          isTrue ? Colors.blue : Colors.red,
                        ),
                      ),
                      Consumer<GpsService>(
                        builder: (context, gps, _) {
                          if (gps.latitude != null && gps.longitude != null) {
                            return _buildNavDataColumn(
                              Icons.wb_sunny,
                              GeoUtils.calculateSunrise(gps.latitude!, gps.longitude!, DateTime.now()),
                              'sunrise',
                              Colors.orange,
                            );
                          }
                          return _buildNavDataColumn(Icons.wb_sunny, '--:--', 'sunrise', Colors.orange);
                        },
                      ),
                      Consumer<GpsService>(
                        builder: (context, gps, _) {
                          if (gps.latitude != null && gps.longitude != null) {
                            return _buildNavDataColumn(
                              Icons.brightness_2,
                              GeoUtils.calculateSunset(gps.latitude!, gps.longitude!, DateTime.now()),
                              'sunset',
                              Colors.purple,
                            );
                          }
                          return _buildNavDataColumn(Icons.brightness_2, '--:--', 'sunset', Colors.purple);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Elevation
                Consumer<GpsService>(
                  builder: (context, gpsService, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Elevation', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                      const SizedBox(width: 8),
                      Text(
                        gpsService.altitude != null
                            ? '${gpsService.altitude!.toStringAsFixed(1)} m'
                            : '--',
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.info_outline, size: 12, color: Colors.red),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Bearing Type Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBearingToggle(
                        icon: Icons.compass_calibration,
                        label: 'Magnetic',
                        isActive: !_showTrueBearing,
                        onPressed: () => setState(() => _showTrueBearing = false),
                      ),
                      const SizedBox(width: 16),
                      _buildBearingToggle(
                        icon: Icons.explore,
                        label: 'True North',
                        isActive: _showTrueBearing,
                        onPressed: () => setState(() => _showTrueBearing = true),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Consumer<CompassProvider>(
                    builder: (context, provider, _) => Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.navigation,
                            label: 'Waypoints',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const WaypointManagerScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.fiber_manual_record,
                            label: 'Track',
                            color: Colors.red,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TrackRecordingScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.crop_free,
                            label: 'Area',
                            color: Colors.green,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AreaMeasurementScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.aspect_ratio,
                            label: 'Level',
                            color: Colors.purple,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LevelScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 100), // Space for bottom nav
              ],
            ),
          ),

          // Status indicators at top
          Positioned(
            top: 20,
            left: 20,
            right: 60,
            child: Consumer<CompassProvider>(
              builder: (context, provider, _) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        provider.hasGpsLock ? Icons.gps_fixed : Icons.gps_off,
                        color: provider.hasGpsLock ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        provider.hasGpsLock ? 'GPS' : 'No GPS',
                        style: TextStyle(
                          fontSize: 12,
                          color: provider.hasGpsLock ? Colors.green : Colors.red,
                        ),
                      ),
                      if (provider.magneticDisturbance) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.warning, color: Colors.orange, size: 16),
                        const Text(' Metal', style: TextStyle(fontSize: 10, color: Colors.orange)),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      if (provider.accuracy > 0)
                        Text(
                          '±${provider.accuracy.toStringAsFixed(0)}m',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      if (provider.calibrationProgress < 100) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: provider.calibrationProgress / 100,
                            color: Colors.cyan,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Settings icon top right
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
              onPressed: () => _showSettingsBottomSheet(context),
            ),
          ),

          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildNavDataColumn(IconData icon, String value, String unit, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 9,
            color: color.withAlpha((0.7 * 255).round()),
          ),
        ),
      ],
    );
  }

  String _formatCoordinate(double coord, {required bool isLatitude}) {
    final absCoord = coord.abs();
    final degrees = absCoord.floor();
    final minutesFloat = (absCoord - degrees) * 60;
    int minutes = minutesFloat.floor();
    final secondsDouble = (minutesFloat - minutes) * 60;
    int seconds = secondsDouble.floor();
    if (seconds == 60) {
      seconds = 0;
      minutes += 1;
    }

    return '$degrees°${minutes.toString().padLeft(2, '0')}\'${seconds.toString().padLeft(2, '0')}"';
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(
            color: Colors.grey[700]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomNavItem(
            icon: Icons.explore,
            label: 'Compass',
            isActive: true,
            onPressed: () {}, // Already on compass
          ),
          _buildBottomNavItem(
            icon: Icons.map,
            label: 'Map',
            isActive: false,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              );
            },
          ),
          _buildBottomNavItem(
            icon: Icons.navigation,
            label: 'Waypoints',
            isActive: false,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WaypointManagerScreen()),
              );
            },
          ),
          _buildBottomNavItem(
            icon: Icons.build,
            label: 'Tools',
            isActive: false,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ToolsScreen()),
              );
            },
          ),
          _buildBottomNavItem(
            icon: Icons.settings,
            label: 'More',
            isActive: false,
            onPressed: () => _showSettingsBottomSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey[500],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.white : Colors.grey[500],
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildBearingToggle({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isActive ? Colors.cyan.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isActive ? Colors.cyan : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.cyan : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.cyan : Colors.grey[400],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final buttonColor = color ?? Colors.cyan;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.grey[800]!,
              Colors.grey[850]!,
            ],
          ),
          border: Border.all(
            color: buttonColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: buttonColor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text('All Features', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                _menuTile(Icons.camera_alt, 'Camera GPS Tagging', 'Photo with GPS coordinates', Colors.cyan, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraGpsScreen()));
                }),
                _menuTile(Icons.trending_up, 'Slope Calculator', 'Calculate slope between two points', Colors.green, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SlopeCalculatorScreen()));
                }),
                _menuTile(Icons.straighten, 'Distance Measure', 'Measure distance by marking points', Colors.blue, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DistanceMeasureScreen()));
                }),
                _menuTile(Icons.qr_code, 'QR Code Share', 'Share waypoints via QR code', Colors.purple, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const QrShareScreen()));
                }),
                _menuTile(Icons.mic, 'Voice Notes', 'Record voice notes at site', Colors.red, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceNotesScreen()));
                }),
                _menuTile(Icons.aspect_ratio, 'Bubble Level', 'Check surface levelness', Colors.teal, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelScreen()));
                }),
                _menuTile(Icons.fiber_manual_record, 'Track Recording', 'Record your movement path', Colors.redAccent, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackRecordingScreen()));
                }),
                _menuTile(Icons.crop_free, 'Area Measurement', 'Measure area by walking perimeter', Colors.greenAccent, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AreaMeasurementScreen()));
                }),
                _menuTile(Icons.view_in_ar, 'AR Compass', 'See waypoints in AR view', Colors.deepPurple, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ArCompassScreen()));
                }),
                _menuTile(Icons.folder, 'Projects', 'Manage site survey projects', Colors.blue, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectManagerScreen()));
                }),
                _menuTile(Icons.import_export, 'Import/Export', 'KML, GPX, CSV, JSON', Colors.orange, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportExportScreen()));
                }),
                _menuTile(Icons.brightness_6, 'Night Mode', 'Toggle dark/light theme', Colors.amber, () {
                  context.read<ThemeProvider>().toggleTheme();
                  Navigator.pop(context);
                }),
                _menuTile(Icons.height, 'Height Measure', 'Measure object height via angle', Colors.lightGreen, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HeightMeasureScreen()));
                }),
                _menuTile(Icons.terrain, '3D Terrain Viewer', 'View waypoints in 3D', Colors.brown, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TerrainViewerScreen()));
                }),
                _menuTile(Icons.picture_as_pdf, 'PDF Report', 'Generate survey report', Colors.redAccent, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PdfReportScreen()));
                }),
                _menuTile(Icons.swap_horiz, 'Coordinate Converter', 'DD, DMS, UTM formats', Colors.indigo, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CoordinateConverterScreen()));
                }),
                _menuTile(Icons.explore, 'Bearing Line', 'Draw boundary lines on map', Colors.orangeAccent, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BearingLineScreen()));
                }),
                _menuTile(Icons.signal_cellular_alt, 'GPS Strength', 'Signal quality & tips', Colors.lime, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GpsStrengthScreen()));
                }),
                _menuTile(Icons.bookmark, 'Saved Locations', 'Bookmarked places', Colors.pink, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedLocationsScreen()));
                }),
                _menuTile(Icons.cloud_upload, 'Cloud Backup', 'Auto backup to Firebase', Colors.cyanAccent, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CloudBackupScreen()));
                }),
                _menuTile(Icons.settings, 'Settings', 'GPS, compass, data management', Colors.grey, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _NavData {
  final double speed;
  final double accuracy;
  final bool hasGpsLock;
  final double declination;

  const _NavData({
    required this.speed,
    required this.accuracy,
    required this.hasGpsLock,
    required this.declination,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _NavData &&
          runtimeType == other.runtimeType &&
          speed == other.speed &&
          accuracy == other.accuracy &&
          hasGpsLock == other.hasGpsLock &&
          declination == other.declination;

  @override
  int get hashCode => Object.hash(speed, accuracy, hasGpsLock, declination);
}
