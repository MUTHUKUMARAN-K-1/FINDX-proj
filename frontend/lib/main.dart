import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:frontend/api/items_repository.dart';
import 'package:frontend/blocs/items/items_bloc.dart';
import 'package:frontend/blocs/items/items_event.dart';
import 'package:frontend/blocs/auth/auth_bloc.dart';
import 'package:frontend/services/location_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/fcm_service.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/utils/routes.dart';
import 'package:frontend/firebase_options.dart';
import 'package:go_router/go_router.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📬 Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Firestore offline persistence for caching
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Catch Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('⚠️ Flutter Error: ${details.exception}');
  };

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _locationInitialized = false;
  final FcmService _fcmService = FcmService();

  @override
  void initState() {
    super.initState();
    // Initialize location and FCM after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
      _initializeFcm();
    });
  }

  Future<void> _initializeFcm() async {
    await _fcmService.init();
    // Force save token immediately for current user (if logged in)
    await _fcmService.forceSaveToken();
  }

  Future<void> _initializeLocation() async {
    if (!_locationInitialized) {
      final success = await LocationService().initializeAndSaveLocation();
      if (success) {
        setState(() => _locationInitialized = true);
        print('✅ Location service started - updating every 2 minutes');
      } else {
        print('⚠️ Location service failed to initialize');
        // Show dialog after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          _showLocationPermissionDialog();
        });
      }
    }
  }

  void _showLocationPermissionDialog() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.location_on,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Enable Location'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FindX needs location access to help you find lost items nearby.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'On Windows, please enable location in:\nSettings → Privacy → Location',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Try again
                final success = await LocationService()
                    .initializeAndSaveLocation();
                if (success) {
                  setState(() => _locationInitialized = true);
                }
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppRouter appRouter = AppRouter();
    final ItemsRepository itemsRepository = ItemsRepository();
    final AuthService authService = AuthService();

    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: itemsRepository),
          RepositoryProvider.value(value: authService),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) =>
                  ItemsBloc(itemsRepository: itemsRepository)
                    ..add(const LoadItems()),
            ),
            BlocProvider(
              create: (context) =>
                  AuthBloc(authService: authService)..add(AuthStarted()),
            ),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp.router(
                title: 'FindX',
                debugShowCheckedModeBanner: false,
                theme: ThemeProvider.lightTheme,
                darkTheme: ThemeProvider.darkTheme,
                themeMode: themeProvider.themeMode,
                routerConfig: GoRouter(
                  initialLocation: '/splash',
                  routes: appRouter.routes,
                  navigatorKey: navigatorKey,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Global navigator key for accessing context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
