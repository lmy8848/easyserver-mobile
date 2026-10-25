import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../di/providers.dart';

class QRLoginScreen extends ConsumerStatefulWidget {
  const QRLoginScreen({super.key});
  @override
  ConsumerState<QRLoginScreen> createState() => _QRLoginScreenState();
}

class _QRLoginScreenState extends ConsumerState<QRLoginScreen> {
  MobileScannerController? _controller;
  bool _processing = false;

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
          const SnackBar(content: Text('扫码登录授权成功'), backgroundColor: Colors.green),
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
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_processing)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Text(
              '扫描 EasyServer Web 面板上的二维码',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
