import 'package:flutter/material.dart';
import 'dart:ui';
import '../providers/theme_provider.dart';
import '../screens/camera_gps_screen.dart';
import '../screens/slope_calculator_screen.dart';
import '../screens/distance_measure_screen.dart';
import '../screens/qr_share_screen.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/excel_export_screen.dart';
import '../screens/voice_notes_screen.dart';
import '../screens/track_recording_screen.dart';
import '../screens/area_measurement_screen.dart';
import '../screens/ar_compass_screen.dart';
import '../screens/project_manager_screen.dart';
import '../screens/import_export_screen.dart';
import '../screens/height_measure_screen.dart';
import '../screens/terrain_viewer_screen.dart';
import '../screens/pdf_report_screen.dart';
import '../screens/coordinate_converter_screen.dart';
import '../screens/bearing_line_screen.dart';
import '../screens/gps_strength_screen.dart';
import '../screens/saved_locations_screen.dart';
import '../screens/cloud_backup_screen.dart';
import '../screens/offline_maps_screen.dart';
import '../screens/data_sync_screen.dart';
import '../screens/survey_forms_screen.dart';
import '../screens/geofencing_screen.dart';
import '../screens/export_formats_screen.dart';
import '../screens/language_settings_screen.dart';
import '../screens/bluetooth_gps_screen.dart';
import '../screens/settings_screen.dart';

void showSettingsBottomSheet(BuildContext context, VoidCallback onThemeToggle) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => SettingsBottomSheet(
      onThemeToggle: onThemeToggle,
    ),
  );
}

class SettingsBottomSheet extends StatelessWidget {
  final VoidCallback onThemeToggle;

  const SettingsBottomSheet({
    Key? key,
    required this.onThemeToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraGpsScreen()));
                    }),
                    _settingsTile(Icons.trending_up, 'Slope Calculator', 'Calculate slope between two points', Colors.greenAccent, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SlopeCalculatorScreen()));
                    }),
                    _settingsTile(Icons.straighten, 'Distance Measure', 'Measure distance by marking points', Colors.blueAccent, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const DistanceMeasureScreen()));
                    }),
                    _settingsTile(Icons.qr_code, 'QR Code Share', 'Share waypoints via QR code', Colors.purpleAccent, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const QrShareScreen()));
                    }),
                    _settingsTile(Icons.qr_code_scanner, 'QR Code Scanner', 'Scan waypoints from QR codes', Colors.deepPurpleAccent, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScannerScreen()));
                    }),
                    _settingsTile(Icons.table_chart, 'Excel Export', 'Export data to Excel spreadsheet', Colors.tealAccent, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ExcelExportScreen()));
                    }),
                    _settingsTile(Icons.mic, 'Voice Notes', 'Record voice notes at site', Colors.redAccent, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const VoiceNotesScreen()));
                    }),
                    _settingsTile(Icons.fiber_manual_record, 'Track Recording', 'Record your movement path', Colors.red, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TrackRecordingScreen()));
                    }),
                    _settingsTile(Icons.crop_free, 'Area Measurement', 'Measure area by walking perimeter', Colors.green, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AreaMeasurementScreen()));
                    }),
                    _settingsTile(Icons.view_in_ar, 'AR Compass', 'See waypoints in AR view', Colors.deepPurple, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ArCompassScreen()));
                    }),
                    _settingsTile(Icons.folder, 'Projects', 'Manage site survey projects', Colors.blue, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectManagerScreen()));
                    }),
                    _settingsTile(Icons.import_export, 'Import/Export', 'KML, GPX, CSV, JSON', Colors.orange, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ImportExportScreen()));
                    }),
                    _settingsTile(Icons.brightness_6, 'Night Mode', 'Toggle dark/light theme', Colors.amber, () {
                      onThemeToggle();
                      Navigator.pop(context);
                    }),
                    _settingsTile(Icons.height, 'Height Measure', 'Measure object height via angle', Colors.lightGreen, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HeightMeasureScreen()));
                    }),
                    _settingsTile(Icons.terrain, '3D Terrain Viewer', 'View waypoints in 3D', Colors.brown, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TerrainViewerScreen()));
                    }),
                    _settingsTile(Icons.picture_as_pdf, 'PDF Report', 'Generate survey report', Colors.redAccent, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PdfReportScreen()));
                    }),
                    _settingsTile(Icons.swap_horiz, 'Coordinate Converter', 'DD, DMS, UTM formats', Colors.indigo, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CoordinateConverterScreen()));
                    }),
                    _settingsTile(Icons.explore, 'Bearing Line', 'Draw boundary lines on map', Colors.orangeAccent, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const BearingLineScreen()));
                    }),
                    _settingsTile(Icons.signal_cellular_alt, 'GPS Strength', 'Signal quality & tips', Colors.lime, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const GpsStrengthScreen()));
                    }),
                    _settingsTile(Icons.bookmark, 'Saved Locations', 'Bookmarked places', Colors.pink, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedLocationsScreen()));
                    }),
                    _settingsTile(Icons.cloud_upload, 'Cloud Backup', 'Auto backup to Firebase', Colors.cyan, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CloudBackupScreen()));
                    }),
                    _settingsTile(Icons.download_for_offline, 'Offline Maps', 'Download maps for offline use', Colors.blue, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const OfflineMapsScreen()));
                    }),
                    _settingsTile(Icons.sync, 'Data Sync', 'Sync data with cloud storage', Colors.purple, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const DataSyncScreen()));
                    }),
                    _settingsTile(Icons.description, 'Survey Forms', 'Create custom survey forms', Colors.teal, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SurveyFormsScreen()));
                    }),
                    _settingsTile(Icons.location_searching, 'Geofencing', 'Zone alerts for locations', Colors.indigo, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const GeofencingScreen()));
                    }),
                    _settingsTile(Icons.file_download, 'Export Formats', 'Export KML, GPX, CSV', Colors.green, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ExportFormatsScreen()));
                    }),
                    _settingsTile(Icons.language, 'Language', 'Change app language', Colors.amber, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSettingsScreen()));
                    }),
                    _settingsTile(Icons.bluetooth, 'Bluetooth GPS', 'Connect external GPS', Colors.cyanAccent, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const BluetoothGpsScreen()));
                    }),
                    _settingsTile(Icons.settings, 'Settings', 'GPS, compass, data management', Colors.grey, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
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