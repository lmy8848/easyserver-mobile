import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'adb_service.dart';
import 'mirror_controller.dart';

/// 屏幕面板。
///
/// 实时模式：adb screenrecord → ffmpeg 转封装 → 进程内 mpv 渲染成 Flutter
/// 纹理。画面是普通 Widget，随窗口缩放等比拉伸、可被面板裁剪，不会出现
/// 原生窗口内嵌时的闪烁/不缩放问题；点按滑动通过 adb 注入。
/// 抓帧模式：screencap 轮询，作为降级手段。
enum ScreenMode { mirror, snapshot }

class ScreenPanel extends StatefulWidget {
  final String? serial;

  /// 回传视频尺寸，外层据此把面板宽度收成手机比例（避免两侧黑边）
  final void Function(Size video)? onMetrics;

  const ScreenPanel({super.key, required this.serial, this.onMetrics});

  @override
  State<ScreenPanel> createState() => _ScreenPanelState();
}

class _ScreenPanelState extends State<ScreenPanel> {
  ScreenMode _mode = ScreenMode.mirror;
  Offset? _dragStart;

  // ── mirror（Flutter 纹理渲染）──
  MirrorController? _mirror;
  bool _startingMirror = false;
  String? _mirrorError;
  Timer? _retryTimer;
  int _retryCount = 0;

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
      debugPrint('[sp] serial ${old.serial} -> ${widget.serial}');
      _frameBytes = null;
      if (_mode == ScreenMode.mirror) {
        _restartMirror();
      } else {
        _capture();
      }
    }
  }

  // ══════════ 实时镜像 ══════════

  Future<void> _startMirror() async {
    debugPrint('[sp] startMirror serial=${widget.serial} starting=$_startingMirror');
    if (_startingMirror || widget.serial == null) return;
    _startingMirror = true;
    setState(() => _mirrorError = null);
    final mirror = MirrorController(widget.serial);
    _mirror = mirror;
    mirror.onFatal = (msg) {
      if (!mounted) return;
      setState(() => _mirrorError = '实时镜像不可用：$msg');
      _scheduleAutoRetry();
    };
    try {
      await mirror.start();
    } catch (e) {
      if (mounted) setState(() => _mirrorError = '实时镜像启动失败: $e');
    } finally {
      // 必须 setState：否则码流已通也不会重建，界面停在「正在启动」
      if (mounted) {
        setState(() => _startingMirror = false);
      } else {
        _startingMirror = false;
      }
    }
    if (mounted && _mirrorError == null) _retryCount = 0;
    _reportMetrics();
  }

  Future<void> _stopMirror() async {
    debugPrint('[sp] stopMirror');
    _retryTimer?.cancel();
    final m = _mirror;
    _mirror = null;
    await m?.stop();
  }

  Future<void> _restartMirror() async {
    await _stopMirror();
    if (mounted) await _startMirror();
  }

  /// 镜像失败后按 4/8/16/30 秒退避重建整条管道。
  /// 典型场景：App 启动时手机还锁着 → screenrecord 报错、ffmpeg 拿不到码流
  /// 退出；用户解锁后若不重建就会一直是黑屏。
  void _scheduleAutoRetry() {
    _retryTimer?.cancel();
    const delays = [4, 8, 16, 30];
    final delay = delays[_retryCount < delays.length ? _retryCount : 3];
    if (_retryCount < delays.length) _retryCount++;
    _retryTimer = Timer(Duration(seconds: delay), () async {
      if (!mounted || _mode != ScreenMode.mirror) return;
      if (_startingMirror) {
        _scheduleAutoRetry();
        return;
      }
      var awake = 'Unknown';
      try {
        awake = await AdbService.instance.wakefulness(widget.serial);
      } catch (_) {}
      if (!mounted || _mode != ScreenMode.mirror) return;
      if (awake != 'Awake') {
        _scheduleAutoRetry();
        return;
      }
      await _restartMirror();
    });
  }

  void _reportMetrics() {
    final v = _mirror?.videoSize;
    if (v == null) return;
    widget.onMetrics?.call(v);
  }

  // ══════════ 抓帧轮询（降级模式）══════════

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (!_auto) return;
    final elapsed = DateTime.now().difference(_lastCaptureAt).inMilliseconds;
    final wait =
        elapsed >= _intervalSec * 1000 ? 0 : _intervalSec * 1000 - elapsed;
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
        widget.onMetrics?.call(_screenSize);
      }
    } catch (_) {}
  }

  // ══════════ 坐标注入（实时/抓帧共用）══════════

  Size get _sourceSize => _mirror?.videoSize ?? _screenSize;

  Offset _toDevice(Offset local, Size display) => Offset(
    (local.dx / display.width * _sourceSize.width).round().toDouble(),
    (local.dy / display.height * _sourceSize.height).round().toDouble(),
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
    _retryTimer?.cancel();
    _stopMirror();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: widget.serial ?? '未连接设备',
                    child: Text(
                      '屏幕监视',
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SegmentedButton<ScreenMode>(
                  segments: const [
                    ButtonSegment(
                      value: ScreenMode.mirror,
                      icon: Tooltip(
                        message: '实时镜像',
                        child: Icon(Icons.live_tv, size: 16),
                      ),
                    ),
                    ButtonSegment(
                      value: ScreenMode.snapshot,
                      icon: Tooltip(
                        message: '抓帧模式',
                        child: Icon(Icons.image_outlined, size: 16),
                      ),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => _switchMode(s.first),
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity(horizontal: -3, vertical: -2),
                  ),
                ),
                const SizedBox(width: 4),
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
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
                color: Colors.black,
              ),
              clipBehavior: Clip.antiAlias,
              child: _mode == ScreenMode.mirror
                  ? _buildMirror(theme)
                  : _buildSnapshot(theme),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                _keyBtn(Icons.arrow_back, '返回', 4),
                _keyBtn(Icons.home_outlined, '主页', 3),
                _keyBtn(Icons.crop_square, '多任务', 187),
                _keyBtn(Icons.power_settings_new, '电源', 26),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '发送文本',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _sendText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMirror(ThemeData theme) {
    final controller = _mirror?.videoController;
    if (controller == null || _mirrorError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_mirrorError == null) const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                widget.serial == null
                    ? '未连接设备'
                    : (_startingMirror
                        ? '正在启动实时镜像…'
                        : (_mirrorError ?? '正在建立实时镜像…')),
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    // 按视频宽高比铺满画布：等比拉伸，不留黑边
    return LayoutBuilder(
      builder: (context, c) {
        final src = _mirror?.videoSize ?? const Size(1080, 2400);
        final aspect = src.width / src.height;
        var w = c.maxWidth;
        var h = w / aspect;
        if (h > c.maxHeight) {
          h = c.maxHeight;
          w = h * aspect;
        }
        final display = Size(w, h);
        return Center(
          child: GestureDetector(
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
              child: Video(controller: controller, fit: BoxFit.fill),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSnapshot(ThemeData theme) {
    if (_frameBytes == null) {
      return Center(
        child: Text(
          _captureError ?? '正在抓帧…',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      );
    }
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
        return Center(
          child: GestureDetector(
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
