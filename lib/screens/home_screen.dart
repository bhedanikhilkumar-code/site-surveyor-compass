import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/compass_provider.dart';
import '../providers/theme_provider.dart';
import '../services/gps_service.dart';
import '../widgets/compass_dial.dart';
import '../widgets/glass_container.dart';

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
  String _currentTime = '';
  String _currentDate = '';
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());

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

  void _updateClock() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _currentDate = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
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
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GlassContainer(
                blur: 5,
                opacity: 0.05,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 24),
                  onPressed: () => _showSettingsBottomSheet(context),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildGlassNavigation(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        blur: 8,
        opacity: 0.08,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Consumer<CompassProvider>(
          builder: (context, provider, _) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: provider.hasGpsLock ? Colors.greenAccent : Colors.redAccent,
                      boxShadow: [
                        BoxShadow(
                          color: (provider.hasGpsLock ? Colors.greenAccent : Colors.redAccent).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    provider.hasGpsLock ? 'GPS Lock' : 'No GPS',
                    style: TextStyle(
                      fontSize: 13,
                      color: provider.hasGpsLock ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (provider.magneticDisturbance) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.warning_amber, color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      'Magnetic',
                      style: TextStyle(fontSize: 11, color: Colors.orangeAccent),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  if (provider.accuracy > 0)
                    Text(
                      '±${provider.accuracy.toStringAsFixed(0)}m',
                      style: const TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                  if (provider.calibrationProgress < 100) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: provider.calibrationProgress / 100,
                        color: Colors.cyanAccent,
                      ),
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
        return Column(
          children: [
            GlassContainer(
              blur: 15,
              opacity: 0.08,
              borderRadius: BorderRadius.circular(30),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CompassDial(bearing: bearing),
                  const SizedBox(height: 16),
                  Text(
                    context.read<CompassProvider>().getCardinalDirection(bearing),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${bearing.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white60,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCoordinatesCard() {
    return GlassContainer(
      blur: 10,
      opacity: 0.08,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(20),
      child: Consumer<GpsService>(
        builder: (context, gpsService, _) => Column(
          children: [
            const Text(
              'COORDINATES',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white38,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
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
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white24,
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
                style: const TextStyle(fontSize: 11, color: Colors.white54),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinateItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white38,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildNavDataCard() {
    return GlassContainer(
      blur: 10,
      opacity: 0.08,
      borderRadius: BorderRadius.circular(20),
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
                navData.hasGpsLock ? Colors.greenAccent : Colors.orangeAccent,
              ),
              _buildNavItem(
                Icons.gps_fixed,
                navData.accuracy > 0 ? '${navData.accuracy.toStringAsFixed(0)}' : '--',
                'accuracy',
                navData.hasGpsLock ? Colors.cyanAccent : Colors.redAccent,
              ),
              _buildNavItem(
                Icons.compass_calibration,
                '${navData.declination.toStringAsFixed(1)}°',
                'declination',
                Colors.purpleAccent,
              ),
              Consumer<GpsService>(
                builder: (context, gps, _) => _buildNavItem(
                  Icons.height,
                  gps.altitude != null ? '${gps.altitude!.toStringAsFixed(0)}' : '--',
                  'altitude',
                  gpsServiceAltitudeColor(gps.altitude),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String value, String unit, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
          ),
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
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white38,
          ),
        ),
      ],
    );
  }

  Color gpsServiceAltitudeColor(double? altitude) {
    return altitude != null ? Colors.blueAccent : Colors.grey;
  }

  Widget _buildTimeSunCard() {
    return GlassContainer(
      blur: 10,
      opacity: 0.08,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTimeItem(Icons.access_time, _currentTime, _currentDate, Colors.amberAccent),
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
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white38,
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
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildBearingToggleSmall() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Selector<CompassProvider, bool>(
            selector: (_, p) => _showTrueBearing,
            builder: (context, isTrue, _) => Row(
              children: [
                Icon(
                  isTrue ? Icons.explore : Icons.compass_calibration,
                  color: isTrue ? Colors.blueAccent : Colors.redAccent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isTrue ? 'TRUE' : 'MAG',
                  style: TextStyle(
                    fontSize: 12,
                    color: isTrue ? Colors.blueAccent : Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBearingToggle() {
    return GlassContainer(
      blur: 8,
      opacity: 0.08,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildToggleButton(
            icon: Icons.compass_calibration,
            label: 'Magnetic',
            isActive: !_showTrueBearing,
            color: Colors.redAccent,
            onPressed: () => setState(() => _showTrueBearing = false),
          ),
          const SizedBox(width: 12),
          _buildToggleButton(
            icon: Icons.explore,
            label: 'True North',
            isActive: _showTrueBearing,
            color: Colors.blueAccent,
            onPressed: () => setState(() => _showTrueBearing = true),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isActive ? color : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? color : Colors.white38, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? color : Colors.white38,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassContainer(
        blur: 10,
        opacity: 0.08,
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white38,
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
                    color: Colors.cyanAccent,
                    onPressed: () => _navigateTo(const WaypointManagerScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.fiber_manual_record,
                    label: 'Track',
                    color: Colors.redAccent,
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
                    color: Colors.greenAccent,
                    onPressed: () => _navigateTo(const AreaMeasurementScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.aspect_ratio,
                    label: 'Level',
                    color: Colors.purpleAccent,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Widget _buildGlassNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItemGlass(Icons.explore, 'Compass', true, () {}),
                _buildNavItemGlass(Icons.map, 'Map', false, () => _navigateTo(const MapScreen())),
                _buildNavItemGlass(Icons.navigation, 'Points', false, () => _navigateTo(const WaypointManagerScreen())),
                _buildNavItemGlass(Icons.build, 'Tools', false, () => _navigateTo(const ToolsScreen())),
                _buildNavItemGlass(Icons.more_horiz, 'More', false, () => _showSettingsBottomSheet(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItemGlass(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white54,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? Colors.white : Colors.white54,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
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

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e).withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ALL FEATURES',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _settingsTile(Icons.camera_alt, 'Camera GPS Tagging', 'Photo with GPS coordinates', Colors.cyanAccent, () {
                        Navigator.pop(context);
                        _navigateTo(const CameraGpsScreen());
                      }),
                      _settingsTile(Icons.trending_up, 'Slope Calculator', 'Calculate slope between two points', Colors.greenAccent, () {
                        Navigator.pop(context);
                        _navigateTo(const SlopeCalculatorScreen());
                      }),
                      _settingsTile(Icons.straighten, 'Distance Measure', 'Measure distance by marking points', Colors.blueAccent, () {
                        Navigator.pop(context);
                        _navigateTo(const DistanceMeasureScreen());
                      }),
                      _settingsTile(Icons.qr_code, 'QR Code Share', 'Share waypoints via QR code', Colors.purpleAccent, () {
                        Navigator.pop(context);
                        _navigateTo(const QrShareScreen());
                      }),
                      _settingsTile(Icons.qr_code_scanner, 'QR Code Scanner', 'Scan waypoints from QR codes', Colors.deepPurpleAccent, () {
                        Navigator.pop(context);
                        _navigateTo(const QrScannerScreen());
                      }),
                      _settingsTile(Icons.table_chart, 'Excel Export', 'Export data to Excel spreadsheet', Colors.tealAccent, () {
                        Navigator.pop(context);
                        _navigateTo(const ExcelExportScreen());
                      }),
                      _settingsTile(Icons.mic, 'Voice Notes', 'Record voice notes at site', Colors.redAccent, () {
                        Navigator.pop(context);
                        _navigateTo(const VoiceNotesScreen());
                      }),
                      _settingsTile(Icons.fiber_manual_record, 'Track Recording', 'Record your movement path', Colors.red, () {
                        Navigator.pop(context);
                        _navigateTo(const TrackRecordingScreen());
                      }),
                      _settingsTile(Icons.crop_free, 'Area Measurement', 'Measure area by walking perimeter', Colors.green, () {
                        Navigator.pop(context);
                        _navigateTo(const AreaMeasurementScreen());
                      }),
                      _settingsTile(Icons.view_in_ar, 'AR Compass', 'See waypoints in AR view', Colors.deepPurple, () {
                        Navigator.pop(context);
                        _navigateTo(const ArCompassScreen());
                      }),
                      _settingsTile(Icons.folder, 'Projects', 'Manage site survey projects', Colors.blue, () {
                        Navigator.pop(context);
                        _navigateTo(const ProjectManagerScreen());
                      }),
                      _settingsTile(Icons.import_export, 'Import/Export', 'KML, GPX, CSV, JSON', Colors.orange, () {
                        Navigator.pop(context);
                        _navigateTo(const ImportExportScreen());
                      }),
                      _settingsTile(Icons.brightness_6, 'Night Mode', 'Toggle dark/light theme', Colors.amber, () {
                        context.read<ThemeProvider>().toggleTheme();
                        Navigator.pop(context);
                      }),
                      _settingsTile(Icons.height, 'Height Measure', 'Measure object height via angle', Colors.lightGreen, () {
                        Navigator.pop(context);
                        _navigateTo(const HeightMeasureScreen());
                      }),
                      _settingsTile(Icons.terrain, '3D Terrain Viewer', 'View waypoints in 3D', Colors.brown, () {
                        Navigator.pop(context);
                        _navigateTo(const TerrainViewerScreen());
                      }),
                      _settingsTile(Icons.picture_as_pdf, 'PDF Report', 'Generate survey report', Colors.redAccent, () {
                        Navigator.pop(context);
                        _navigateTo(const PdfReportScreen());
                      }),
                      _settingsTile(Icons.swap_horiz, 'Coordinate Converter', 'DD, DMS, UTM formats', Colors.indigo, () {
                        Navigator.pop(context);
                        _navigateTo(const CoordinateConverterScreen());
                      }),
                      _settingsTile(Icons.explore, 'Bearing Line', 'Draw boundary lines on map', Colors.orangeAccent, () {
                        Navigator.pop(context);
                        _navigateTo(const BearingLineScreen());
                      }),
                      _settingsTile(Icons.signal_cellular_alt, 'GPS Strength', 'Signal quality & tips', Colors.lime, () {
                        Navigator.pop(context);
                        _navigateTo(const GpsStrengthScreen());
                      }),
                      _settingsTile(Icons.bookmark, 'Saved Locations', 'Bookmarked places', Colors.pink, () {
                        Navigator.pop(context);
                        _navigateTo(const SavedLocationsScreen());
                      }),
                      _settingsTile(Icons.cloud_upload, 'Cloud Backup', 'Auto backup to Firebase', Colors.cyan, () {
                        Navigator.pop(context);
                        _navigateTo(const CloudBackupScreen());
                      }),
                      _settingsTile(Icons.download_for_offline, 'Offline Maps', 'Download maps for offline use', Colors.blue, () {
                        Navigator.pop(context);
                        _navigateTo(const OfflineMapsScreen());
                      }),
                      _settingsTile(Icons.sync, 'Data Sync', 'Sync data with cloud storage', Colors.purple, () {
                        Navigator.pop(context);
                        _navigateTo(const DataSyncScreen());
                      }),
                      _settingsTile(Icons.description, 'Survey Forms', 'Create custom survey forms', Colors.teal, () {
                        Navigator.pop(context);
                        _navigateTo(const SurveyFormsScreen());
                      }),
                      _settingsTile(Icons.location_searching, 'Geofencing', 'Zone alerts for locations', Colors.indigo, () {
                        Navigator.pop(context);
                        _navigateTo(const GeofencingScreen());
                      }),
                      _settingsTile(Icons.file_download, 'Export Formats', 'Export KML, GPX, CSV', Colors.green, () {
                        Navigator.pop(context);
                        _navigateTo(const ExportFormatsScreen());
                      }),
                      _settingsTile(Icons.language, 'Language', 'Change app language', Colors.amber, () {
                        Navigator.pop(context);
                        _navigateTo(const LanguageSettingsScreen());
                      }),
                      _settingsTile(Icons.bluetooth, 'Bluetooth GPS', 'Connect external GPS', Colors.cyanAccent, () {
                        Navigator.pop(context);
                        _navigateTo(const BluetoothGpsScreen());
                      }),
                      _settingsTile(Icons.settings, 'Settings', 'GPS, compass, data management', Colors.grey, () {
                        Navigator.pop(context);
                        _navigateTo(const SettingsScreen());
                      }),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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