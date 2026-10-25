import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/setup/setup_screen.dart';
import '../presentation/screens/login/login_screen.dart';
import '../presentation/screens/login/qr_login_screen.dart';
import '../presentation/screens/dashboard/home_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/setup', builder: (context, state) => const SetupScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/qr-login', builder: (context, state) => const QRLoginScreen()),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
      ],
    ),
  ],
);
