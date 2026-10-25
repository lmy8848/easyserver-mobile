import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../di/providers.dart';
import '../../../presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final notifier = ref.read(serverConfigProvider.notifier);
    await notifier.loadConfig();
    final config = ref.read(serverConfigProvider);

    if (config == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) context.go('/setup');
      return;
    }

    ref.read(apiClientProvider).updateBaseUrl(config.baseUrl);
    await ref.read(authStateProvider.notifier).checkAuth();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    final authState = ref.read(authStateProvider);
    if (authState.isAuthenticated) {
      context.go('/');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dns, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text('EasyServer',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('服务器管理面板',
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
