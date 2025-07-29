import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/profile_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/course/course_selection_screen.dart';
import '../screens/game/scorecard_screen.dart';
import '../screens/game/shot_tracking_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login' || 
                           state.matchedLocation == '/register';
        
        if (!isLoggedIn && !isLoggingIn) {
          return '/login';
        }
        
        if (isLoggedIn && isLoggingIn) {
          return '/home';
        }
        
        return null;
      },
      routes: [
        // Auth routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        
        // Main app routes
        ShellRoute(
          builder: (context, state, child) {
            return MainNavigationShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/course-selection',
              name: 'course-selection',
              builder: (context, state) => const CourseSelectionScreen(),
            ),
            GoRoute(
              path: '/scorecard',
              name: 'scorecard',
              builder: (context, state) {
                final courseId = state.uri.queryParameters['courseId'] ?? '';
                return ScorecardScreen(courseId: courseId);
              },
            ),
            GoRoute(
              path: '/shot-tracking',
              name: 'shot-tracking',
              builder: (context, state) {
                final roundId = state.uri.queryParameters['roundId'] ?? '';
                final holeNumber = int.tryParse(
                  state.uri.queryParameters['holeNumber'] ?? '1'
                ) ?? 1;
                return ShotTrackingScreen(
                  roundId: roundId, 
                  holeNumber: holeNumber,
                );
              },
            ),
            GoRoute(
              path: '/analytics',
              name: 'analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final Widget child;
  
  const MainNavigationShell({super.key, required this.child});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    const NavigationDestination(
      icon: Icon(Icons.golf_course),
      label: 'Course',
    ),
    const NavigationDestination(
      icon: Icon(Icons.analytics),
      label: 'Analytics',
    ),
    const NavigationDestination(
      icon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/course-selection');
        break;
      case 2:
        context.go('/analytics');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations,
      ),
    );
  }
}