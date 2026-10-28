import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/logger/app_logger.dart';
import '../../../di/providers.dart';

class QRLoginScreen extends ConsumerStatefulWidget {
  const QRLoginScreen({super.key});
  @override
  ConsumerState<QRLoginScreen> createState() => _QRLoginScreenState();
}

class _QRLoginScreenState extends ConsumerState<QRLoginScreen> {
  MobileScannerController? _controller;
  bool _processing = false;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    // 显式持有 controller：手电筒开关需要它，异常信息也能从同一实例拿到
    _controller = MobileScannerController();
    // 扫码授权需要本机已登录（后端 confirm 有 JWT 中间件）；
    // 未登录时明确引导，避免扫码后 401 停留造成困惑
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final token = await ref.read(secureStorageProvider).getToken();
    if (!mounted) return;
    setState(() => _loggedIn = token != null && token.isNotEmpty);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null || !raw.startsWith('esqr:')) return;

    _processing = true;
    final token = raw.substring(5);
    _confirmQR(token);
  }

  Future<void> _confirmQR(String qrToken) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.confirmQrLogin(qrToken);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('扫码登录授权成功'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      _processing = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('授权失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('扫码登录'), actions: [
        IconButton(
          icon: const Icon(Icons.flash_on),
          onPressed: () => _controller?.toggleTorch(),
        ),
      ]),
      body: _loggedIn
          ? Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error, child) {
                    // 相机起不来时把真实原因显示出来并进日志，避免只有黑屏图标
                    final detail = error.errorDetails?.message ??
                        error.errorCode.name;
                    AppLogger.e('扫码相机启动失败: $detail');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.no_photography_outlined,
                                size: 48, color: Colors.orange),
                            const SizedBox(height: 12),
                            const Text('相机启动失败',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            const SizedBox(height: 8),
                            Text(detail,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white70)),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () => _controller?.start(),
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_processing)
                  const Center(child: CircularProgressIndicator()),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 80,
                  child: Text(
                    '扫描 EasyServer Web 面板上的二维码，授权该浏览器登录',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14),
                  ),
                ),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 56, color: Colors.orange.shade700),
                    const SizedBox(height: 16),
                    const Text('扫码授权需要先登录本机',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text(
                      '此功能用于把本机已登录的账号授权给 Web 面板登录。'
                      '请先返回登录本机，再回来扫码。',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('去登录'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
