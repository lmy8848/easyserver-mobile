/// 防火墙规则表单校验。与后端语义一致：端口留空表示全部端口，
/// 单端口 1-65535，范围 a-b（a <= b）。
String? validateFirewallPort(String? v) {
  final s = v?.trim() ?? '';
  if (s.isEmpty) return null; // 留空 = 全部端口
  if (s.contains('-')) {
    final parts = s.split('-');
    if (parts.length != 2) return '格式应为 8000-9000';
    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    if (a == null || b == null || a < 1 || b > 65535 || a > b) {
      return '端口范围无效（1-65535，起始不能大于结束）';
    }
    return null;
  }
  final p = int.tryParse(s);
  if (p == null || p < 1 || p > 65535) return '端口无效（1-65535）';
  return null;
}

/// 来源 IP/CIDR 校验，留空 = 任意来源。IPv4 粗校验点分十进制，
/// IPv6 粗校验十六进制与冒号组成；CIDR 最多一个 `/`，前缀长度 0-32（v4）
/// 或 0-128（v6）。后端提交时仍会做权威校验。
String? validateFirewallSource(String? v) {
  final s = v?.trim() ?? '';
  if (s.isEmpty) return null;
  final parts = s.split('/');
  if (parts.length > 2) return 'IP 或 CIDR 格式无效';
  final ip = parts[0];
  final v4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');
  final v6 = RegExp(r'^[0-9a-fA-F:]+$');
  final isV4 = v4.hasMatch(ip);
  if (!isV4 && !v6.hasMatch(ip)) return 'IP 或 CIDR 格式无效';
  if (parts.length == 2) {
    final prefix = int.tryParse(parts[1]);
    final max = isV4 ? 32 : 128;
    if (prefix == null || prefix < 0 || prefix > max) {
      return 'IP 或 CIDR 格式无效';
    }
  }
  return null;
}
