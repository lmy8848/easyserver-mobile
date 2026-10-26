import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'adb_service.dart';
import 'panels.dart';
import 'screen_panel.dart';
import 'pair_wizard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  if (Platform.isWindows) {
    windowManager.ensureInitialized();
  }
  runApp(const DevBoardApp());
}

class DevBoardApp extends StatelessWidget {
  const DevBoardApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevBoard · 移动端开发脚手架',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const DevBoardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DevBoardPage extends StatefulWidget {
  const DevBoardPage({super.key});
  @override
  State<DevBoardPage> createState() => _DevBoardPageState();
}

class _DevBoardPageState extends State<DevBoardPage> {
  String? _serial;
  List<DeviceEntry> _devices = [];
  String? _adbError;
  double _videoAspect = 1080 / 2400;
  Timer? _watchTimer;
  bool _watching = false;
  String? _lastSerial;

  @override
  void initState() {
    super.initState();
    _init();
    // 无线 adb 会因为 server 重启/手机休眠而掉线，掉线后设备列表就空了。
    // 空闲时定时复查，并对已知的 IP:端口 自动重连，避免用户手动点刷新。
    _watchTimer = Timer.periodic(const Duration(seconds: 3), (_) => _watch());
  }

  @override
  void dispose() {
    _watchTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    await windowManager.waitUntilReadyToShow(null, () {});
    await _refreshDevices();
  }

  /// 收到面板度量：按视频宽高比重新分配左右宽度
  void _onPanelMetrics(Size video) {
    if (video.height <= 0) return;
    final aspect = video.width / video.height;
    if ((aspect - _videoAspect).abs() < 0.0005) return;
    setState(() => _videoAspect = aspect);
  }

  Future<void> _watch() async {
    if (_watching || _serial != null) return;
    _watching = true;
    try {
      // 优先用内存里的上次设备，其次用持久化的「上次连接目标」：
      // adb server 重启/App 重启都会断开无线连接，这里自动重连，
      // 否则每次都要用户手动点「连接无线设备」。
      final target =
          _lastSerial ?? await AdbService.instance.lastConnectTarget();
      if (target != null && target.contains(':')) {
        await AdbService.instance.connect(target);
      }
      await _refreshDevices();
    } catch (_) {
      // 重连失败下个周期再试
    } finally {
      _watching = false;
    }
  }

  Future<void> _refreshDevices() async {
    try {
      final devices = await AdbService.instance.devices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _adbError = null;
        if (_serial == null ||
            !_devices.any((d) => d.serial == _serial && d.online)) {
          final online = _devices.where((d) => d.online).toList();
          if (online.isEmpty) {
            _serial = null;
          } else {
            // 优先 IP:端口 形式（mDNS 传输 exec-out 不可靠）
            _serial =
                online
                    .where((d) => d.serial.contains(':'))
                    .firstOrNull
                    ?.serial ??
                online.first.serial;
          }
        }
      });
      if (_serial != null) _lastSerial = _serial;
    } catch (e) {
      if (!mounted) return;
      setState(() => _adbError = '$e');
    }
  }

  Future<void> _connectDialog() async {
    final controller = TextEditingController(text: '192.168.1.10:37299');
    final host = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('连接无线设备'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'IP:端口',
            hintText: '192.168.1.10:37299',
          ),
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('连接'),
          ),
        ],
      ),
    );
    if (host == null || host.isEmpty) return;
    final out = await AdbService.instance.connect(host);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          out.isEmpty ? '已发起连接 $host' : out,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
    _refreshDevices();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('DevBoard · 移动端开发脚手架'),
        actions: [
          IconButton(
            tooltip: '无线配对向导（首次配对）',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const PairWizardDialog(),
              );
            },
          ),
          IconButton(
            tooltip: '连接无线设备',
            icon: const Icon(Icons.add_link),
            onPressed: _connectDialog,
          ),
          IconButton(
            tooltip: '刷新设备',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDevices,
          ),
        ],
      ),
      body: _adbError != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(_adbError!, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: _refreshDevices,
                    child: const Text('重试'),
                  ),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // 左侧面板按手机宽高比定宽，画面就不会在两侧留黑边，
                // 剩余宽度全部给右侧面板。
                // chrome = 面板内除画布外的高度（标题行 + 底部按键行 + 间距），
                // 用常量而非运行时测量，避免宽度↔高度互相影响形成反馈环。
                // 12(上padding) + 40(标题行) + 8 + 画布 + 8 + 48(按键行) + 12
                const chrome = 128.0;
                const hPadding = 24.0; // ScreenPanel 左右各 12
                var leftW =
                    (constraints.maxHeight - chrome) * _videoAspect + hPadding;
                leftW = leftW.clamp(240.0, constraints.maxWidth * 0.66);
                return Row(
                  children: [
                    SizedBox(
                      width: leftW,
                      child: ScreenPanel(
                        serial: _serial,
                        onMetrics: _onPanelMetrics,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: SidePanels(serial: _serial, devices: _devices),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
