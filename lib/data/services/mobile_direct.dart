import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 移动端直连通道（绕过 Cloudflare）的客户端能力：
/// - 设备 Ed25519 密钥对：私钥只存安全存储，公钥用于在面板登记；
/// - 请求签名：METHOD\nURI\n时间戳\nnonce\nSHA256(body)；
/// - 证书指纹固定（TOFU）：没有域名时用「IP:端口」直连，首次核对指纹后固化。
class MobileDirect {
  MobileDirect._();
  static final MobileDirect instance = MobileDirect._();

  static const _keySeedKey = 'md_ed25519_seed';
  static const _fingerprintKey = 'md_cert_fingerprint';
  static const _directUrlKey = 'md_direct_url';
  static const _enabledKey = 'md_enabled';

  final _secure = const FlutterSecureStorage();
  final _algorithm = Ed25519();

  SimpleKeyPair? _cachedKeyPair;

  // --- 配置 ---

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> isEnabled() async => (await _prefs).getBool(_enabledKey) ?? false;

  Future<void> setEnabled(bool enabled) async {
    await (await _prefs).setBool(_enabledKey, enabled);
  }

  /// 直连地址，形如 `https://192.168.1.10:8443` 或 `https://1.2.3.4:8443`。
  Future<String?> directUrl() async => (await _prefs).getString(_directUrlKey);

  Future<void> setDirectUrl(String? url) async {
    final p = await _prefs;
    if (url == null || url.isEmpty) {
      await p.remove(_directUrlKey);
    } else {
      await p.setString(_directUrlKey, url);
    }
  }

  /// 证书指纹（SHA-256，冒号分隔十六进制）。为空表示尚未固定。
  Future<String?> fingerprint() async => (await _prefs).getString(_fingerprintKey);

  Future<void> setFingerprint(String? fp) async {
    final p = await _prefs;
    if (fp == null || fp.isEmpty) {
      await p.remove(_fingerprintKey);
    } else {
      await p.setString(_fingerprintKey, fp.toLowerCase());
    }
  }

  // --- 设备密钥 ---

  Future<SimpleKeyPair> _keyPair() async {
    if (_cachedKeyPair != null) return _cachedKeyPair!;
    final saved = await _secure.read(key: _keySeedKey);
    if (saved != null && saved.isNotEmpty) {
      final seed = base64Decode(saved);
      _cachedKeyPair = await _algorithm.newKeyPairFromSeed(seed);
    } else {
      final kp = await _algorithm.newKeyPair();
      final seed = await kp.extractPrivateKeyBytes();
      await _secure.write(key: _keySeedKey, value: base64Encode(seed));
      _cachedKeyPair = kp;
    }
    return _cachedKeyPair!;
  }

  /// 设备公钥（base64 标准编码的 32 字节 Ed25519 公钥），用于登记。
  Future<String> publicKeyBase64() async {
    final pub = await (await _keyPair()).extractPublicKey();
    return base64Encode(pub.bytes);
  }

  /// 生成本次请求的签名头。
  Future<Map<String, String>> signHeaders({
    required String method,
    required String uri, // 路径 + 查询串，如 /api/auth/me
    required String deviceId,
    Uint8List? body,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final nonce = _nonce();
    final bodyHash = crypto.sha256.convert(body ?? Uint8List(0)).toString();
    final canonical = '$method\n$uri\n$ts\n$nonce\n$bodyHash';
    final sig = await _algorithm.sign(
      utf8.encode(canonical),
      keyPair: await _keyPair(),
    );
    return {
      'X-Device-Id': deviceId,
      'X-Device-Timestamp': '$ts',
      'X-Device-Nonce': nonce,
      'X-Device-Signature': base64Encode(sig.bytes),
    };
  }

  String _nonce() {
    final rnd = List<int>.generate(12, (_) => Random().nextInt(256));
    return base64UrlEncode(rnd).replaceAll('=', '');
  }

  // --- 指纹固定 ---

  /// 构造按指纹校验服务端证书的客户端（同步，供 dio 适配器工厂使用）。
  /// [expected] 为存储的指纹；证书 DER 的 SHA-256 需与其一致，否则连接失败。
  HttpClient pinnedHttpClientFor(String expected) {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) {
      final der = cert.der;
      final fp = _formatFingerprint(crypto.sha256.convert(der).bytes);
      return fp.toLowerCase() == expected.toLowerCase();
    };
    return client;
  }

  String _formatFingerprint(List<int> bytes) => bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join(':');

  /// 计算服务端当前证书指纹（供首次连接时展示给用户核对）。
  Future<String?> fetchServerFingerprint(String url) async {
    final uri = Uri.parse(url);
    final port = uri.hasPort ? uri.port : 443;
    SecureSocket? sock;
    try {
      sock = await SecureSocket.connect(
        uri.host,
        port,
        onBadCertificate: (_) => true,
        timeout: const Duration(seconds: 10),
      );
      final cert = sock.peerCertificate;
      if (cert == null) return null;
      return _formatFingerprint(crypto.sha256.convert(cert.der).bytes);
    } catch (_) {
      return null;
    } finally {
      sock?.destroy();
    }
  }
}
