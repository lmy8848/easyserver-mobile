import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'di/router.dart';
import 'presentation/providers/app_settings_provider.dart';
import 'presentation/providers/theme_provider.dart';

class EasyServerMobileApp extends ConsumerStatefulWidget {
  const EasyServerMobileApp({super.key});
  @override
  ConsumerState<EasyServerMobileApp> createState() =>
      _EasyServerMobileAppState();
}

class _EasyServerMobileAppState extends ConsumerState<EasyServerMobileApp>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _authenticating = false;
  bool _wasBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 应用锁：真实离开前台（paused）后回到前台才验证。
    // 注意：local_auth 弹系统验证框也会引发 inactive->resumed，
    // 若一律在 resumed 上锁会造成解锁死循环——
    // 仅在"未处于锁定态时离开前台"才标记 _wasBackgrounded。
    final lockOn = ref.read(appSettingsProvider).appLockEnabled;
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) &&
        !_locked &&
        lockOn) {
      _wasBackgrounded = true;
    }
    if (state == AppLifecycleState.resumed && lockOn && _wasBackgrounded) {
      _wasBackgrounded = false;
      if (!_locked && !_authenticating) {
        setState(() => _locked = true);
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    _authenticating = true;
    final ok = await ref.read(appSettingsProvider.notifier).authenticate();
    _authenticating = false;
    if (!mounted) return;
    setState(() => _locked = !ok);
    if (!ok) {
      // 验证失败/取消：允许再次点击解锁
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'EasyServer',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo, brightness: Brightness.dark),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      themeMode: themeMode,
      builder: (context, child) {
        // 全局应用锁遮罩：覆盖所有页面
        return Stack(
          children: [
            child ?? const SizedBox.expand(),
            if (_locked) _buildLockOverlay(context),
          ],
        );
      },
    );
  }

  Widget _buildLockOverlay(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Container(
        color: theme.colorScheme.surface,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('已锁定', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('验证身份以继续使用', style: theme.textTheme.bodySmall),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _authenticating ? null : _authenticate,
              icon: const Icon(Icons.fingerprint),
              label: Text(_authenticating ? '正在验证…' : '解锁'),
            ),
          ],
        ),
      ),
    );
  }
}
