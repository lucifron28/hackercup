import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/firebase_realtime_provider.dart';
import 'core/providers/driver_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase only on mobile platforms
  if (defaultTargetPlatform == TargetPlatform.android || 
      defaultTargetPlatform == TargetPlatform.iOS) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully');
      // Initialize Notifications only if Firebase is available
      await NotificationService.initialize();
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  }
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  runApp(
    MultiProvider(
      providers: [
        // Core Providers
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(),
        ),
        ChangeNotifierProvider<LocationProvider>(
          create: (context) => LocationProvider(),
        ),
        ChangeNotifierProvider<FirebaseRealtimeProvider>(
          create: (context) => FirebaseRealtimeProvider(),
        ),
        // Driver Provider
        ChangeNotifierProvider<DriverProvider>(
          create: (context) => DriverProvider(),
        ),
      ],
      child: const JeepneyTrackerApp(),
    ),
  );
}

class JeepneyTrackerApp extends StatelessWidget {
  const JeepneyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Jeepney Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      
      // Internationalization
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('tl', ''), // Tagalog
      ],
      
      // Router
      routerConfig: AppRouter.router,
      
      debugShowCheckedModeBanner: false,
    );
  }
}
