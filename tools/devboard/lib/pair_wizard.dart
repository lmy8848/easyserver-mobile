import 'dart:async';

import 'package:flutter/material.dart';

import 'adb_service.dart';

/// 无线配对向导：手机「无线调试 → 使用配对码配对设备」弹窗的
/// 端口 + 6 位配对码 → adb pair → mDNS 自动发现连接端口 → connect。
/// 配对一次永久有效，之后只需 connect。
class PairWizardDialog extends StatefulWidget {
  final VoidCallback? onConnected;
  const PairWizardDialog({super.key, this.onConnected});
  @override
  State<PairWizardDialog> createState() => _PairWizardDialogState();
}

class _PairWizardDialogState extends State<PairWizardDialog> {
  final _portController = TextEditingController();
  final _codeController = TextEditingController();
  String _status = '';
  bool _busy = false;
  Timer? _discoverTimer;
  bool _autoFilled = false;

  @override
  void initState() {
    super.initState();
    // 自动发现：配对弹窗打开期间设备广播 _adb-tls-pairing，端口自动填入，
    // 用户只需照手机上的 6 位码填一次
    _discoverTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_busy || _autoFilled || !mounted) return;
      final port = await _discoverPairingPort();
      if (port != null && mounted && !_autoFilled) {
        setState(() {
          _portController.text = port;
          _autoFilled = true;
          _status = '已自动识别配对端口 $port（来自设备广播）';
        });
      }
    });
  }

  /// 从 adb mdns services 输出解析指定服务的 host:port
  Future<String?> _discoverService(String service) async {
    final out = await AdbService.instance.raw([
      'mdns',
      'services',
    ], timeout: const Duration(seconds: 8));
    for (final line in out.split('\n')) {
      if (!line.contains(service)) continue;
      final m = RegExp(r'(\d+\.\d+\.\d+\.\d+):(\d+)').firstMatch(line);
      if (m != null) return '${m.group(1)}:${m.group(2)}';
    }
    return null;
  }

  Future<String?> _discoverPairingPort() async {
    final hit = await _discoverService('_adb-tls-pairing');
    return hit?.split(':').last;
  }

  Future<void> _pair() async {
    final port = _portController.text.trim();
    final code = _codeController.text.trim();
    if (port.isEmpty || code.length != 6) {
      setState(() => _status = '请填入弹窗上的端口和 6 位配对码');
      return;
    }
    setState(() {
      _busy = true;
      _status = '正在配对…（弹窗保持打开）';
    });
    // 配对前先刷新一次端口：mDNS 若发现比输入框更新的端口（弹窗重开过）则采用
    try {
      final fresh = await _discoverPairingPort();
      if (fresh != null && mounted) {
        _portController.text = fresh;
      }
      final out = await AdbService.instance.raw([
        'pair',
        '192.168.1.10:$port',
        code,
      ], timeout: const Duration(seconds: 15));
      final ok = out.contains('Successfully paired');
      if (!mounted) return;
      if (!ok) {
        // 10061（连接拒绝）= 弹窗已超时关闭，端口失效。
        // 重新打开弹窗即可：向导继续轮询 mDNS，新端口会自动填入。
        setState(() {
          _busy = false;
          _autoFilled = false; // 恢复自动追踪，重开弹窗后自动填新端口
          _status =
              '配对失败：$out\n'
              '配对弹窗有效期约 2 分钟，超时即失效（错误 10061）。\n'
              '请重新打开「使用配对码配对设备」弹窗，新端口会自动填入，'
              '再填新的 6 位码立即配对。';
        });
        return;
      }
      setState(() => _status = '配对成功！正在自动连接…');
      // 连接发现：上次成功端口优先（无线调试开关期间端口通常不变），
      // 再持续轮询 mDNS；全部失败时提供手动填写入口（不阻塞）
      final tried = <String>{};
      final last = await AdbService.instance.lastConnectTarget();
      if (last != null && last.isNotEmpty) tried.add(last);
      String? connected;
      for (var round = 0; round < 8; round++) {
        if (!mounted) return;
        final hit = await _discoverService('_adb-tls-connect');
        if (hit != null && hit.isNotEmpty) tried.add(hit);
        for (final t in tried.toList()) {
          if (!mounted) return;
          setState(() => _status = '正在连接 $t …（第 ${round + 1} 轮）');
          final connectOut = await AdbService.instance.raw([
            'connect',
            t,
          ], timeout: const Duration(seconds: 8));
          if (connectOut.contains('connected to') &&
              !connectOut.contains('cannot')) {
            connected = t;
            break;
          }
        }
        if (connected != null) break;
        await Future<void>.delayed(const Duration(seconds: 3));
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (connected != null) {
          _status = '已连接 $connected，可以关闭本窗口';
          widget.onConnected?.call();
          _showManualConnect = false;
        } else {
          _status =
              '配对成功，但自动连接未成功。'
              '可在下方「手动填写连接端口」（见无线调试主界面），'
              '或稍后由向导继续尝试。';
          _showManualConnect = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = '配对异常：$e';
      });
    }
  }

  bool _showManualConnect = false;

  Future<void> _manualConnect() async {
    final controller = TextEditingController(text: '192.168.1.10:');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('手动连接'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'IP:端口',
            hintText: '无线调试主界面显示的 IP:端口',
          ),
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
    if (result == null || result.isEmpty || result.endsWith(':')) return;
    setState(() => _status = '正在连接 $result …');
    final out = await AdbService.instance.raw([
      'connect',
      result,
    ], timeout: const Duration(seconds: 10));
    if (!mounted) return;
    setState(() {
      _status = out.contains('connected to') && !out.contains('cannot')
          ? '已连接 $result，可以关闭本窗口'
          : '连接：$out';
    });
    if (out.contains('connected to') && !out.contains('cannot')) {
      widget.onConnected?.call();
      setState(() => _showManualConnect = false);
    }
  }

  @override
  void dispose() {
    _discoverTimer?.cancel();
    _portController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('无线配对向导'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '① 手机：设置 → 开发者选项 → 无线调试 → 「使用配对码配对设备」，保持弹窗打开',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '② 弹窗端口（打开后自动识别）',
                      hintText: '如 41143',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: '③ 6 位配对码',
                      hintText: '如 895785',
                      counterText: '',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '端口无需手抄：打开弹窗后会自动识别（设备广播）；'
              '配对码因系统限制只能照手机显示填入',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _pair,
              child: Text(_busy ? '配对中…' : '开始配对'),
            ),
            const SizedBox(height: 12),
            if (_status.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_status, style: const TextStyle(fontSize: 12)),
              ),
            if (_showManualConnect)
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('手动填写连接端口', style: TextStyle(fontSize: 12)),
                onPressed: _busy ? null : _manualConnect,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
