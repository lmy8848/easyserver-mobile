/// 按 key 互斥的操作守卫：同一 key 在途时忽略后续触发。
///
/// 解决「连点按钮发出多次请求」：写操作统一经 [run] 执行，
/// 同 key 请求在途时后续调用直接被跳过（返回 null），不发请求。
class ActionGuard {
  final Set<String> _inFlight = {};

  bool isInFlight(String key) => _inFlight.contains(key);

  /// 尝试占用 key：未被占用则占用并返回 true，已在途返回 false。
  bool tryBegin(String key) => _inFlight.add(key);

  void end(String key) => _inFlight.remove(key);

  /// 在途时静默跳过并返回 null；否则执行 action 并在完成后释放。
  Future<T?>? run<T>(String key, Future<T> Function() action) async {
    if (!_inFlight.add(key)) return null;
    try {
      return await action();
    } finally {
      _inFlight.remove(key);
    }
  }
}

/// 全局共享实例：各领域的写操作守卫共用一把锁集合，
/// key 按领域前缀区分（如 'cron:enable:name'、'web:restart:1'）。
final globalActionGuard = ActionGuard();
