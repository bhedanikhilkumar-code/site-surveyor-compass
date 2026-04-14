import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../providers/auth_provider.dart';
import '../providers/compass_provider.dart';
import '../providers/theme_provider.dart';
import '../services/gps_service.dart';
import '../widgets/compass_dial.dart';
import '../widgets/settings_bottom_sheet.dart';

import '../utils/geo_utils.dart';
import '../utils/app_constants.dart';
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
import 'qr_scanner_screen.dart';
import 'excel_export_screen.dart';
import 'offline_maps_screen.dart';
import 'data_sync_screen.dart';
import 'survey_forms_screen.dart';
import 'geofencing_screen.dart';
import 'export_formats_screen.dart';
import 'language_settings_screen.dart';
import 'bluetooth_gps_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _showTrueBearing = true;
  int _selectedIndex = 0;
  late SpeechToText _speechToText;

  @override
  void initState() {
    super.initState();
    _speechToText = SpeechToText();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final gpsService = context.read<GpsService>();
      await gpsService.getInitialPosition();
      await gpsService.startLocationUpdates(
        accuracy: LocationAccuracy.bestForNavigation,
        intervalMs: 1000,
        distanceFilterMeters: 2,
      );
    });
  }



  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final compassProvider = context.read<CompassProvider>();
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      compassProvider.pauseSensors();
    } else if (state == AppLifecycleState.resumed) {
      compassProvider.resumeSensors();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleVoiceCommand(BuildContext context) async {
    if (await _speechToText.initialize()) {
      _speechToText.listen(onResult: (result) {
        final command = result.recognizedWords.toLowerCase();
        if (command.contains('start tracking')) {
          setState(() {
            _selectedIndex = 4; // Assuming track recording is at index 4
          });
        } else if (command.contains('add waypoint')) {
          setState(() {
            _selectedIndex = 1; // Assuming waypoint manager is at index 1
          });
        } else if (command.contains('calculate area')) {
          setState(() {
            _selectedIndex = 3; // Assuming area measurement is at index 3
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice command not recognized: $command')),
          );
        }
        _speechToText.stop();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoCompass Pro'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () => _handleVoiceCommand(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => showSettingsBottomSheet(context, () => context.read<ThemeProvider>().toggleTheme()),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusBar(),
                  const SizedBox(height: 24),
                  _buildCompassSection(),
                  const SizedBox(height: 24),
                  _buildCoordinatesCard(),
                  const SizedBox(height: 16),
                  _buildNavDataCard(),
                  const SizedBox(height: 16),
                  _buildTimeSunCard(),
                  const SizedBox(height: 16),
                  _buildBearingToggle(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                ],
              ),
            ),
            const MapScreen(),
            const WaypointManagerScreen(),
            const ToolsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildStatusBar() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  const SizedBox(width: 8),
                  Text(
                    provider.hasGpsLock ? 'GPS Lock' : 'No GPS',
                    style: TextStyle(
                      fontSize: 14,
                      color: provider.hasGpsLock ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (provider.magneticDisturbance) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      'Magnetic Interference',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  if (provider.accuracy > 0)
                    Text(
                      '±${provider.accuracy.toStringAsFixed(0)}m',
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                   if (provider.calibrationProgress < 100) ...[
                     const SizedBox(width: 12),
                     Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Text(
                           'Calibrating... Rotate in figure-8',
                           style: TextStyle(fontSize: 12, color: Colors.blue),
                         ),
                         SizedBox(
                           width: 20,
                           height: 20,
                           child: CircularProgressIndicator(
                             strokeWidth: 2,
                             value: provider.calibrationProgress / 100,
                             color: Colors.blue,
                           ),
                         ),
                       ],
                     ),
                   ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompassSection() {
    return Selector<CompassProvider, double>(
      selector: (_, provider) => _showTrueBearing ? provider.trueBearing : provider.bearing,
      builder: (context, bearing, _) {
        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CompassDial(bearing: bearing),
                const SizedBox(height: 16),
                Text(
                  context.read<CompassProvider>().getCardinalDirection(bearing),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${bearing.toStringAsFixed(1)}°',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoordinatesCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Consumer<GpsService>(
          builder: (context, gpsService, _) => Column(
            children: [
              Text(
                'COORDINATES',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCoordinateItem(
                    'LATITUDE',
                    gpsService.latitude != null
                        ? _formatCoordinate(gpsService.latitude!.abs(), isLatitude: true) +
                          (gpsService.latitude! >= 0 ? ' N' : ' S')
                        : '--',
                  ),
                  VerticalDivider(
                    width: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                  _buildCoordinateItem(
                    'LONGITUDE',
                    gpsService.longitude != null
                        ? _formatCoordinate(gpsService.longitude!.abs(), isLatitude: false) +
                          (gpsService.longitude! >= 0 ? ' E' : ' W')
                        : '--',
                  ),
                ],
              ),
              if (gpsService.address != null) ...[
                const SizedBox(height: 12),
                Text(
                  gpsService.address!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoordinateItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavDataCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Selector<CompassProvider, _NavData>(
          selector: (_, p) => _NavData(
            speed: p.speed,
            accuracy: p.accuracy,
            hasGpsLock: p.hasGpsLock,
            declination: p.magneticDeclination,
          ),
          builder: (context, navData, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  Icons.speed,
                  '${navData.speed.toStringAsFixed(1)}',
                  'km/h',
                  navData.hasGpsLock ? Colors.green : Colors.orange,
                ),
                _buildNavItem(
                  Icons.gps_fixed,
                  navData.accuracy > 0 ? '${navData.accuracy.toStringAsFixed(0)}' : '--',
                  'accuracy',
                  navData.hasGpsLock ? Colors.blue : Colors.red,
                ),
                _buildNavItem(
                  Icons.compass_calibration,
                  '${navData.declination.toStringAsFixed(1)}°',
                  'declination',
                  Colors.purple,
                ),
                Consumer<GpsService>(
                  builder: (context, gps, _) => _buildNavItem(
                    Icons.height,
                    gps.altitude != null ? '${gps.altitude!.toStringAsFixed(0)}' : '--',
                    'altitude',
                    gps.altitude != null ? Colors.teal : Colors.grey,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String value, String unit, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          unit,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Color gpsServiceAltitudeColor(double? altitude) {
    return altitude != null ? Colors.blueAccent : Colors.grey;
  }

  Widget _buildTimeSunCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const ClockWidget(),
            _buildBearingToggleSmall(),
            Consumer<GpsService>(
              builder: (context, gps, _) {
                if (gps.latitude != null && gps.longitude != null) {
                  return Row(
                    children: [
                      _buildSunItem(
                        Icons.wb_sunny,
                        GeoUtils.calculateSunrise(gps.latitude!, gps.longitude!, DateTime.now()),
                        'Sunrise',
                        Colors.orange,
                      ),
                      const SizedBox(width: 24),
                      _buildSunItem(
                        Icons.nights_stay,
                        GeoUtils.calculateSunset(gps.latitude!, gps.longitude!, DateTime.now()),
                        'Sunset',
                        Colors.indigo,
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeItem(IconData icon, String time, String date, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 20,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          date,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildSunItem(IconData icon, String time, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildBearingToggleSmall() {
    return ActionChip(
      label: Selector<CompassProvider, bool>(
        selector: (_, p) => _showTrueBearing,
        builder: (context, isTrue, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isTrue ? Icons.explore : Icons.compass_calibration,
              color: isTrue ? Colors.blue : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              isTrue ? 'TRUE' : 'MAG',
              style: TextStyle(
                fontSize: 12,
                color: isTrue ? Colors.blue : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      onPressed: () => setState(() => _showTrueBearing = !_showTrueBearing),
    );
  }

  Widget _buildBearingToggle() {
    return Center(
      child: ToggleButtons(
        isSelected: [!_showTrueBearing, _showTrueBearing],
        onPressed: (index) => setState(() => _showTrueBearing = index == 1),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.compass_calibration, color: !_showTrueBearing ? Colors.red : null),
                const SizedBox(width: 8),
                Text('Magnetic'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.explore, color: _showTrueBearing ? Colors.blue : null),
                const SizedBox(width: 8),
                Text('True North'),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'QUICK ACTIONS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.navigation,
                    label: 'Waypoints',
                    color: Colors.cyan,
                    onPressed: () => _navigateTo(const WaypointManagerScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.fiber_manual_record,
                    label: 'Track',
                    color: Colors.red,
                    onPressed: () => _navigateTo(const TrackRecordingScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.crop_free,
                    label: 'Area',
                    color: Colors.green,
                    onPressed: () => _navigateTo(const AreaMeasurementScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.aspect_ratio,
                    label: 'Level',
                    color: Colors.purple,
                    onPressed: () => _navigateTo(const LevelScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Compass'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        BottomNavigationBarItem(icon: Icon(Icons.navigation), label: 'Points'),
        BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Tools'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
      ],
      onTap: (index) {
        if (index == 4) {
          showSettingsBottomSheet(context, () => context.read<ThemeProvider>().toggleTheme());
        } else {
          setState(() => _selectedIndex = index);
        }
      },
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



  Widget _settingsTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.1),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.2),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
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

class ClockWidget extends StatefulWidget {
  const ClockWidget({Key? key}) : super(key: key);

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  String _currentTime = '';
  String _currentDate = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateClock() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _currentDate = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.access_time, color: Colors.amber, size: 24),
        const SizedBox(height: 4),
        Text(
          _currentTime,
          style: TextStyle(
            fontSize: 20,
            color: Colors.amber,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          _currentDate,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
