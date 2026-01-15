import 'package:frontend/screens/home/home_screen.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/screens/auth/login_screen.dart';
import 'package:frontend/screens/auth/signup_screen.dart';
import 'package:frontend/screens/lost_item/report_lost_item_screen.dart';
import 'package:frontend/screens/found_item/report_found_item_screen.dart';
import 'package:frontend/screens/onboarding/onboarding_screen.dart';
import 'package:frontend/screens/onboarding/location_permission_screen.dart';
import 'package:frontend/screens/splash/splash_screen.dart';

import 'package:frontend/models/item.dart';
import 'package:frontend/screens/item_details/item_details_screen.dart';
import 'package:frontend/screens/map/map_screen.dart';
import 'package:frontend/screens/map/heatmap_screen.dart';
import 'package:frontend/screens/profile/profile_screen.dart';
import 'package:frontend/screens/search/search_screen.dart';
import 'package:frontend/screens/chat/chat_screen.dart';
import 'package:frontend/screens/notifications/notification_screen.dart';
import 'package:frontend/screens/settings/settings_screen.dart';
import 'package:frontend/screens/chat/chat_details_screen.dart';
import 'package:frontend/screens/main_scaffold.dart';
import 'package:frontend/screens/profile/my_reports_screen.dart';

class AppRouter {
  List<RouteBase> get routes => [
    // Splash screen (checks onboarding status)
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),

    // Onboarding (shown only on first launch)
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Location permission (shown after onboarding)
    GoRoute(
      path: '/location-permission',
      builder: (context, state) => const LocationPermissionScreen(),
    ),

    // Auth Routes (outside shell - no bottom nav)
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),

    // ShellRoute wraps the main tabs with persistent bottom navigation
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // Routes outside ShellRoute (full-screen pages without bottom nav)
    GoRoute(
      path: '/report-lost-item',
      builder: (context, state) => const ReportLostItemScreen(),
    ),
    GoRoute(
      path: '/report-found-item',
      builder: (context, state) => const ReportFoundItemScreen(),
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) {
        final items = state.extra as List<Item>;
        return MapScreen(items: items);
      },
    ),
    GoRoute(
      path: '/item/:id',
      builder: (context, state) {
        final item = state.extra as Item?;
        return ItemDetailsScreen(item: item);
      },
    ),
    GoRoute(
      path: '/chat-details/:chatId',
      builder: (context, state) =>
          ChatDetailsScreen(chatId: state.pathParameters['chatId']!),
    ),
    // Route for starting a new chat with a user (from AI match contact button)
    GoRoute(
      path: '/chat/:userId',
      builder: (context, state) {
        final otherUserId = state.pathParameters['userId']!;
        // Navigate to chat details using the userId as chatId
        return ChatDetailsScreen(chatId: otherUserId);
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/my-reports',
      builder: (context, state) => const MyReportsScreen(),
    ),
    // Heatmap route - shows all lost/found items on map
    GoRoute(
      path: '/heatmap',
      builder: (context, state) {
        final lat = double.tryParse(state.uri.queryParameters['lat'] ?? '');
        final lng = double.tryParse(state.uri.queryParameters['lng'] ?? '');
        return HeatmapScreen(initialLat: lat, initialLng: lng);
      },
    ),
  ];
}
