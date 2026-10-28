import 'package:easyserver_mobile/core/action_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActionGuard', () {
    test('同 key 在途时 tryBegin 返回 false', () {
      final guard = ActionGuard();
      expect(guard.tryBegin('a'), isTrue);
      expect(guard.tryBegin('a'), isFalse); // 在途，拦截
      expect(guard.tryBegin('b'), isTrue); // 不同 key 互不影响
    });

    test('end 释放后可重新进入', () {
      final guard = ActionGuard();
      guard.tryBegin('a');
      guard.end('a');
      expect(guard.tryBegin('a'), isTrue);
    });

    test('run 在途时静默跳过并返回 null', () async {
      final guard = ActionGuard();
      var calls = 0;
      final first = guard.run('k', () async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      final second = await guard.run('k', () async {
        calls++;
      });
      expect(second, isNull); // 被拦截
      await first;
      expect(calls, 1); // 只执行了一次
    });

    test('run 完成后释放，异常也会释放', () async {
      final guard = ActionGuard();
      await guard.run('k', () async {});
      expect(guard.isInFlight('k'), isFalse);

      try {
        await guard.run<Object?>('k', () async => throw Exception('boom'));
      } catch (_) {}
      expect(guard.isInFlight('k'), isFalse); // 异常路径也释放
    });

    test('run 返回 action 的结果', () async {
      final guard = ActionGuard();
      final v = await guard.run<String>('k', () async => 'ok');
      expect(v, 'ok');
    });
  });
}
