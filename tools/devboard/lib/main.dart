import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'adb_service.dart';

const _mirrorPort = 28213;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) MediaKit.ensureInitialized();
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

/// 屏幕面板：默认 scrcpy 实时镜像（H.264 串流内嵌渲染），
/// 可切换为轻量抓帧轮询（scrcpy 不可用时的降级方案）。
enum ScreenMode { mirror, snapshot }

class ScreenPanel extends StatefulWidget {
  final String? serial;
  const ScreenPanel({super.key, required this.serial});

  @override
  State<ScreenPanel> createState() => _ScreenPanelState();
}

class _ScreenPanelState extends State<ScreenPanel> {
  ScreenMode _mode = ScreenMode.mirror;

  // ── mirror（scrcpy → mkv over TCP → media_kit）──
  Player? _player;
  VideoController? _videoController;
  Process? _scrcpyProc;
  StreamSubscription? _videoParamsSub;
  Size _videoSize = const Size(1080, 2400);
  bool _mirrorStarting = false;
  String? _mirrorError;
  Offset? _dragStart;

  // ── snapshot（抓帧轮询）──
  Uint8List? _frameBytes;
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
    _startMirror();
  }

  @override
  void didUpdateWidget(covariant ScreenPanel old) {
    super.didUpdateWidget(old);
    if (old.serial != widget.serial) {
      _restartMirror();
      _frameBytes = null;
      if (_mode == ScreenMode.snapshot) _capture();
    }
  }

  // ══════════ scrcpy 实时镜像 ══════════

  ServerSocket? _mirrorServer;
  Socket? _mirrorClient;
  final _backlog = <List<int>>[];

  Future<void> _startMirror() async {
    if (widget.serial == null || _mirrorStarting) return;
    _mirrorStarting = true;
    await _stopMirror();
    if (!mounted) {
      _mirrorStarting = false;
      return;
    }
    setState(() {
      _mirrorError = null;
      _videoSize = const Size(1080, 2400);
    });

    final player = Player();
    final controller = VideoController(player);
    setState(() {
      _player = player;
      _videoController = controller;
    });

    _videoParamsSub = player.stream.videoParams.listen((p) {
      if (p.w != null && p.h != null && mounted) {
        setState(() => _videoSize = Size(p.w!.toDouble(), p.h!.toDouble()));
      }
    });
    player.stream.error.listen((msg) {
      debugPrint('[player-err] $msg');
      if (mounted) setState(() => _mirrorError = '播放器: $msg');
    });
    player.stream.log.listen((e) {
      if (e.level == 'error' || e.level == 'warn') {
        debugPrint('[mpv:${e.prefix}] ${e.text}');
      }
    });

    try {
      // 本地 TCP 中转：scrcpy 把 mkv 写到 stdout，DevBoard 转发给 media_kit
      // （scrcpy 的 avio 不支持 listen URL，stdout 由我们全权接管）
      _mirrorServer = await ServerSocket.bind('127.0.0.1', _mirrorPort);
      _mirrorServer!.listen((sock) {
        _mirrorClient = sock;
        for (final b in _backlog) {
          sock.add(b);
        }
        _backlog.clear();
      });

      final proc = await Process.start('bin/scrcpy/scrcpy.exe', [
        '-s',
        widget.serial!,
        '--no-window',
        '--no-audio',
        '--record=-',
        '--record-format=mkv',
        '--max-fps=30',
        '--video-bit-rate=8M',
      ], mode: ProcessStartMode.normal);
      _scrcpyProc = proc;
      // 等到 scrcpy 真正吐出 mkv 头（EBML 魔数）再启动播放器，
      // 否则 mpv 探针在编码协商期连上会因无数据报 format 错误
      final headerReady = Completer<void>();
      proc.stdout.listen((chunk) {
        if (!headerReady.isCompleted) {
          for (
            var i = 0;
            !headerReady.isCompleted && i + 3 < chunk.length;
            i++
          ) {
            if (chunk[i] == 0x1A &&
                chunk[i + 1] == 0x45 &&
                chunk[i + 2] == 0xDF &&
                chunk[i + 3] == 0xA3) {
              headerReady.complete();
            }
          }
        }
        final c = _mirrorClient;
        if (c != null) {
          try {
            c.add(chunk);
          } catch (_) {
            // 播放器断开（如切模式/退出），数据转入暂存等待重连
            _backlog.add(chunk);
            while (_backlog.length > 512) {
              _backlog.removeAt(0);
            }
            _mirrorClient = null;
          }
        } else {
          // 播放器尚未连上：暂存，超限丢头部防内存膨胀
          _backlog.add(chunk);
          while (_backlog.length > 512) {
            _backlog.removeAt(0);
          }
        }
      });
      try {
        await headerReady.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('scrcpy 10s 内未输出视频流');
          },
        );
      } catch (e) {
        // 实时镜像建立失败（设备端无流等）：自动回退抓帧轮询模式并提示
        proc.kill();
        _scrcpyProc = null;
        if (mounted) {
          setState(() {
            _mode = ScreenMode.snapshot;
            _captureError = '实时镜像建立失败（$e），已回退抓帧模式';
          });
          _capture();
          _schedule();
        }
        return;
      }
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
      // mpv 默认拒绝网络 URL（unsafe playlist），放行本地回环的镜像流
      await (player.platform as dynamic).setProperty(
        'load-unsafe-playlists',
        'yes',
      );
      await player.open(Media('tcp://127.0.0.1:$_mirrorPort'));
    } catch (e) {
      if (mounted) setState(() => _mirrorError = '实时镜像启动失败: $e');
    } finally {
      _mirrorStarting = false;
    }
  }

  Future<void> _stopMirror() async {
    _videoParamsSub?.cancel();
    _videoParamsSub = null;
    _scrcpyProc?.kill();
    _scrcpyProc = null;
    _mirrorClient?.destroy();
    _mirrorClient = null;
    _mirrorServer?.close();
    _mirrorServer = null;
    _backlog.clear();
    final player = _player;
    _player = null;
    _videoController = null;
    await player?.dispose();
  }

  Future<void> _restartMirror() async {
    await _stopMirror();
    if (mounted && _mode == ScreenMode.mirror) await _startMirror();
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
        _frameBytes = Uint8List.fromList(bytes);
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

  // ══════════ 操控注入 ══════════

  Offset _toDevice(Offset local, Size displaySize, Size sourceSize) => Offset(
    (local.dx / displaySize.width * sourceSize.width).round().toDouble(),
    (local.dy / displaySize.height * sourceSize.height).round().toDouble(),
  );

  Future<void> _tap(Offset local, Size display, Size source) async {
    final p = _toDevice(local, display, source);
    await AdbService.instance.deviceArgs(widget.serial, [
      'shell',
      'input',
      'tap',
      '${p.dx}',
      '${p.dy}',
    ]);
  }

  Future<void> _swipe(Offset from, Offset to, Size display, Size source) async {
    final a = _toDevice(from, display, source);
    final b = _toDevice(to, display, source);
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
        ? (_videoController != null)
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
              // 模式切换：实时镜像（默认）/ 抓帧预览
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
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_mode == ScreenMode.mirror)
                    _buildMirror()
                  else
                    _buildSnapshot(context),
                  if (!active && _mode == ScreenMode.mirror)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_mirrorStarting || _mirrorError == null)
                          const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          widget.serial == null
                              ? '未连接设备'
                              : (_mirrorError ?? '正在建立实时镜像…'),
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  if (_mode == ScreenMode.mirror &&
                      _mirrorError != null &&
                      _videoController == null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.black54,
                        child: Text(
                          _mirrorError!,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                          ),
                        ),
                      ),
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

  Widget _buildMirror() {
    final controller = _videoController;
    if (controller == null) return const SizedBox.expand();
    return LayoutBuilder(
      builder: (context, constraints) {
        final aspect = _videoSize.width / _videoSize.height;
        var w = constraints.maxWidth;
        var h = w / aspect;
        if (h > constraints.maxHeight) {
          h = constraints.maxHeight;
          w = h * aspect;
        }
        final display = Size(w, h);
        return GestureDetector(
          onTapDown: (d) => _tap(d.localPosition, display, _videoSize),
          onPanStart: (d) => _dragStart = d.localPosition,
          onPanEnd: (d) {
            if (_dragStart != null) {
              _swipe(_dragStart!, d.localPosition, display, _videoSize);
              _dragStart = null;
            }
          },
          child: SizedBox(
            width: w,
            height: h,
            child: Video(controller: controller, fit: BoxFit.fill),
          ),
        );
      },
    );
  }

  Widget _buildSnapshot(BuildContext context) {
    if (_frameBytes == null) return const SizedBox.expand();
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
          onTapDown: (d) => _tap(d.localPosition, display, _screenSize),
          onPanStart: (d) => _dragStart = d.localPosition,
          onPanEnd: (d) {
            if (_dragStart != null) {
              _swipe(_dragStart!, d.localPosition, display, _screenSize);
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
