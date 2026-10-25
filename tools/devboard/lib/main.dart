import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'adb_service.dart';

void main() {
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

  @override
  void initState() {
    super.initState();
    _refreshDevices();
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
          _serial = online.isEmpty ? null : online.first.serial;
        }
      });
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
          : Row(
              children: [
                Expanded(flex: 3, child: ScreenPanel(serial: _serial)),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: TerminalPanel(serial: _serial, devices: _devices),
                ),
              ],
            ),
    );
  }
}

/// 屏幕监视 + 操控面板
class ScreenPanel extends StatefulWidget {
  final String? serial;
  const ScreenPanel({super.key, required this.serial});

  @override
  State<ScreenPanel> createState() => _ScreenPanelState();
}

class _ScreenPanelState extends State<ScreenPanel> {
  Uint8List? _frameBytes;
  Size _screenSize = const Size(1080, 2400);
  bool _auto = true;
  bool _capturing = false;
  bool _pendingFrame = false;
  String? _error;
  Timer? _timer;
  int _intervalSec = 2;
  Offset? _dragStart;
  DateTime _lastCaptureAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _capture();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant ScreenPanel old) {
    super.didUpdateWidget(old);
    if (old.serial != widget.serial) {
      _frameBytes = null;
      _capture();
    }
  }

  // 流水线预取：无线抓帧 1-2s 可能超过定时间隔，抓完立即按剩余间隔续抓，
  // 避免固定 Timer 造成的「间隔+传输时长」双重等待
  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (!_auto) return;
    final elapsed = DateTime.now().difference(_lastCaptureAt).inMilliseconds;
    final wait = elapsed >= _intervalSec * 1000
        ? 0
        : _intervalSec * 1000 - elapsed;
    _timer = Timer(Duration(milliseconds: wait), () => _capture());
  }

  Future<void> _capture() async {
    if (_capturing) {
      _pendingFrame = true;
      return;
    }
    if (widget.serial == null) return;
    _capturing = true;
    _lastCaptureAt = DateTime.now();
    try {
      final bytes = await AdbService.instance.screencap(widget.serial);
      if (!mounted) return;
      setState(() {
        _frameBytes = Uint8List.fromList(bytes);
        _error = null;
      });
      _probeSize();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '抓帧失败: $e');
    } finally {
      _capturing = false;
      if (mounted && _auto) {
        if (_pendingFrame) {
          _pendingFrame = false;
          _capture();
        } else {
          _schedule();
        }
      }
    }
  }

  Future<void> _probeSize() async {
    try {
      final out = await AdbService.instance.screenMeta(widget.serial);
      final m = RegExp(r'(\d+)x(\d+)').firstMatch(out);
      if (m != null && mounted) {
        setState(
          () => _screenSize = Size(
            double.parse(m.group(1)!),
            double.parse(m.group(2)!),
          ),
        );
      }
    } catch (_) {}
  }

  Offset _toDevice(Offset local, Size displaySize) => Offset(
    (local.dx / displaySize.width * _screenSize.width).round().toDouble(),
    (local.dy / displaySize.height * _screenSize.height).round().toDouble(),
  );

  Future<void> _tap(Offset local, Size display) async {
    final p = _toDevice(local, display);
    await AdbService.instance.deviceArgs(widget.serial, [
      'shell',
      'input',
      'tap',
      '${p.dx}',
      '${p.dy}',
    ]);
  }

  Future<void> _swipe(Offset from, Offset to, Size display) async {
    final a = _toDevice(from, display);
    final b = _toDevice(to, display);
    if ((a.dx - b.dx).abs() < 8 && (a.dy - b.dy).abs() < 8) return;
    await AdbService.instance.deviceArgs(widget.serial, [
      'shell',
      'input',
      'swipe',
      '${a.dx}',
      '${a.dy}',
      '${b.dx}',
      '${b.dy}',
      '300',
    ]);
  }

  Future<void> _key(int keycode) => AdbService.instance.deviceArgs(
    widget.serial,
    ['shell', 'input', 'keyevent', '$keycode'],
  );

  Future<void> _sendText(String text) => AdbService.instance.deviceArgs(
    widget.serial,
    ['shell', 'input', 'text', text.replaceAll(' ', '%s')],
  );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Text('屏幕监视', style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              if (widget.serial != null)
                Expanded(
                  child: Text(
                    widget.serial!,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              DropdownButton<int>(
                value: _intervalSec,
                items: const [1, 2, 3, 5]
                    .map(
                      (s) => DropdownMenuItem(value: s, child: Text('${s}s')),
                    )
                    .toList(),
                onChanged: (s) {
                  if (s == null) return;
                  setState(() {
                    _intervalSec = s;
                    _auto = true;
                  });
                  _schedule();
                },
              ),
              IconButton(
                tooltip: _auto ? '暂停自动抓帧' : '恢复自动抓帧',
                icon: Icon(_auto ? Icons.pause_circle : Icons.play_circle),
                onPressed: () {
                  setState(() => _auto = !_auto);
                  if (_auto) _capture();
                },
              ),
              IconButton(
                tooltip: '手动抓帧',
                icon: const Icon(Icons.camera_alt),
                onPressed: _capture,
              ),
              IconButton(
                tooltip: 'scrcpy 实时镜像（30-60fps）',
                icon: const Icon(Icons.live_tv),
                onPressed: () async {
                  try {
                    await AdbService.instance.launchScrcpy(widget.serial);
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _error = '$e');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
                color: Colors.black12,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_frameBytes != null)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final aspect = _screenSize.width / _screenSize.height;
                        var w = constraints.maxWidth;
                        var h = w / aspect;
                        if (h > constraints.maxHeight) {
                          h = constraints.maxHeight;
                          w = h * aspect;
                        }
                        final display = Size(w, h);
                        return GestureDetector(
                          onTapDown: (d) => _tap(d.localPosition, display),
                          onPanStart: (d) => _dragStart = d.localPosition,
                          onPanEnd: (d) {
                            if (_dragStart != null) {
                              _swipe(_dragStart!, d.localPosition, display);
                              _dragStart = null;
                            }
                          },
                          child: SizedBox(
                            width: w,
                            height: h,
                            child: Image.memory(
                              _frameBytes!,
                              fit: BoxFit.fill,
                              gaplessPlayback: true,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          widget.serial == null ? '未连接设备' : '正在抓取屏幕…',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  if (_error != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.black54,
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _keyBtn(Icons.arrow_back, '返回', 4),
              _keyBtn(Icons.home_outlined, '主页', 3),
              _keyBtn(Icons.crop_square, '多任务', 187),
              _keyBtn(Icons.power_settings_new, '电源', 26),
              SizedBox(
                width: 220,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '发送文本到手机',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _sendText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keyBtn(IconData icon, String tip, int keycode) => IconButton(
    tooltip: tip,
    icon: Icon(icon),
    onPressed: () => _key(keycode),
  );
}

/// 设备选择 + ADB 命令终端
class TerminalPanel extends StatefulWidget {
  final String? serial;
  final List<DeviceEntry> devices;
  const TerminalPanel({super.key, required this.serial, required this.devices});
  @override
  State<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<TerminalPanel> {
  final _output = <String>[];
  final _controller = TextEditingController();
  final _listController = ScrollController();

  void _append(String line) {
    setState(() {
      _output.addAll(line.split('\n'));
      if (_output.length > 800) _output.removeRange(0, _output.length - 800);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listController.hasClients) {
        _listController.jumpTo(_listController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _exec(String input) async {
    final cmd = input.trim();
    if (cmd.isEmpty) return;
    _append('\$ adb $cmd');
    _controller.clear();
    try {
      final parts = cmd.split(RegExp(r'\s+'));
      final out = await AdbService.instance.raw(
        parts,
        timeout: const Duration(seconds: 30),
      );
      _append(out.isEmpty ? '(no output)' : out);
    } catch (e) {
      _append('ERR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('设备与 ADB 终端', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final d in widget.devices)
                Chip(
                  label: Text(
                    '${d.model} · ${d.state}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: d.serial == widget.serial
                      ? Colors.indigo.shade50
                      : null,
                ),
              if (widget.devices.isEmpty)
                Text('暂无设备，请点右上角连接', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF101418),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                controller: _listController,
                itemCount: _output.length,
                itemBuilder: (context, i) => Text(
                  _output[i],
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFFB8C4CC),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'adb 命令（自动附加 -s 设备），如 shell pm list packages',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: _exec,
          ),
        ],
      ),
    );
  }
}
