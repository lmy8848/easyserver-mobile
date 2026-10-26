import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'adb_service.dart';

/// 右侧多标签面板：ADB 终端 / 实时日志 / 设备信息 / 快捷操作。
class SidePanels extends StatelessWidget {
  final String? serial;
  final List<DeviceEntry> devices;
  const SidePanels({super.key, required this.serial, required this.devices});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final d in devices)
                  Chip(
                    label: Text(
                      '${d.model} · ${d.state}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: d.serial == serial
                        ? Colors.indigo.shade50
                        : null,
                  ),
                if (devices.isEmpty)
                  const Text(
                    '暂无设备，请点右上角连接',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.terminal, size: 18), text: '终端'),
              Tab(icon: Icon(Icons.article_outlined, size: 18), text: '日志'),
              Tab(icon: Icon(Icons.info_outline, size: 18), text: '设备'),
              Tab(icon: Icon(Icons.bolt, size: 18), text: '操作'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                TerminalPanel(serial: serial),
                LogcatPanel(serial: serial),
                DeviceInfoPanel(serial: serial),
                ActionsPanel(serial: serial),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ADB 命令终端
class TerminalPanel extends StatefulWidget {
  final String? serial;
  const TerminalPanel({super.key, required this.serial});
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
      final out = await AdbService.instance.deviceArgs(
        widget.serial,
        cmd.split(RegExp(r'\s+')),
        timeout: const Duration(seconds: 30),
      );
      _append(out.isEmpty ? '(no output)' : out);
    } catch (e) {
      _append('ERR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
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

/// 实时 logcat（客户端关键字过滤 + 等级过滤）
class LogcatPanel extends StatefulWidget {
  final String? serial;
  const LogcatPanel({super.key, required this.serial});
  @override
  State<LogcatPanel> createState() => _LogcatPanelState();
}

class _LogcatPanelState extends State<LogcatPanel> {
  Process? _proc;
  StreamSubscription? _sub;
  final _lines = <String>[];
  final _listController = ScrollController();
  final _filterController = TextEditingController();
  bool _running = false;
  bool _onlyErrors = false;
  bool _autoScroll = true;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _stop();
    if (widget.serial == null) return;
    try {
      final proc = await AdbService.instance.startLogcat(widget.serial);
      _proc = proc;
      setState(() => _running = true);
      _sub = proc.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .listen(_onLine);
    } catch (e) {
      _add('启动 logcat 失败: $e');
    }
  }

  bool _match(String line) {
    if (_onlyErrors) {
      // time <level> <tag>: msg —— 仅 E/F
      final m = RegExp(
        r'^\d\d-\d\d\s+\d\d:\d\d:\d\d\.\d+\s+([A-Z])/',
      ).firstMatch(line);
      if (m == null || !(m.group(1) == 'E' || m.group(1) == 'F')) return false;
    }
    if (_keyword.isNotEmpty &&
        !line.toLowerCase().contains(_keyword.toLowerCase())) {
      return false;
    }
    return true;
  }

  void _onLine(String line) {
    if (!_match(line)) return;
    _add(line);
  }

  void _add(String line) {
    if (!mounted) return;
    setState(() {
      _lines.add(line);
      if (_lines.length > 1500) _lines.removeRange(0, _lines.length - 1500);
    });
    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_listController.hasClients) {
          _listController.jumpTo(_listController.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _stop() async {
    await _sub?.cancel();
    _sub = null;
    _proc?.kill();
    _proc = null;
    if (mounted) setState(() => _running = false);
  }

  Future<void> _restart() async {
    _lines.clear();
    await _start();
  }

  @override
  void dispose() {
    _stop();
    _listController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  Color _lineColor(String line) {
    final m = RegExp(
      r'^\d\d-\d\d\s+\d\d:\d\d:\d\d\.\d+\s+([A-Z])/',
    ).firstMatch(line);
    return switch (m?.group(1)) {
      'E' || 'F' => Colors.redAccent,
      'W' => Colors.orange,
      'I' => const Color(0xFFB8C4CC),
      _ => const Color(0xFF7A8B99),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _filterController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 16),
                    hintText: '关键字过滤（tag/文本）',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _keyword = v.trim()),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: '只看错误/致命',
                isSelected: _onlyErrors,
                icon: const Icon(Icons.report_gmailerrorred),
                onPressed: () => setState(() => _onlyErrors = !_onlyErrors),
              ),
              IconButton(
                tooltip: _autoScroll ? '自动滚动：开' : '自动滚动：关',
                icon: Icon(
                  _autoScroll ? Icons.vertical_align_bottom : Icons.pause,
                ),
                onPressed: () => setState(() => _autoScroll = !_autoScroll),
              ),
              IconButton(
                tooltip: '清空',
                icon: const Icon(Icons.delete_sweep),
                onPressed: () => setState(_lines.clear),
              ),
              IconButton(
                tooltip: _running ? '重启抓取' : '开始抓取',
                color: _running ? Colors.green : null,
                icon: Icon(_running ? Icons.refresh : Icons.play_arrow),
                onPressed: _restart,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0B0F13),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: _lines.isEmpty
                  ? Center(
                      child: Text(
                        widget.serial == null ? '未连接设备' : '等待日志…',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _listController,
                      itemCount: _lines.length,
                      itemBuilder: (context, i) => Text(
                        _lines[i],
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.25,
                          color: _lineColor(_lines[i]),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 设备信息
class DeviceInfoPanel extends StatefulWidget {
  final String? serial;
  const DeviceInfoPanel({super.key, required this.serial});
  @override
  State<DeviceInfoPanel> createState() => _DeviceInfoPanelState();
}

class _DeviceInfoPanelState extends State<DeviceInfoPanel> {
  List<MapEntry<String, String>> _info = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DeviceInfoPanel old) {
    super.didUpdateWidget(old);
    if (old.serial != widget.serial) _load();
  }

  Future<void> _load() async {
    if (widget.serial == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await AdbService.instance.deviceInfo(widget.serial);
      if (!mounted) return;
      setState(() => _info = info);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
          Row(
            children: [
              Text('设备信息', style: theme.textTheme.titleSmall),
              const Spacer(),
              if (_loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              IconButton(
                tooltip: '刷新',
                icon: const Icon(Icons.refresh),
                onPressed: _load,
              ),
            ],
          ),
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          Expanded(
            child: ListView(
              children: [
                for (final e in _info)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 92,
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SelectableText(
                            e.value,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_info.isEmpty && !_loading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('未连接设备', style: TextStyle(color: Colors.grey)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 快捷操作：装/卸 APK、截图、录屏、重启应用、系统快捷键
class ActionsPanel extends StatefulWidget {
  final String? serial;
  const ActionsPanel({super.key, required this.serial});
  @override
  State<ActionsPanel> createState() => _ActionsPanelState();
}

class _ActionsPanelState extends State<ActionsPanel> {
  final _apkController = TextEditingController();
  final _pkgController = TextEditingController();
  final _log = <String>[];
  bool _busy = false;

  void _append(String s) => setState(() {
    _log.add(s);
    if (_log.length > 200) _log.removeRange(0, _log.length - 200);
  });

  Future<void> _run(Future<String> Function() op, String label) async {
    if (_busy) return;
    setState(() => _busy = true);
    _append('▶ $label');
    try {
      final out = await op();
      _append(out.isEmpty ? '✓ 完成' : out);
    } catch (e) {
      _append('ERR: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _install() async {
    final path = _apkController.text.trim().replaceAll('"', '');
    if (path.isEmpty) {
      _append('请填写 APK 完整路径');
      return;
    }
    await _run(
      () => AdbService.instance.installApk(widget.serial, path),
      '安装 APK',
    );
  }

  Future<void> _uninstall() async {
    final pkg = _pkgController.text.trim();
    if (pkg.isEmpty) {
      _append('请填写包名');
      return;
    }
    await _run(
      () => AdbService.instance.uninstallPackage(widget.serial, pkg),
      '卸载 $pkg',
    );
  }

  /// 截图保存到本地 screenshots/ 目录
  Future<void> _screenshot() async {
    setState(() => _busy = true);
    _append('▶ 截图');
    try {
      final bytes = await AdbService.instance.screencap(widget.serial);
      final dir = Directory('screenshots');
      await dir.create(recursive: true);
      final name = 'shot-${DateTime.now().millisecondsSinceEpoch}.png';
      final f = File('${dir.path}/$name');
      await f.writeAsBytes(bytes);
      _append('✓ 已保存 ${f.absolute.path}');
    } catch (e) {
      _append('ERR: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _screenRecord() async {
    setState(() => _busy = true);
    _append('▶ 录屏 30 秒（保存到 recordings/）');
    try {
      final dir = Directory('recordings');
      await dir.create(recursive: true);
      final path =
          '${dir.absolute.path}/rec-${DateTime.now().millisecondsSinceEpoch}.mp4';
      final adb = await AdbService.instance.resolveAdb();
      // screenrecord 最长 180s；后台执行，30 秒后自动结束
      unawaited(
        Process.run(adb, [
          if (widget.serial != null && widget.serial!.isNotEmpty) ...[
            '-s',
            widget.serial!,
          ],
          'shell',
          'screenrecord',
          '--time-limit',
          '30',
          '/sdcard/devboard-rec.mp4',
        ]).then((_) async {
          await AdbService.instance.deviceArgs(widget.serial!, [
            'pull',
            '/sdcard/devboard-rec.mp4',
            path,
          ], timeout: const Duration(seconds: 90));
          await AdbService.instance.deviceArgs(widget.serial!, [
            'shell',
            'rm',
            '-f',
            '/sdcard/devboard-rec.mp4',
          ]);
          _append('✓ 录屏已保存 $path');
        }),
      );
    } catch (e) {
      _append('ERR: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _apkController.dispose();
    _pkgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          TextField(
            controller: _apkController,
            decoration: const InputDecoration(
              labelText: 'APK 路径',
              hintText: r'F:\path\to\app-debug.apk',
              isDense: true,
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.android),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _install,
                  icon: const Icon(Icons.install_mobile, size: 18),
                  label: const Text('安装'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(
                          () => AdbService.instance
                              .thirdPartyPackages(widget.serial)
                              .then((l) => l.isEmpty ? '无三方应用' : l.join('\n')),
                          '列出三方应用',
                        ),
                  icon: const Icon(Icons.list, size: 18),
                  label: const Text('列出应用'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pkgController,
            decoration: const InputDecoration(
              labelText: '卸载包名',
              hintText: 'com.example.app',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _uninstall,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('卸载'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _screenshot,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('截图'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _screenRecord,
            icon: const Icon(Icons.videocam_outlined, size: 18),
            label: const Text('录屏 30 秒'),
          ),
          const Divider(height: 24),
          Text('系统操作', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quick('亮屏', ['shell', 'input', 'keyevent', 'KEYCODE_WAKEUP']),
              _quick('锁屏', ['shell', 'input', 'keyevent', 'KEYCODE_SLEEP']),
              _quick('重启应用', [
                'shell',
                'am',
                'force-stop',
                _pkgController.text.trim().isEmpty
                    ? 'com.example.easyserver_mobile'
                    : _pkgController.text.trim(),
              ]),
              _quick('重启系统', ['reboot']),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFF101418),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: ListView(
              children: [
                for (final l in _log)
                  Text(
                    l,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFFB8C4CC),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quick(String label, List<String> args) => OutlinedButton(
    onPressed: _busy
        ? null
        : () => _run(
            () => AdbService.instance.deviceArgs(widget.serial, args),
            label,
          ),
    child: Text(label),
  );
}
