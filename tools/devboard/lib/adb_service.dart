import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// adb 访问层：路径自动探测、设备管理、输入注入、截屏帧抓取。
/// 全部通过 Process.run 调用本机 adb.exe，无线/USB 设备通用。
class AdbService {
  AdbService._();
  static final AdbService instance = AdbService._();

  String? _adbPath;

  /// 探测 adb：环境变量 DEVBOARD_ADB → PATH → Android SDK 默认位置
  Future<String> resolveAdb() async {
    if (_adbPath != null) return _adbPath!;
    final candidates = <String>[
      Platform.environment['DEVBOARD_ADB'] ?? '',
      'adb',
      r'C:\android-sdk\platform-tools\adb.exe',
      Platform.environment['LOCALAPPDATA'] != null
          ? '${Platform.environment['LOCALAPPDATA']!}\\Android\\Sdk\\platform-tools\\adb.exe'
          : '',
    ].where((c) => c.isNotEmpty).toList();

    for (final candidate in candidates) {
      try {
        final r = await Process.run(
          candidate,
          ['version'],
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );
        if (r.exitCode == 0) {
          _adbPath = candidate;
          return candidate;
        }
      } catch (_) {}
    }
    throw Exception('未找到 adb.exe，请设置环境变量 DEVBOARD_ADB 指向 adb 路径');
  }

  Future<ProcessResult> _run(
    List<String> args, {
    Duration? timeout,
    bool binaryStdout = false,
  }) async {
    final adb = await resolveAdb();
    return Process.run(
      adb,
      args,
      stdoutEncoding: binaryStdout ? null : utf8,
      stderrEncoding: utf8,
    ).timeout(timeout ?? const Duration(seconds: 20));
  }

  Future<String> raw(List<String> args, {Duration? timeout}) async {
    final r = await _run(args, timeout: timeout);
    final out = (r.stdout as String).trim();
    final err = (r.stderr as String).trim();
    if (r.exitCode != 0 && err.isNotEmpty) return 'ERR: $err';
    return out;
  }

  /// 带设备序列执行
  Future<String> deviceArgs(
    String? serial,
    List<String> args, {
    Duration? timeout,
  }) {
    final full = <String>[
      if (serial != null && serial.isNotEmpty) ...['-s', serial],
      ...args,
    ];
    return raw(full, timeout: timeout);
  }

  Future<List<DeviceEntry>> devices() async {
    final out = await raw(['devices', '-l']);
    final entries = <DeviceEntry>[];
    // -l 长格式为空格对齐且 Windows 行尾带 \r，用状态字正则解析而非 tab 切分
    final lineRe = RegExp(
      r'^(\S+)\s+(device|offline|unauthorized|recovery|sideload)\b',
    );
    for (final line in out.split(RegExp(r'\r?\n'))) {
      final m = lineRe.firstMatch(line.trim());
      if (m == null) continue;
      final serial = m.group(1)!;
      final state = m.group(2)!;
      final model = RegExp(r'model:(\S+)').firstMatch(line)?.group(1) ?? serial;
      entries.add(
        DeviceEntry(
          serial: serial,
          state: state,
          model: state == 'device' ? model : serial,
        ),
      );
    }
    return entries;
  }

  Future<String> connect(String hostPort) async {
    final out = await raw([
      'connect',
      hostPort,
    ], timeout: const Duration(seconds: 10));
    if (out.contains('connected to') && !out.contains('cannot')) {
      await rememberConnectTarget(hostPort);
    }
    return out;
  }

  /// 上次成功连接的 IP:端口（无线调试开关期间端口通常不变，配对后优先重试）
  Future<String?> lastConnectTarget() async {
    try {
      final f = File('.devboard_last_connect');
      if (await f.exists()) {
        final v = (await f.readAsString()).trim();
        return v.isEmpty ? null : v;
      }
    } catch (_) {}
    return null;
  }

  Future<void> rememberConnectTarget(String target) async {
    try {
      await File('.devboard_last_connect').writeAsString(target);
    } catch (_) {}
  }

  /// 定位 scrcpy.exe：bin/scrcpy/（仓库内）→ PATH
  Future<String?> resolveScrcpy() async {
    final candidates = <String>['bin/scrcpy/scrcpy.exe', 'scrcpy.exe'];
    for (final c in candidates) {
      final f = File(c);
      if (await f.exists()) return f.absolute.path;
    }
    return null;
  }

  /// 启动 scrcpy 独立实时镜像窗口（H.264 硬件编码串流，30-60fps）
  Future<void> launchScrcpy(String? serial) async {
    final exe = await resolveScrcpy();
    if (exe == null) {
      throw Exception('未找到 scrcpy.exe，请下载解压到 bin/scrcpy/（见 README）');
    }
    await Process.start(exe, [
      if (serial != null && serial.isNotEmpty) ...['-s', serial],
      '--window-title',
      'DevBoard Mirror',
    ], mode: ProcessStartMode.detached);
  }

  /// 抓取当前屏幕 PNG 字节（无线设备约 1-2s）
  Future<List<int>> screencap(String? serial) async {
    final r = await _run(
      [
        if (serial != null && serial.isNotEmpty) ...['-s', serial],
        'exec-out',
        'screencap',
        '-p',
      ],
      timeout: const Duration(seconds: 12),
      binaryStdout: true,
    );
    if (r.exitCode != 0) {
      throw Exception('screencap 失败: ${r.stderr}');
    }
    final bytes = r.stdout as List<int>;
    // Windows 下 adb 可能把 \n 转成 \r\n 破坏 PNG：exec-out 通常不转换，校验魔数兜底
    if (bytes.length > 8 && bytes[0] == 0x89 && bytes[1] == 0x50) {
      return bytes;
    }
    final fixed = _fixCrlf(bytes);
    if (fixed.length > 8 && fixed[0] == 0x89 && fixed[1] == 0x50) return fixed;
    throw Exception('screencap 返回非 PNG 数据');
  }

  /// 把 stdout 中被 CRLF 污染的 PNG 修复（0x0D 0x0A → 0x0A）
  List<int> _fixCrlf(List<int> bytes) {
    final out = <int>[];
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] == 0x0D && i + 1 < bytes.length && bytes[i + 1] == 0x0A) {
        continue;
      }
      out.add(bytes[i]);
    }
    return out;
  }

  Future<String> screenMeta(String? serial) =>
      deviceArgs(serial, ['shell', 'wm', 'size']);
}

class DeviceEntry {
  final String serial;
  final String state;
  final String model;
  DeviceEntry({required this.serial, required this.state, required this.model});

  bool get online => state == 'device';
}
