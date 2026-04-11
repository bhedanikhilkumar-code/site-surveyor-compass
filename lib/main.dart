import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'models/project_model.dart';
import 'models/tagged_photo.dart';
import 'models/track_model.dart';
import 'models/voice_note_model.dart';
import 'models/waypoint_model.dart';
import 'providers/compass_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/api_waypoint_service.dart';
import 'services/firebase_service.dart';
import 'services/gps_service.dart';
import 'services/waypoint_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Request required permissions upfront
    await _requestPermissions();
    
    // Initialize Firebase (optional - app works without it)
    try {
      await Firebase.initializeApp();
     } on Exception catch (e) {
       // debugPrint('Firebase initialization failed: $e - Using offline mode');
     }
   } on Exception catch (e) {
      // debugPrint('Initialization error: $e');
   }
  
  try {
    // Initialize Hive for local storage
    await Hive.initFlutter();
    Hive.registerAdapter(WaypointAdapter());
    Hive.registerAdapter(TrackPointAdapter());
    Hive.registerAdapter(TrackAdapter());
    Hive.registerAdapter(SiteProjectAdapter());
    Hive.registerAdapter(VoiceNoteAdapter());
    Hive.registerAdapter(TaggedPhotoAdapter());
    
    // Initialize services
    final waypointService = WaypointService();
    await waypointService.initialize();
    
    final firebaseService = FirebaseService();
    final apiWaypointService = ApiWaypointService(
      localService: waypointService,
      firebaseService: firebaseService,
    );
    await apiWaypointService.initialize();

    // Initialize compass provider
    final compassProvider = CompassProvider();
    final themeProvider = ThemeProvider();

    runApp(SiteSurveyorCompassApp(
      apiWaypointService: apiWaypointService,
      compassProvider: compassProvider,
      themeProvider: themeProvider,
    ));
   } on Exception catch (e) {
      // debugPrint('App initialization error: $e');
   }
}

Future<void> _requestPermissions() async {
  // Request permissions with web compatibility
  try {
    // Request location and sensor permissions
    final status = await Permission.locationWhenInUse.request();
    final sensorStatus = await Permission.sensors.request();
    
    // Check if location permissions are granted
    if (status.isDenied) {
      // Location permission denied - GPS will not work
    } else {
      // Location permission granted - GPS enabled
    }

    if (sensorStatus.isDenied) {
      // Sensor permission denied - Compass may not work
    } else {
      // Sensor permission granted - Compass enabled
    }
   } on Exception catch (e) {
      // debugPrint('Permission request error: $e - Continue anyway - app can work with limited functionality');
   }
}

class SiteSurveyorCompassApp extends StatelessWidget {
  final ApiWaypointService apiWaypointService;
  final CompassProvider compassProvider;
  final ThemeProvider themeProvider;

  const SiteSurveyorCompassApp({
    super.key,
    required this.apiWaypointService,
    required this.compassProvider,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: compassProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(
          create: (context) {
            final gpsService = GpsService();
            gpsService.setCompassProvider(compassProvider);
            return gpsService;
          },
        ),
        Provider<ApiWaypointService>(create: (_) => apiWaypointService),
      ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) => MaterialApp(
            title: 'Site Surveyor Compass',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.getLightTheme(),
            darkTheme: themeProvider.getDarkTheme(),
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
          ),
        ),
    );
  }
}
