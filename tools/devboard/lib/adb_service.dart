import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// adb 访问层：路径自动探测、设备管理、输入注入、截屏帧抓取。
/// 全部通过 Process.run 调用本机 adb.exe，无线/USB 设备通用。
class AdbService {
  AdbService._();
  static final AdbService instance = AdbService._();

  String? _adbPath;

  /// 探测 adb：环境变量 DEVBOARD_ADB → 随包附带的 scrcpy adb → PATH → Android SDK 默认位置
  ///
  /// 必须优先用随包 adb：不同版本 adb 客户端会互相杀掉对方的 server 并重启，
  /// 正在执行的 `exec-out screenrecord` 会被掐断（表现为 screenrecord 退出
  /// code=-1、码流截断，进而 ffmpeg 报 Error submitting a packet to the muxer）。
  Future<String> resolveAdb() async {
    if (_adbPath != null) return _adbPath!;
    final candidates = <String>[
      Platform.environment['DEVBOARD_ADB'] ?? '',
      _findBundledAdb() ?? '',
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

  /// 从可执行文件所在目录逐级向上找随包 adb
  /// （调试构建在 build/windows/x64/runner/Debug，打包后与 bin 同级）。
  String? _findBundledAdb() {
    var dir = File(Platform.resolvedExecutable).parent;
    for (var i = 0; i < 6; i++) {
      for (final sub in const ['bin/scrcpy27/adb.exe', 'bin/scrcpy/adb.exe']) {
        final f = File('${dir.path}/$sub');
        if (f.existsSync()) return f.path;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return null;
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

  // ────────────────────── 应用安装/卸载 ──────────────────────

  /// 安装 APK（-r 覆盖安装，-t 允许测试包）
  Future<String> installApk(String? serial, String apkPath) async {
    final r = await _run([
      if (serial != null && serial.isNotEmpty) ...['-s', serial],
      'install',
      '-r',
      '-t',
      apkPath,
    ], timeout: const Duration(minutes: 3));
    final out = '${r.stdout}\n${r.stderr}'.trim();
    return out.contains('Success')
        ? 'SUCCESS'
        : 'ERR: ${out.isEmpty ? 'exit ${r.exitCode}' : out}';
  }

  Future<String> uninstallPackage(String? serial, String pkg) => deviceArgs(
    serial,
    ['uninstall', pkg],
    timeout: const Duration(minutes: 1),
  );

  /// 已安装三方包列表（排除系统包，供卸载下拉选择）
  Future<List<String>> thirdPartyPackages(String? serial) async {
    final out = await deviceArgs(serial, [
      'shell',
      'pm',
      'list',
      'packages',
      '-3',
    ]);
    return out
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.startsWith('package:'))
        .map((l) => l.substring('package:'.length).trim())
        .toList()
      ..sort();
  }

  // ────────────────────── logcat 实时流 ──────────────────────

  /// 启动 logcat 进程；[filter] 支持 tag/文本关键字过滤（客户端侧过滤，
  /// 避免 shell 引号转义问题）。
  Future<Process> startLogcat(String? serial, {int lines = 400}) async {
    final adb = await resolveAdb();
    return Process.start(adb, [
      if (serial != null && serial.isNotEmpty) ...['-s', serial],
      'logcat',
      '-v',
      'time',
      '-T',
      '$lines',
    ]);
  }

  // ────────────────────── 设备信息 ──────────────────────

  /// 汇总设备关键信息（型号/系统/分辨率/电量/存储）
  Future<List<MapEntry<String, String>>> deviceInfo(String? serial) async {
    Future<String> prop(String key) async {
      final out = await deviceArgs(serial, ['shell', 'getprop', key]);
      return out.replaceAll('ERR:', '').trim();
    }

    final model = await prop('ro.product.model');
    final brand = await prop('ro.product.brand');
    final release = await prop('ro.build.version.release');
    final sdk = await prop('ro.build.version.sdk');
    final abi = await prop('ro.product.cpu.abi');
    final sizeOut = await deviceArgs(serial, ['shell', 'wm', 'size']);
    final size = RegExp(r'(\d+x\d+)').firstMatch(sizeOut)?.group(1) ?? '-';
    final densityOut = await deviceArgs(serial, ['shell', 'wm', 'density']);
    final density = RegExp(
      r'(\d+)',
    ).allMatches(densityOut).map((m) => m.group(1)!).join('/');
    final batteryOut = await deviceArgs(serial, [
      'shell',
      'dumpsys',
      'battery',
    ]);
    final level =
        RegExp(r'level:\s*(\d+)').firstMatch(batteryOut)?.group(1) ?? '-';
    final status =
        RegExp(r'status:\s*(\d+)').firstMatch(batteryOut)?.group(1) ?? '-';
    final storageOut = await deviceArgs(serial, ['shell', 'df', '-h', '/data']);
    final storageLine =
        storageOut
            .split(RegExp(r'\r?\n'))
            .where((l) => l.contains('/data'))
            .firstOrNull ??
        '';
    final storageParts = storageLine.split(RegExp(r'\s+'));

    return [
      MapEntry('品牌型号', '$brand $model'.trim()),
      MapEntry('Android', '$release (API $sdk)'),
      MapEntry('CPU ABI', abi.isEmpty ? '-' : abi),
      MapEntry('分辨率', size),
      MapEntry('像素密度', density.isEmpty ? '-' : density),
      MapEntry('电量', '$level% (status $status)'),
      if (storageParts.length >= 4)
        MapEntry(
          '/data 用量',
          '${storageParts[2]} / ${storageParts[1]}（剩余 ${storageParts[3]}）',
        ),
    ];
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
  /// 定位 scrcpy.exe。
  /// Flutter debug 运行时的进程 cwd 可能是 build/windows/.../runner/Debug，
  /// 相对路径不可靠 —— 从 cwd 与可执行文件目录分别向上回溯查找 bin/scrcpy。
  Future<String?> resolveScrcpy() async {
    if (_scrcpyPath != null) return _scrcpyPath;

    // 顺序与 resolveAdb 保持一致：scrcpy 会用它同目录下的 adb，
    // 两套工具的 adb 版本不同（35 vs 36），混用会互杀 server 掐断镜像流。
    const rels = ['bin/scrcpy27/scrcpy.exe', 'bin/scrcpy/scrcpy.exe'];
    final roots = <Directory>[
      Directory.current,
      File(Platform.resolvedExecutable).parent,
    ];
    for (final rel in rels) {
      for (final root in roots) {
        var dir = root;
        for (var depth = 0; depth < 8; depth++) {
          final candidate = File(
            '${dir.path}${Platform.pathSeparator}'
            '${rel.replaceAll('/', Platform.pathSeparator)}',
          );
          if (await candidate.exists()) {
            _scrcpyPath = candidate.absolute.path;
            return _scrcpyPath;
          }
          final parent = dir.parent;
          if (parent.path == dir.path) break;
          dir = parent;
        }
      }
    }
    // 兜底：PATH 中的 scrcpy
    try {
      final r = await Process.run('scrcpy.exe', ['--version']);
      if (r.exitCode == 0) {
        _scrcpyPath = 'scrcpy.exe';
        return _scrcpyPath;
      }
    } catch (_) {}
    return null;
  }

  String? _scrcpyPath;

  /// 定位 ffmpeg.exe（用于把 screenrecord 裸 H.264 实时转封装成 TS，
  /// 供 mpv 稳定播放）。探测：PATH → chocolatey → 常见目录。
  Future<String?> resolveFfmpeg() async {
    if (_ffmpegPath != null) return _ffmpegPath;
    final candidates = <String>[
      'ffmpeg',
      r'C:\ProgramData\chocolateyinfmpeg.exe',
      r'C:fmpeginfmpeg.exe',
    ];
    for (final c in candidates) {
      try {
        final r = await Process.run(
          c,
          ['-version'],
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );
        if (r.exitCode == 0 && (r.stdout as String).contains('ffmpeg')) {
          _ffmpegPath = c == 'ffmpeg' ? 'ffmpeg' : c;
          return _ffmpegPath;
        }
      } catch (_) {}
    }
    return null;
  }

  String? _ffmpegPath;

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

  /// 屏幕唤醒状态（Awake / Dozing / Asleep）
  /// 屏幕是否点亮。
  ///
  /// 注意：不能只看 `dumpsys power` 的 `mWakefulness`——部分 ROM（MIUI 等）
  /// 息屏后该值仍为 Awake，此时 screencap/screenrecord 只会得到黑屏
  /// （screenrecord 还会往 stdout 吐 ERROR: INVALID_LAYER_STACK）。
  /// 真实状态以 `dumpsys display` 的 mScreenState 为准。
  Future<String> wakefulness(String? serial) async {
    final out = await deviceArgs(serial, ['shell', 'dumpsys', 'display']);
    final m = RegExp(r'mScreenState=(ON|OFF)').firstMatch(out);
    if (m != null) return m.group(1) == 'ON' ? 'Awake' : 'Asleep';
    final p = await deviceArgs(serial, ['shell', 'dumpsys', 'power']);
    final m2 = RegExp(r'mWakefulness=(\w+)').firstMatch(p);
    return m2?.group(1) ?? 'Unknown';
  }

  /// 唤醒屏幕（息屏时 screencap 只会返回全黑图）。
  ///
  /// KEYCODE_WAKEUP 在部分 ROM 上只把 Wakefulness 置为 Awake 而不点亮面板，
  /// 因此面板关闭时改用电源键；随后解除锁屏，避免抓到的仍是锁屏/黑屏。
  Future<void> wakeUp(String? serial) async {
    if (await wakefulness(serial) != 'Awake') {
      await deviceArgs(serial, ['shell', 'input', 'keyevent', '26']);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    await deviceArgs(serial, ['shell', 'wm', 'dismiss-keyguard']);
  }

  /// 延长息屏超时（10 分钟），减少预览期间自动息屏
  Future<void> keepScreenOn(String? serial) => deviceArgs(serial, [
    'shell',
    'settings',
    'put',
    'system',
    'screen_off_timeout',
    '600000',
  ]);
}

class DeviceEntry {
  final String serial;
  final String state;
  final String model;
  DeviceEntry({required this.serial, required this.state, required this.model});

  bool get online => state == 'device';
}
