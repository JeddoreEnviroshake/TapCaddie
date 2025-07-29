import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'src/services/auth_service.dart';
import 'src/services/firestore_service.dart';
import 'src/services/location_service.dart';
import 'src/services/nfc_service.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/game_provider.dart';
import 'src/providers/analytics_provider.dart';
import 'src/config/app_theme.dart';
import 'src/config/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const TapCaddieApp());
}

class TapCaddieApp extends StatelessWidget {
  const TapCaddieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<NFCService>(create: (_) => NFCService()),
        
        // State Providers
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            authService: context.read<AuthService>(),
            firestoreService: context.read<FirestoreService>(),
          ),
        ),
        ChangeNotifierProvider<GameProvider>(
          create: (context) => GameProvider(
            firestoreService: context.read<FirestoreService>(),
            locationService: context.read<LocationService>(),
            nfcService: context.read<NFCService>(),
          ),
        ),
        ChangeNotifierProvider<AnalyticsProvider>(
          create: (context) => AnalyticsProvider(
            firestoreService: context.read<FirestoreService>(),
          ),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'TapCaddie',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: AppRouter.router(authProvider),
          );
        },
      ),
    );
  }
}