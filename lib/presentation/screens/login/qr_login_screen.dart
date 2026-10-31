import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _QRLoginScreenState extends ConsumerState<QRLoginScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  bool _processing = false;
  bool _loggedIn = false;
  bool _succeeded = false;

  /// 扫描线动画：往复扫过取景框，给"正在扫描"的持续反馈
  late final AnimationController _scanLine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

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
    _scanLine.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null || !raw.startsWith('esqr:')) return;

    _processing = true;
    HapticFeedback.mediumImpact(); // 识别到二维码的即时触觉反馈
    if (mounted) setState(() {});
    final token = raw.substring(5);
    _confirmQR(token);
  }

  Future<void> _confirmQR(String qrToken) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.confirmQrLogin(qrToken);
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() => _succeeded = true);
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (mounted) context.pop();
      }
    } catch (e) {
      _processing = false;
      if (mounted) {
        setState(() {}); // 恢复扫描线与提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('授权失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 取景框 + 四角括号 + 扫描线
  Widget _buildScanFrame() {
    return AnimatedBuilder(
      animation: _scanLine,
      builder: (context, _) {
        final size = MediaQuery.of(context).size;
        final frameSize = size.width * 0.72;
        final top = (size.height - frameSize) / 2 - 60;
        final lineY = top + frameSize * _scanLine.value;
        return Stack(
          children: [
            // 四角括号
            Positioned(
              left: (size.width - frameSize) / 2,
              top: top,
              child: SizedBox(
                width: frameSize,
                height: frameSize,
                child: CustomPaint(painter: _FrameCornerPainter()),
              ),
            ),
            // 扫描线（授权中停住淡出，成功态由对勾替代）
            if (!_processing)
              Positioned(
                left: (size.width - frameSize) / 2 + 12,
                width: frameSize - 24,
                top: lineY,
                child: Container(
                  height: 2.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.greenAccent.withValues(alpha: 0),
                      Colors.greenAccent,
                      Colors.greenAccent.withValues(alpha: 0),
                    ]),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.greenAccent.withValues(alpha: 0.6),
                          blurRadius: 8),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
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
                _buildScanFrame(),
                // 识别/授权中的状态提示
                if (_processing)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 120,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.greenAccent),
                            ),
                            SizedBox(width: 10),
                            Text('已识别，正在授权…',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                // 成功反馈：绿色对勾
                if (_succeeded)
                  Positioned(
                    left: (MediaQuery.of(context).size.width - 96) / 2,
                    top: MediaQuery.of(context).size.height / 2 - 110,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 56),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 80,
                  child: Text(
                    _processing
                        ? '已识别二维码，正在授权该浏览器登录'
                        : '对准 Web 面板上的二维码即可自动扫描',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
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

/// 扫描框四角括号
class _FrameCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const r = 12.0;

    final path = Path()
      ..moveTo(0, r)
      ..lineTo(0, 0)
      ..lineTo(r, 0)
      ..moveTo(size.width - r, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, r)
      ..moveTo(size.width, size.height - r)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width - r, size.height)
      ..moveTo(r, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height - r);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
