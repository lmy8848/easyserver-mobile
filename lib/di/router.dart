import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/setup/setup_screen.dart';
import '../presentation/screens/login/login_screen.dart';
import '../presentation/screens/login/qr_login_screen.dart';
import '../presentation/screens/notifications/notifications_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/logs/logs_screen.dart';
import '../presentation/screens/lanshare/lanshare_screen.dart';
import '../presentation/screens/cron/cron_screen.dart';
import '../presentation/screens/firewall/firewall_screen.dart';
import '../presentation/screens/shares/shares_screen.dart';
import '../presentation/screens/web/web_servers_screen.dart';
import '../presentation/screens/web/website_list_screen.dart';
import '../presentation/screens/dashboard/home_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/setup', builder: (context, state) => const SetupScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
        path: '/qr-login', builder: (context, state) => const QRLoginScreen()),
    GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen()),
    GoRoute(
        path: '/profile', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: '/logs', builder: (context, state) => const LogsScreen()),
    GoRoute(
        path: '/lanshare', builder: (context, state) => const LanShareScreen()),
    GoRoute(path: '/cron', builder: (context, state) => const CronScreen()),
    GoRoute(
        path: '/firewall', builder: (context, state) => const FirewallScreen()),
    GoRoute(path: '/shares', builder: (context, state) => const SharesScreen()),
    GoRoute(
        path: '/web', builder: (context, state) => const WebServersScreen()),
    GoRoute(
      path: '/web/:sid/:name',
      builder: (context, state) => WebsiteListScreen(
        serverId: int.tryParse(state.pathParameters['sid'] ?? '') ?? 0,
        serverName: state.pathParameters['name'] ?? 'Web 服务器',
      ),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [],
    ),
  ],
);
