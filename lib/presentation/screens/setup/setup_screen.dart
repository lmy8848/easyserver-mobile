import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../di/providers.dart';
import '../../../domain/entities/server_config.dart';
import '../../../data/services/mobile_direct.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});
  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  bool _useTls = false;
  bool _isTesting = false;
  bool _directEnabled = false;
  final _directUrlController = TextEditingController();
  final _fingerprintController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefillFromSaved();
  }

  // 已保存过服务器地址时自动回填表单，更换服务器时无需重新输入
  Future<void> _prefillFromSaved() async {
    var config = ref.read(serverConfigProvider);
    if (config == null) {
      await ref.read(serverConfigProvider.notifier).loadConfig();
      config = ref.read(serverConfigProvider);
    }
    final md = MobileDirect.instance;
    final directEnabled = await md.isEnabled();
    final directUrl = await md.directUrl();
    final fingerprint = await md.fingerprint();
    if (config == null || !mounted) return;
    final host = config.host;
    final port = config.port;
    final useTls = config.useTls;
    setState(() {
      _hostController.text = host;
      if (port > 0) _portController.text = port.toString();
      _useTls = useTls;
      _directEnabled = directEnabled;
      _directUrlController.text = directUrl ?? '';
      _fingerprintController.text = fingerprint ?? '';
    });
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _directUrlController.dispose();
    _fingerprintController.dispose();
    super.dispose();
  }

  String _sanitizeHost(String input) {
    var h = input.trim();
    for (final prefix in ['https://', 'http://', 'HTTPS://', 'HTTP://']) {
      if (h.startsWith(prefix)) {
        h = h.substring(prefix.length);
        break;
      }
    }
    final slash = h.indexOf('/');
    if (slash > 0) h = h.substring(0, slash);
    return h;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isTesting = true);

    try {
      final config = ServerConfig(
        host: _sanitizeHost(_hostController.text),
        port: int.parse(_portController.text.trim()),
        useTls: _useTls,
      );
      await _checkReachable(config);
      await ref.read(serverConfigProvider.notifier).setConfig(config);
      final md = MobileDirect.instance;
      await md.setEnabled(_directEnabled);
      await md.setDirectUrl(_directUrlController.text.trim());
      await md.setFingerprint(_fingerprintController.text.trim());
      ref.read(apiClientProvider).updateBaseUrl(config.baseUrl);
      await applyDirectSettings(ref);

      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('连接失败: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  /// 连通性测试：/health 为根路径公开端点，任何 HTTP 响应都视为可达
  /// （连接拒绝/超时/DNS 失败才抛错），避免只存配置不测通的误导转圈。
  Future<void> _checkReachable(ServerConfig config) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      validateStatus: (_) => true,
    ));
    try {
      await dio.getUri<dynamic>(Uri.parse('${config.baseUrl}/health'));
    } on DioException catch (e) {
      throw Exception(
          '无法连接 ${config.baseUrl}（${e.type.name}），请检查地址与端口');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('配置服务器')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.dns, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('连接到 EasyServer',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('输入您的 EasyServer 面板地址',
                  textAlign: TextAlign.center,
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              const SizedBox(height: 32),
              SwitchListTile(
                title: const Text('启用 HTTPS'),
                subtitle: const Text('使用 wss/https 连接'),
                value: _useTls,
                onChanged: (v) => setState(() => _useTls = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hostController,
                decoration: InputDecoration(
                  labelText: '服务器地址',
                  hintText: _useTls ? 'example.com' : '192.168.1.100',
                  prefixIcon: const Icon(Icons.computer),
                ),
                keyboardType: TextInputType.url,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? '请输入服务器地址' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: '端口',
                  hintText: '8080',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '请输入端口';
                  final port = int.tryParse(v.trim());
                  if (port == null || port < 1 || port > 65535)
                    return '端口范围 1-65535';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('启用移动端直连'),
                subtitle: const Text('绕过 Cloudflare，直连服务器端口（可选）'),
                value: _directEnabled,
                onChanged: (v) => setState(() => _directEnabled = v),
              ),
              if (_directEnabled) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _directUrlController,
                  decoration: const InputDecoration(
                    labelText: '直连地址',
                    hintText: 'https://192.168.1.10:8443',
                    prefixIcon: Icon(Icons.bolt),
                  ),
                  keyboardType: TextInputType.url,
                  validator: (v) {
                    if (!_directEnabled) return null;
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return '请输入直连地址';
                    if (!t.startsWith('https://')) return '直连地址需以 https:// 开头';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fingerprintController,
                  decoration: InputDecoration(
                    labelText: '证书指纹（SHA-256）',
                    hintText: '首次连接时点「获取指纹」核对',
                    prefixIcon: const Icon(Icons.fingerprint),
                    suffixIcon: TextButton(
                      onPressed: () async {
                        final url = _directUrlController.text.trim();
                        if (!url.startsWith('https://')) return;
                        final fp =
                            await MobileDirect.instance.fetchServerFingerprint(url);
                        if (fp == null) return;
                        setState(() => _fingerprintController.text = fp);
                      },
                      child: const Text('获取指纹'),
                    ),
                  ),
                  validator: (v) {
                    if (!_directEnabled) return null;
                    if ((v ?? '').trim().isEmpty) return '请获取并核对证书指纹';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _isTesting ? null : _save,
                child: _isTesting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('连接服务器'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
