import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'providers/compass_provider.dart';
import 'providers/theme_provider.dart';
import 'models/waypoint_model.dart';
import 'models/track_model.dart';
import 'models/project_model.dart';
import 'services/gps_service.dart';
import 'services/waypoint_service.dart';
import 'services/firebase_service.dart';
import 'services/api_waypoint_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request required permissions upfront
  await _requestPermissions();
  
  // Initialize Firebase (optional - app works without it)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization failed: $e - Using offline mode');
  }
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  Hive.registerAdapter(WaypointAdapter());
  Hive.registerAdapter(TrackPointAdapter());
  Hive.registerAdapter(TrackAdapter());
  Hive.registerAdapter(SiteProjectAdapter());
  
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
}

Future<void> _requestPermissions() async {
  // Request all required permissions for GPS and sensors
  final statuses = await [
    Permission.location,
    Permission.locationWhenInUse,
    Permission.locationAlways,
    Permission.sensors,
  ].request();

  // Check if location permissions are granted
  if (statuses[Permission.location]!.isDenied ||
      statuses[Permission.locationWhenInUse]!.isDenied) {
    print('Location permission denied - GPS will not work');
  } else {
    print('Location permission granted - GPS enabled');
  }

  if (statuses[Permission.sensors]!.isDenied) {
    print('Sensor permission denied - Compass may not work');
  } else {
    print('Sensor permission granted - Compass enabled');
  }
}

class SiteSurveyorCompassApp extends StatelessWidget {
  final ApiWaypointService apiWaypointService;
  final CompassProvider compassProvider;
  final ThemeProvider themeProvider;

  const SiteSurveyorCompassApp({
    Key? key,
    required this.apiWaypointService,
    required this.compassProvider,
    required this.themeProvider,
  }) : super(key: key);

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
        builder: (context, theme, _) => MaterialApp(
          title: 'Site Surveyor Compass',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueAccent,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueAccent,
              brightness: Brightness.dark,
            ),
          ),
          themeMode: theme.themeMode,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
