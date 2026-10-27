/// systemd OnCalendar 表达式的人类可读说明。
/// 只覆盖常见形态，认不出来就原样展示——后端用 systemd-analyze 校验，
/// 手写表达式可能是任意合法语法，前端不猜。
String scheduleText(String expr) {
  final s = expr.trim();
  if (s.isEmpty) return '未设置';
  switch (s) {
    case 'hourly':
      return '每小时';
    case 'daily':
      return '每天';
    case 'weekly':
      return '每周';
    case 'monthly':
      return '每月';
    case 'yearly':
    case 'annually':
      return '每年';
  }

  final everyMinute = RegExp(r'^\*-\*-\* \*:\*:00$');
  if (everyMinute.hasMatch(s)) return '每分钟';

  // *-*-* HH:MM:SS → 每天 HH:MM
  final daily = RegExp(r'^\*-\*-\* (\d{2}):(\d{2}):\d{2}$').firstMatch(s);
  if (daily != null) return '每天 ${daily[1]}:${daily[2]}';

  // Mon *-*-* HH:MM:SS → 每周一 HH:MM
  const weekdays = {
    'Mon': '一',
    'Tue': '二',
    'Wed': '三',
    'Thu': '四',
    'Fri': '五',
    'Sat': '六',
    'Sun': '日',
  };
  final weekly =
      RegExp(r'^(Mon|Tue|Wed|Thu|Fri|Sat|Sun) \*-\*-\* (\d{2}):(\d{2}):\d{2}$')
          .firstMatch(s);
  if (weekly != null) {
    return '每周${weekdays[weekly[1]] ?? ''} ${weekly[2]}:${weekly[3]}';
  }

  // *-*-DD HH:MM:SS → 每月 DD 日 HH:MM
  final monthly =
      RegExp(r'^\*-\*-(\d{2}) (\d{2}):(\d{2}):\d{2}$').firstMatch(s);
  if (monthly != null) {
    return '每月 ${int.parse(monthly[1]!)} 日 ${monthly[2]}:${monthly[3]}';
  }

  return s;
}

/// 执行状态 → 中文
String runStatusText(String status) {
  switch (status.toLowerCase()) {
    case 'success':
      return '成功';
    case 'failed':
      return '失败';
    case 'running':
      return '运行中';
    default:
      return status.isEmpty ? '未知' : status;
  }
}

/// 后端返回的 systemd 时间（如 "Mon 2026-10-27 02:00:00 CST"）过长，去掉星期前缀
String shortTime(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return '—';
  const prefixes = ['Mon ', 'Tue ', 'Wed ', 'Thu ', 'Fri ', 'Sat ', 'Sun '];
  for (final p in prefixes) {
    if (s.startsWith(p)) return s.substring(p.length);
  }
  return s;
}
