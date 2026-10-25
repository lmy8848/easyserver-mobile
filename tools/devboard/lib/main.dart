import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'adb_service.dart';
import 'pair_wizard.dart';
import 'win32_embed.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  int? _windowHandle;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 窗口就绪后取 HWND（Win32 FindWindow 按 exe 名），供 scrcpy 子窗口嵌入定位
    await windowManager.waitUntilReadyToShow(null, () {});
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final hwnd = Win32Embed.findWindow('devboard');
    if (!mounted) return;
    setState(() => _windowHandle = hwnd);
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
          : Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ScreenPanel(
                    serial: _serial,
                    devboardHwnd: _windowHandle,
                  ),
                ),
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

/// 屏幕面板：默认 scrcpy 实时镜像（GUI 模式窗口 Win32 SetParent 内嵌，
/// 鼠标键盘由 scrcpy 原生处理），可切换轻量抓帧轮询。
enum ScreenMode { mirror, snapshot }

class ScreenPanel extends StatefulWidget {
  final String? serial;
  final int? devboardHwnd;
  const ScreenPanel({
    super.key,
    required this.serial,
    required this.devboardHwnd,
  });

  @override
  State<ScreenPanel> createState() => _ScreenPanelState();
}

class _ScreenPanelState extends State<ScreenPanel> {
  ScreenMode _mode = ScreenMode.mirror;
  Offset? _dragStart;

  // ── mirror（scrcpy GUI 窗口内嵌）──
  Process? _scrcpyProc;
  ScrcpyEmbedSession? _session;
  bool _mirrorStarting = false;
  String? _mirrorError;
  final GlobalKey _canvasKey = GlobalKey();

  // ── snapshot（抓帧轮询）──
  List<int>? _frameBytes;
  Size _screenSize = const Size(1080, 2400);
  bool _auto = true;
  bool _capturing = false;
  bool _pendingFrame = false;
  String? _captureError;
  Timer? _timer;
  int _intervalSec = 2;
  DateTime _lastCaptureAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mode == ScreenMode.mirror) _startMirror();
    });
  }

  @override
  void didUpdateWidget(covariant ScreenPanel old) {
    super.didUpdateWidget(old);
    if (old.serial != widget.serial) {
      _frameBytes = null;
      if (_mode == ScreenMode.mirror) {
        _restartMirror();
      } else {
        _capture();
      }
    }
    if (old.devboardHwnd != widget.devboardHwnd &&
        widget.devboardHwnd != null) {
      _session?.setDevboardHwnd(widget.devboardHwnd!);
    }
  }

  // ══════════ scrcpy GUI 内嵌 ══════════

  Future<void> _startMirror() async {
    if (widget.serial == null ||
        _mirrorStarting ||
        widget.devboardHwnd == null) {
      return;
    }
    _mirrorStarting = true;
    await _stopMirror();
    if (!mounted) {
      _mirrorStarting = false;
      return;
    }
    setState(() => _mirrorError = null);

    final title = 'DevBoard_Mirror_${DateTime.now().millisecondsSinceEpoch}';
    final session = ScrcpyEmbedSession(title);
    session.setDevboardHwnd(widget.devboardHwnd!);
    _session = session;

    try {
      final proc = await Process.start('bin/scrcpy/scrcpy.exe', [
        '-s',
        widget.serial!,
        '--no-audio',
        '--window-borderless',
        '--window-title=$title',
        '--max-fps=30',
        '--video-bit-rate=8M',
      ], mode: ProcessStartMode.normal);
      _scrcpyProc = proc;
      proc.stderr.cast<List<int>>().transform(systemEncoding.decoder).listen((
        line,
      ) {
        debugPrint('[scrcpy] $line');
      });
      unawaited(
        proc.exitCode.then((code) {
          _scrcpyProc = null;
          if (mounted && _mode == ScreenMode.mirror && code != 0) {
            setState(() => _mirrorError = 'scrcpy 已退出（代码 $code）');
          }
        }),
      );

      // 等窗口出现并挂为子窗口（12s 超时）
      final attached = await session.attach();
      if (!mounted) return;
      if (!attached) {
        setState(() => _mirrorError = '未找到 scrcpy 镜像窗口（进程可能启动失败）');
        proc.kill();
        return;
      }
      session.startWatchdog(() {
        if (mounted) {
          setState(() => _mirrorError = '镜像窗口已关闭');
        }
      });
      // 立即按当前画布布局一次
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncLayout());
    } catch (e) {
      if (mounted) setState(() => _mirrorError = '实时镜像启动失败: $e');
    } finally {
      _mirrorStarting = false;
    }
  }

  Future<void> _restartMirror() async {
    await _stopMirror();
    if (mounted && _mode == ScreenMode.mirror) await _startMirror();
  }

  Future<void> _stopMirror() async {
    _session?.dispose();
    _session = null;
    _scrcpyProc?.kill();
    _scrcpyProc = null;
  }

  /// 把 scrcpy 子窗口移动到 Flutter 画布区域（布局变化时由框架回调）
  void _syncLayout() {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final topLeft = box.localToGlobal(Offset.zero);
    final size = box.size;
    _session?.layout(
      logicalX: topLeft.dx,
      logicalY: topLeft.dy,
      logicalW: size.width,
      logicalH: size.height,
    );
  }

  // ══════════ 抓帧轮询（降级模式）══════════

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
        _frameBytes = bytes;
        _captureError = null;
      });
      _probeSize();
    } catch (e) {
      if (!mounted) return;
      setState(() => _captureError = '抓帧失败: $e');
    } finally {
      _capturing = false;
      if (mounted && _auto && _mode == ScreenMode.snapshot) {
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

  // ══════════ 抓帧模式的坐标注入 ══════════

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

  Future<void> _switchMode(ScreenMode m) async {
    if (_mode == m) return;
    setState(() => _mode = m);
    if (m == ScreenMode.mirror) {
      _timer?.cancel();
      await _startMirror();
    } else {
      await _stopMirror();
      _capture();
      _schedule();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopMirror();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = _mode == ScreenMode.mirror
        ? (_session?.attached ?? false)
        : (_frameBytes != null);

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
              SegmentedButton<ScreenMode>(
                segments: const [
                  ButtonSegment(
                    value: ScreenMode.mirror,
                    icon: Icon(Icons.live_tv, size: 16),
                    label: Text('实时', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: ScreenMode.snapshot,
                    icon: Icon(Icons.image_outlined, size: 16),
                    label: Text('抓帧', style: TextStyle(fontSize: 12)),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => _switchMode(s.first),
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity(horizontal: -3, vertical: -2),
                ),
              ),
              const SizedBox(width: 8),
              if (_mode == ScreenMode.snapshot) ...[
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
              ] else
                IconButton(
                  tooltip: '重启实时镜像',
                  icon: const Icon(Icons.replay),
                  onPressed: _startMirror,
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
              clipBehavior: Clip.none,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 画布：mirror 模式此区域由 scrcpy 子窗口覆盖（Win32 层），
                  // 布局变化经 LayoutBuilder 驱动子窗口 MoveWindow 对齐
                  LayoutBuilder(
                    builder: (context, constraints) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _syncLayout(),
                      );
                      return Container(
                        key: _canvasKey,
                        width: double.infinity,
                        height: double.infinity,
                        color: _mode == ScreenMode.mirror
                            ? Colors.black
                            : Colors.transparent,
                      );
                    },
                  ),
                  if (_mode == ScreenMode.snapshot && _frameBytes != null)
                    _buildSnapshot(context),
                  if (!active)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_mode == ScreenMode.mirror &&
                            (_mirrorStarting || _mirrorError == null))
                          const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          widget.serial == null
                              ? '未连接设备'
                              : widget.devboardHwnd == null
                              ? '窗口初始化中…'
                              : (_mirrorStarting
                                    ? '正在启动实时镜像…'
                                    : (_mirrorError ?? '正在建立实时镜像…')),
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  if (_mode == ScreenMode.snapshot && _captureError != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.black54,
                        child: Text(
                          _captureError!,
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

  // 布局同步：每次构建后把 scrcpy 子窗口对齐画布
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncLayout());
  }

  Widget _buildSnapshot(BuildContext context) {
    final frame = _frameBytes!;
    return LayoutBuilder(
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
              _frameBytes is Uint8List
                  ? _frameBytes as Uint8List
                  : Uint8List.fromList(frame),
              fit: BoxFit.fill,
              gaplessPlayback: true,
            ),
          ),
        );
      },
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

// PanStart/End 空实现占位（抓帧模式滑动暂未启用）
// ignore_for_file: unused_element
