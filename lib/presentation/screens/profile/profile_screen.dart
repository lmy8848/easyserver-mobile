import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../di/providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_settings_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/theme_provider.dart';

/// 设置与安全：账户安全（TOTP/登录会话/修改密码）、应用设置（外观/
/// 应用锁/通知/服务器）、关于（版本/许可证）。
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _totpEnabled = false;
  bool _loadingTotp = true;
  List<Map<String, dynamic>> _sessions = [];
  Timer? _sessionsTimer;

  @override
  void initState() {
    super.initState();
    _loadTotpStatus();
    _loadSessions();
    _loadAppVersion();
    _checkBiometrics();
    // 在线设备实时刷新（30s）
    _sessionsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadSessions();
    });
  }

  Future<void> _loadTotpStatus() async {
    try {
      final enabled = await ref.read(authRepositoryProvider).getTotpStatus();
      if (mounted)
        setState(() {
          _totpEnabled = enabled;
          _loadingTotp = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loadingTotp = false);
    }
  }

  Future<void> _checkBiometrics() async {
    final supported =
        await ref.read(appSettingsProvider.notifier).deviceSupportsBiometrics();
    if (!mounted) return;
    setState(() => _biometricsAvailable = supported);
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await ref.read(authRepositoryProvider).getSessions();
      if (mounted) setState(() => _sessions = sessions);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('设置与安全')),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadSessions();
          await _loadTotpStatus();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── 用户信息 ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Text(
                        user?.username.isNotEmpty == true
                            ? user!.username[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.username ?? '-',
                            style: theme.textTheme.titleLarge),
                        Text('角色: ${user?.role ?? '-'}',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── 两步验证 ──
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('两步验证（TOTP）'),
                    subtitle: Text(
                        _loadingTotp ? '加载中…' : (_totpEnabled ? '已启用' : '未启用')),
                    trailing: _loadingTotp
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : FilledButton.tonal(
                            onPressed: _totpEnabled
                                ? _showDisableTotpDialog
                                : _startTotpSetup,
                            child: Text(_totpEnabled ? '禁用' : '启用'),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 会话管理 ──
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.devices),
                    title: Text('登录会话（${_sessions.length} 台在线设备）'),
                    trailing: _sessions.length > 1
                        ? TextButton(
                            onPressed: _kickAllOthers,
                            child: const Text('踢出其他'))
                        : null,
                  ),
                  if (_sessions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child:
                          Text('暂无会话数据', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ..._sessions.map((s) {
                      final isCurrent = s['is_current'] == true;
                      final token = (s['token'] as String? ?? '');
                      final clientType = s['client_type'] as String? ?? '';
                      final deviceIcon = clientType == 'mobile'
                          ? Icons.smartphone
                          : clientType == 'web'
                              ? Icons.computer
                              : Icons.devices_other;
                      return ListTile(
                        dense: true,
                        leading: Icon(
                            isCurrent ? Icons.verified_user : deviceIcon,
                            color: isCurrent ? Colors.green : Colors.grey),
                        title: Text(
                          '${isCurrent ? "本机（当前）" : "在线设备"} · ${_clientHint(s['user_agent'] as String?)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          '${s['ip'] ?? '-'} · ${clientType.toUpperCase()} · 登录 ${_fmtTime(s['login_at'] as String?)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: isCurrent
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.logout, size: 18),
                                tooltip: '踢出',
                                onPressed: () => _kickSession(token),
                              ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 应用设置 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
              child: Text('应用设置',
                  style:
                      theme.textTheme.titleSmall?.copyWith(color: Colors.grey)),
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined),
                    title: const Text('外观'),
                    subtitle: Text(_themeLabel(ref.watch(themeModeProvider))),
                    onTap: _showThemeDialog,
                  ),
                  ListTile(
                    leading: const Icon(Icons.fingerprint),
                    title: const Text('应用锁'),
                    subtitle: Text(_appLockSubtitle()),
                    trailing: Switch(
                      value: ref.watch(appSettingsProvider).appLockEnabled,
                      onChanged: (v) => _toggleAppLock(v),
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('新通知提示'),
                    subtitle: const Text('收到新通知时在 App 内弹提示'),
                    value: ref.watch(appSettingsProvider).notifyEnabled,
                    onChanged: (v) => ref
                        .read(appSettingsProvider.notifier)
                        .setNotifyEnabled(v),
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('通知刷新间隔'),
                    subtitle: Text(
                        '每 ${ref.watch(appSettingsProvider).notifyIntervalSec} 秒'),
                    onTap: _showNotifyIntervalDialog,
                  ),
                  ListTile(
                    leading: const Icon(Icons.password),
                    title: const Text('修改密码'),
                    onTap: _showChangePasswordDialog,
                  ),
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('仪表盘刷新间隔'),
                    subtitle: Text(
                        _refreshLabel(ref.watch(dashboardRefreshProvider))),
                    onTap: _showRefreshIntervalDialog,
                  ),
                  ListTile(
                    leading: const Icon(Icons.dns),
                    title: const Text('服务器配置'),
                    subtitle:
                        Text(ref.watch(serverConfigProvider)?.host ?? '未配置'),
                    onTap: () => context.push('/setup'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: const Text('运行日志'),
                    subtitle: const Text('全局异常与运行事件记录'),
                    onTap: () => context.push('/logs'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title:
                        const Text('退出登录', style: TextStyle(color: Colors.red)),
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── 关于 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
              child: Text('关于',
                  style:
                      theme.textTheme.titleSmall?.copyWith(color: Colors.grey)),
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('版本'),
                    trailing: Text(_appVersion,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: const Text('开源许可证'),
                    onTap: () => showLicensePage(
                        context: context, applicationName: 'EasyServer Mobile'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _appVersion = '…';
  bool _biometricsAvailable = false;

  String _appLockSubtitle() {
    if (!ref.watch(appSettingsProvider).appLockEnabled) {
      return _biometricsAvailable ? '关闭 · 回到前台需验证身份' : '本机不支持生物识别';
    }
    return _biometricsAvailable ? '开启 · 指纹/面容解锁' : '已开启';
  }

  Future<void> _toggleAppLock(bool enable) async {
    if (enable) {
      final supported = await ref
          .read(appSettingsProvider.notifier)
          .deviceSupportsBiometrics();
      if (!mounted) return;
      if (!supported) {
        setState(() => _biometricsAvailable = false);
        _snack('本机不支持生物识别（或未录入指纹/面容），无法开启应用锁');
        return;
      }
      // 开启前先验证一次身份，确认是本人操作
      final ok = await ref.read(appSettingsProvider.notifier).authenticate();
      if (!mounted) return;
      if (!ok) {
        _snack('验证未通过，未开启应用锁');
        return;
      }
    }
    await ref.read(appSettingsProvider.notifier).setAppLockEnabled(enable);
    if (!mounted) return;
    setState(() => _biometricsAvailable = true);
    _snack(enable ? '应用锁已开启' : '应用锁已关闭');
  }

  Future<void> _showNotifyIntervalDialog() async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('通知刷新间隔'),
            ),
            ...[15, 30, 60, 120].map(
              (s) => ListTile(
                title: Text('每 $s 秒'),
                trailing: ref.watch(appSettingsProvider).notifyIntervalSec == s
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(ctx, s),
              ),
            ),
          ],
        ),
      ),
    );
    if (choice != null) {
      await ref.read(appSettingsProvider.notifier).setNotifyInterval(choice);
    }
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = '${info.version} (${info.buildNumber})');
  }

  String _themeLabel(ThemeMode m) => switch (m) {
        ThemeMode.light => '浅色',
        ThemeMode.dark => '深色',
        _ => '跟随系统',
      };

  Future<void> _showThemeDialog() async {
    final choice = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('外观'),
            ),
            ...[
              (ThemeMode.system, '跟随系统'),
              (ThemeMode.light, '浅色'),
              (ThemeMode.dark, '深色'),
            ].map(
              (e) => ListTile(
                title: Text(e.$2),
                trailing: ref.watch(themeModeProvider) == e.$1
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(ctx, e.$1),
              ),
            ),
          ],
        ),
      ),
    );
    if (choice != null) {
      await ref.read(themeModeProvider.notifier).setMode(choice);
    }
  }

  String _fmtTime(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final t = DateTime.tryParse(iso);
    if (t == null) return iso;
    final local = t.toLocal();
    return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _refreshLabel(int seconds) =>
      seconds <= 0 ? '关闭（手动刷新）' : '每 $seconds 秒';

  Future<void> _showRefreshIntervalDialog() async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('仪表盘自动刷新间隔'),
            ),
            ...DashboardRefreshNotifier.choices.map(
              (s) => ListTile(
                title: Text(_refreshLabel(s)),
                onTap: () => Navigator.of(ctx).pop(s),
              ),
            ),
          ],
        ),
      ),
    );
    if (choice != null) {
      await ref.read(dashboardRefreshProvider.notifier).setInterval(choice);
    }
  }

  @override
  void dispose() {
    _sessionsTimer?.cancel();
    super.dispose();
  }

  String _clientHint(String? ua) {
    if (ua == null) return '未知客户端';
    if (ua.contains('Dart') || ua.contains('dart')) return '移动端';
    if (ua.contains('Mobile')) return '移动浏览器';
    return 'Web 浏览器';
  }

  // ── TOTP 启用：setup 展示密钥 → 输入验证码确认 ──
  Future<void> _startTotpSetup() async {
    try {
      final setup = await ref.read(authRepositoryProvider).setupTotp();
      if (!mounted) return;
      final secret = (setup['secret'] ?? setup['key'] ?? '') as String;
      final otpauth = (setup['otpauth_url'] ?? setup['url'] ?? '') as String;

      final controller = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('启用两步验证'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1. 在验证器 App 中添加：'),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => Clipboard.setData(
                    ClipboardData(text: otpauth.isNotEmpty ? otpauth : secret)),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    otpauth.isNotEmpty ? otpauth : secret,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text('（点击复制）\n2. 输入 6 位验证码确认：'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration:
                    const InputDecoration(hintText: '验证码', counterText: ''),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('确认启用')),
          ],
        ),
      );
      if (ok != true) return;
      final codes = await ref
          .read(authRepositoryProvider)
          .enableTotp(controller.text.trim());
      if (!mounted) return;
      setState(() {
        _totpEnabled = true;
      });
      // 展示一次性备用码（仅此一次可见）
      if (codes.isNotEmpty && mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('备用恢复码'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('请妥善保存（仅显示一次）：'),
                const SizedBox(height: 8),
                ...codes.map((c) =>
                    Text(c, style: const TextStyle(fontFamily: 'monospace'))),
              ],
            ),
            actions: [
              FilledButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text('已保存'))
            ],
          ),
        );
      }
    } catch (e) {
      _snack('启用失败: $e');
    }
  }

  Future<void> _showDisableTotpDialog() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('禁用两步验证'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: '登录密码'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认禁用')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authRepositoryProvider).disableTotp(controller.text);
      if (mounted) setState(() => _totpEnabled = false);
      _snack('两步验证已禁用');
    } catch (e) {
      _snack('禁用失败: $e');
    }
  }

  // ── 会话 ──
  Future<void> _kickSession(String token) async {
    try {
      await ref.read(authRepositoryProvider).kickSession(token);
      await _loadSessions();
    } catch (e) {
      _snack('踢出失败: $e');
    }
  }

  Future<void> _kickAllOthers() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('踢出其他会话'),
        content: const Text('将登出除本机外的全部登录会话，确定？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确定')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authRepositoryProvider).kickAllOtherSessions();
      await _loadSessions();
      _snack('已踢出其他会话');
    } catch (e) {
      _snack('操作失败: $e');
    }
  }

  // ── 修改密码 ──
  Future<void> _showChangePasswordDialog() async {
    final oldC = TextEditingController();
    final newC = TextEditingController();
    final confirmC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: oldC,
                obscureText: true,
                decoration: const InputDecoration(hintText: '当前密码')),
            const SizedBox(height: 8),
            TextField(
                controller: newC,
                obscureText: true,
                decoration: const InputDecoration(hintText: '新密码（≥8 位）')),
            const SizedBox(height: 8),
            TextField(
                controller: confirmC,
                obscureText: true,
                decoration: const InputDecoration(hintText: '确认新密码')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认')),
        ],
      ),
    );
    if (ok != true) return;
    if (newC.text != confirmC.text) {
      _snack('两次输入的新密码不一致');
      return;
    }
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(oldC.text, newC.text);
      _snack('密码已修改');
    } catch (e) {
      _snack('修改失败: $e');
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
