import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'adb_service.dart';

/// 实时镜像：`adb screenrecord` 出裸 H.264 → 本地 TCP → ffmpeg 零重编码转
/// MPEG-TS → Dart 转发给进程内 mpv，由 media_kit 以 Flutter 纹理渲染。
///
/// 为什么不用 scrcpy 原生窗口 SetParent 内嵌：
/// 1) airspace —— Flutter 用 D3D 交换链渲染，外部 SDL/D3D 窗口盖在交换链
///    之上，父窗口每次 present（悬停控件触发重绘）都会闪一下；
/// 2) SDL 的 swapchain 在 reparent 后不跟随窗口缩放，画面既不会等比拉伸，
///    最大化后还保持原尺寸。
/// 用 Flutter 纹理渲染天然随布局缩放、不闪、可被面板裁剪。
class MirrorController {
  MirrorController(this._serial);

  final String? _serial;

  static const int _h264Port = 28221;
  static const int _tsPort = 28222;

  Process? _ffmpegProc;
  Process? _recProc;
  Player? _player;
  VideoController? _videoController;

  ServerSocket? _h264Server;
  ServerSocket? _tsServer;
  Socket? _ffmpegIn;
  Socket? _playerIn;

  /// ffmpeg 尚未连入时先缓存 h264 分片
  final _backlog = <List<int>>[];

  /// 播放器尚未连入时先缓存 TS 分片（含 SPS/PPS + IDR 关键帧）
  final _tsBacklog = <List<int>>[];

  StreamSubscription<List<int>>? _recOutSub;
  StreamSubscription<List<int>>? _ffmpegOutSub;
  StreamSubscription<VideoParams>? _videoParamsSub;
  StreamSubscription<String>? _errorSub;
  Timer? _restartTimer;

  bool _started = false;
  bool _stopping = false;
  int _retries = 0;
  int _tsBytesOut = 0;
  bool _fatalReported = false;
  Size _videoSize = const Size(1080, 2400);

  Player? get player => _player;
  VideoController? get videoController => _videoController;
  Size get videoSize => _videoSize;

  /// 致命错误回调（锁屏导致 screenrecord 报错、ffmpeg 退出等）
  void Function(String message)? onFatal;

  Future<void> start() async {
    if (_started || _serial == null) return;
    _started = true;
    _stopping = false;
    _retries = 0;
    _tsBytesOut = 0;
    _fatalReported = false;

    // 息屏时 screenrecord 无法编码，先确保屏幕点亮
    try {
      if (await AdbService.instance.wakefulness(_serial) != 'Awake') {
        await AdbService.instance.wakeUp(_serial);
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }
    } catch (_) {}

    // 1) 两个本地中转口：h264 收 ffmpeg，TS 供 mpv 连入
    _h264Server = await ServerSocket.bind('127.0.0.1', _h264Port);
    _h264Server!.listen((s) {
      _ffmpegIn = s;
      for (final b in _backlog) {
        s.add(b);
      }
      _backlog.clear();
    });
    _tsServer = await ServerSocket.bind('127.0.0.1', _tsPort);
    _tsServer!.listen((s) {
      _playerIn = s;
      // 把 mpv 连入前积压的 TS 补发过去：流首的 SPS/PPS 与 IDR 关键帧
      // 一旦错过，mpv 会一直等关键帧，表现为黑屏。
      for (final b in _tsBacklog) {
        try {
          s.add(b);
        } catch (_) {
          break;
        }
      }
      _tsBacklog.clear();
    });

    // 2) ffmpeg：裸 h264 → TS，零重编码
    final ffmpeg = await AdbService.instance.resolveFfmpeg();
    if (ffmpeg == null) {
      throw Exception('未找到 ffmpeg.exe（用于转封装），请安装并加入 PATH');
    }
    // TS 必须走 stdout 由 Dart 转发：若写成 tcp://127.0.0.1:$_tsPort，
    // ffmpeg 会自己连到本进程的 _tsServer，与随后连入的 mpv 变成两个
    // 互不相通的客户端，mpv 收不到数据。
    _ffmpegProc = await Process.start(ffmpeg, [
      '-loglevel',
      'error',
      '-f',
      'h264',
      '-i',
      'tcp://127.0.0.1:$_h264Port',
      '-c',
      'copy',
      '-flush_packets',
      '1',
      '-f',
      'mpegts',
      'pipe:1',
    ], mode: ProcessStartMode.normal);
    _ffmpegOutSub = _ffmpegProc!.stdout.listen((chunk) {
      _tsBytesOut += chunk.length;
      final p = _playerIn;
      if (p != null) {
        try {
          p.add(chunk);
        } catch (_) {}
      } else {
        _tsBacklog.add(chunk);
        while (_tsBacklog.length > 256) {
          _tsBacklog.removeAt(0);
        }
      }
    });
    _ffmpegProc!.stderr.cast<List<int>>().transform(systemEncoding.decoder).listen(
      (l) => debugPrint('[ffmpeg] $l'),
    );
    unawaited(
      _ffmpegProc!.exitCode.then((code) {
        if (_stopping) return;
        debugPrint('[mirror] ffmpeg 退出 code=$code');
        onFatal?.call('转封装进程退出（code=$code）');
      }),
    );

    // 3) 播放器：mpv 渲染到 Flutter 纹理
    final player = Player();
    _player = player;
    await (player.platform as dynamic).setProperty(
      'load-unsafe-playlists',
      'yes',
    );
    // 直播流必须关缓存：mpv 默认按 cache-secs 预缓冲，静态画面码率极低
    // （~1-2KB/s）永远填不满缓存，会一直停在 buffering——表现为播了 2 秒
    // 就卡住不动。cache-pause=no 让缓存不足时继续播而不是暂停等待。
    await (player.platform as dynamic).setProperty('cache', 'no');
    await (player.platform as dynamic).setProperty('cache-pause', 'no');
    await (player.platform as dynamic).setProperty(
      'demuxer-lavf-o',
      'fflags=+nobuffer',
    );
    _videoController = VideoController(player);
    _videoParamsSub = player.stream.videoParams.listen((p) {
      if (p.w != null && p.h != null && p.w! > 0 && p.h! > 0) {
        _videoSize = Size(p.w!.toDouble(), p.h!.toDouble());
      }
    });
    _errorSub = player.stream.error.listen((msg) {
      debugPrint('[mirror-player-err] $msg');
    });

    // 4) 启动 screenrecord，等 ffmpeg 产出首个 TS 分片后再让 mpv 连接
    _startRecord();
    for (var i = 0; i < 60; i++) {
      if (_tsBytesOut > 0 || _fatalReported) break;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    if (_stopping) return;
    if (_tsBytesOut == 0) {
      // 没有码流就不要 open：mpv 会阻塞在 open 上，界面会一直卡在启动态
      if (!_fatalReported) {
        onFatal?.call('未收到画面数据，请确认手机已解锁并点亮屏幕');
      }
      return;
    }
    unawaited(player.open(Media('tcp://127.0.0.1:$_tsPort')));
  }

  /// 识别 screenrecord 写到 stdout 的错误文本（如锁屏时的
  /// INVALID_LAYER_STACK），命中则上报一次并丢弃该分片。
  bool _checkFatal(List<int> chunk) {
    if (chunk.length > 256) return false;
    if (!String.fromCharCodes(chunk.take(5)).startsWith('ERROR')) return false;
    if (!_fatalReported) {
      _fatalReported = true;
      onFatal?.call(String.fromCharCodes(chunk).trim());
    }
    return true;
  }

  void _startRecord() async {
    if (_stopping || _serial == null) return;
    final adb = await AdbService.instance.resolveAdb();
    final proc = await Process.start(adb, [
      '-s',
      _serial,
      'exec-out',
      'screenrecord',
      '--time-limit=170',
      '--output-format=h264',
      '-',
    ], mode: ProcessStartMode.normal);
    _recProc = proc;
    proc.stderr.cast<List<int>>().transform(systemEncoding.decoder).listen((l) {
      final t = l.trim();
      if (t.isNotEmpty) debugPrint('[screenrecord-err] $t');
    });
    _recOutSub = proc.stdout.listen((chunk) {
      if (_checkFatal(chunk)) return;
      final f = _ffmpegIn;
      if (f != null) {
        try {
          f.add(chunk);
        } catch (_) {
          _backlog.add(chunk);
          _ffmpegIn = null;
        }
      } else {
        _backlog.add(chunk);
        while (_backlog.length > 256) {
          _backlog.removeAt(0);
        }
      }
    });
    unawaited(
      proc.exitCode.then((code) {
        _recProc = null;
        debugPrint('[mirror] screenrecord 退出 code=$code');
        if (_stopping) return;
        if (code != 0 && _retries < 3) {
          _retries++;
          _restartTimer?.cancel();
          _restartTimer = Timer(const Duration(seconds: 2), () {
            if (!_stopping) _startRecord();
          });
          return;
        }
        _restartTimer?.cancel();
        _restartTimer = Timer(const Duration(seconds: 2), () {
          if (!_stopping) _startRecord();
        });
      }),
    );
  }

  Future<void> stop() async {
    debugPrint('[mc] stop() 被调用\n${StackTrace.current}');
    _stopping = true;
    _restartTimer?.cancel();
    await _recOutSub?.cancel();
    await _ffmpegOutSub?.cancel();
    await _videoParamsSub?.cancel();
    await _errorSub?.cancel();
    _recProc?.kill();
    _ffmpegProc?.kill();
    _recProc = null;
    _ffmpegProc = null;
    try {
      await _ffmpegIn?.close();
    } catch (_) {}
    try {
      await _playerIn?.close();
    } catch (_) {}
    _ffmpegIn = null;
    _playerIn = null;
    _backlog.clear();
    _tsBacklog.clear();
    await _h264Server?.close();
    await _tsServer?.close();
    _h264Server = null;
    _tsServer = null;
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
    _videoController = null;
    _started = false;
  }
}
