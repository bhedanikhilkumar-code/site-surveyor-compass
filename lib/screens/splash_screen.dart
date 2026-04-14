import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/project_model.dart';
import '../models/tagged_photo.dart';
import '../models/track_model.dart';
import '../models/voice_note_model.dart';
import '../models/waypoint_model.dart';
import '../providers/auth_provider.dart';
import '../providers/compass_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/home_screen.dart';
import '../widgets/auth_wrapper.dart';
import '../services/api_waypoint_service.dart';
import '../services/firebase_service.dart';
import '../services/gps_service.dart';
import '../services/waypoint_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Request required permissions upfront
      await _requestPermissions();

      // Initialize Firebase (optional - app works without it)
      try {
        await Firebase.initializeApp();
      } on Exception catch (e) {
        // Firebase initialization failed - Using offline mode
      }
    } on Exception catch (e) {
      // Initialization error - Continue anyway
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

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SiteSurveyorCompassApp(
            apiWaypointService: apiWaypointService,
            compassProvider: compassProvider,
            themeProvider: themeProvider,
          ),
        ),
      );
    } on Exception catch (e) {
      // App initialization error - Show error and retry or exit
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Initialization failed: $e')),
        );
        // Optionally navigate to a basic home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
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
      // Permission request error - Continue anyway - app can work with limited functionality
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.lightBlueAccent],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Icon(
                Icons.explore,
                size: 120,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'Site Surveyor Compass',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Precision digital compass for construction site surveying',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Initializing...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
          home: const AuthWrapper(),
        ),
      ),
    );
  }
}