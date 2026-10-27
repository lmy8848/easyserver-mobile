import 'package:easyserver_mobile/presentation/screens/cron/cron_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('scheduleText', () {
    test('systemd 简写', () {
      expect(scheduleText('hourly'), '每小时');
      expect(scheduleText('daily'), '每天');
      expect(scheduleText('monthly'), '每月');
      expect(scheduleText('yearly'), '每年');
    });

    test('每分钟与每天', () {
      expect(scheduleText('*-*-* *:*:00'), '每分钟');
      expect(scheduleText('*-*-* 02:00:00'), '每天 02:00');
    });

    test('每周', () {
      expect(scheduleText('Mon *-*-* 03:00:00'), '每周一 03:00');
      expect(scheduleText('Sun *-*-* 23:30:00'), '每周日 23:30');
    });

    test('每月指定日', () {
      expect(scheduleText('*-*-01 04:00:00'), '每月 1 日 04:00');
    });

    test('无法识别的表达式原样返回', () {
      expect(scheduleText('Mon..Fri *-*-* 09:00'), 'Mon..Fri *-*-* 09:00');
      expect(scheduleText(''), '未设置');
    });
  });

  group('runStatusText', () {
    test('状态映射', () {
      expect(runStatusText('success'), '成功');
      expect(runStatusText('failed'), '失败');
      expect(runStatusText('RUNNING'), '运行中');
      expect(runStatusText(''), '未知');
    });
  });

  group('shortTime', () {
    test('去掉 systemd 星期前缀', () {
      expect(
          shortTime('Mon 2026-10-27 02:00:00 CST'), '2026-10-27 02:00:00 CST');
      expect(shortTime('2026-10-27 02:00:00'), '2026-10-27 02:00:00');
      expect(shortTime(''), '—');
    });
  });
}
