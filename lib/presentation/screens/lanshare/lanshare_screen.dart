import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../data/services/lan_share_server.dart';
import '../../../di/providers.dart';

/// 局域网传文件：手机开启 HTTP 服务，电脑/其它设备浏览器访问即可
/// 浏览、下载、上传手机文件。访问需令牌（URL 已自带）。
class LanShareScreen extends ConsumerStatefulWidget {
  const LanShareScreen({super.key});
  @override
  ConsumerState<LanShareScreen> createState() => _LanShareScreenState();
}

class _LanShareScreenState extends ConsumerState<LanShareScreen> {
  bool _running = false;
  bool _starting = false;
  String _token = '';
  String _localIp = '';
  String? _error;
  static const _port = 8090;
  static const _tokenKey = 'lan_share_token';

  @override
  void initState() {
    super.initState();
    _init();
    // 回到本页时同步运行状态（服务离开页面后仍保持运行）
    _running = LanShareServer.instance.running;
  }

  Future<void> _init() async {
    final storage = ref.read(settingsStorageProvider);
    await storage.init();
    var token = storage.getString(_tokenKey);
    if (token.isEmpty) {
      token = _genToken();
      await storage.setString(_tokenKey, token);
    }
    if (!mounted) return;
    setState(() => _token = token);
    await _detectIp();
  }

  String _genToken() {
    final r = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final r2 = (DateTime.now().hashCode & 0xFFFFFF).toRadixString(36);
    return 'es$r$r2';
  }

  Future<void> _detectIp() async {
    String ip = '';
    try {
      final interfaces = await NetworkInterface.list();
      for (final itf in interfaces) {
        if (itf.name.toLowerCase().contains('lo')) continue;
        for (final addr in itf.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            ip = addr.address;
            break;
          }
        }
        if (ip.isNotEmpty) break;
      }
    } catch (_) {}
    if (mounted) setState(() => _localIp = ip);
  }

  Future<void> _toggle() async {
    if (_running) {
      await LanShareServer.instance.stop();
      if (!mounted) return;
      setState(() => _running = false);
      return;
    }

    // 存储权限：Android 11+ 需要「所有文件访问权限」（跳系统设置授予）
    final storage = await Permission.manageExternalStorage.status;
    if (!storage.isGranted) {
      final result = await Permission.manageExternalStorage.request();
      if (!result.isGranted) {
        if (!mounted) return;
        setState(() => _error = '需要「所有文件访问权限」才能共享手机文件，请在系统设置中允许');
        return;
      }
    }

    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      await LanShareServer.instance.start(token: _token, port: _port);
      await _detectIp();
      if (!mounted) return;
      setState(() => _running = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '服务启动失败: $e');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  String get _shareUrl =>
      'http://$_localIp:$_port/?token=${Uri.encodeComponent(_token)}';

  // 服务在离开页面后保持运行（手机锁屏/App 存活期间可继续传输），
  // 停止只能通过本页开关或系统杀掉 App；令牌可随时重新生成使旧地址失效

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('局域网传文件')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.lan_outlined,
                size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text('手机开启服务，电脑或其它设备\n用浏览器打开地址即可互传文件',
                textAlign: TextAlign.center,
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 24),
            // 开关卡
            Card(
              child: ListTile(
                leading: Icon(
                  _running ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                  color: _running ? Colors.green : Colors.grey,
                ),
                title: Text(_running ? '服务运行中' : '服务已停止'),
                subtitle: Text(
                    _running ? 'http://$_localIp:$_port' : '点击开关启动（离开本页仍保持运行）'),
                trailing: Switch(
                  value: _running,
                  onChanged: _starting ? null : (_) => _toggle(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_running) ...[
              // 地址 + 二维码
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: QrImageView(
                          data: _shareUrl,
                          size: 180,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(_shareUrl,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('复制地址'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('已复制：$_shareUrl'),
                              duration: const Duration(seconds: 2)));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 令牌
              Card(
                child: ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('访问令牌'),
                  subtitle: Text(_token),
                  trailing: IconButton(
                    tooltip: '重新生成（已连接的旧地址将失效）',
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      final storage = ref.read(settingsStorageProvider);
                      final newToken = _genToken();
                      await storage.setString(_tokenKey, newToken);
                      if (LanShareServer.instance.running) {
                        // 热更新令牌（服务单例直接改）
                        await LanShareServer.instance.stop();
                        await LanShareServer.instance
                            .start(token: newToken, port: _port);
                      }
                      if (!mounted) return;
                      setState(() => _token = newToken);
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // 权限/说明
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('使用说明', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    const Text(
                      '· 手机与访问设备需在同一局域网（同一 WiFi）\n'
                      '· 默认共享手机存储根目录，网页内可浏览、下载、上传、删除\n'
                      '· 地址含访问令牌，不要泄露给局域网外的人；可随时重新生成令牌使旧地址失效\n'
                      '· 传输期间请保持本页面打开',
                      style: TextStyle(fontSize: 12, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }
}
