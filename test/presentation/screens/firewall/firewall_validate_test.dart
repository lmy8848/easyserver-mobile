import 'package:easyserver_mobile/presentation/screens/firewall/firewall_validate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateFirewallPort', () {
    test('留空表示全部端口', () {
      expect(validateFirewallPort(''), isNull);
      expect(validateFirewallPort(null), isNull);
      expect(validateFirewallPort('  '), isNull);
    });

    test('单端口合法范围 1-65535', () {
      expect(validateFirewallPort('80'), isNull);
      expect(validateFirewallPort('65535'), isNull);
      expect(validateFirewallPort('1'), isNull);
    });

    test('单端口非法', () {
      expect(validateFirewallPort('0'), isNotNull);
      expect(validateFirewallPort('65536'), isNotNull);
      expect(validateFirewallPort('abc'), isNotNull);
      expect(validateFirewallPort('80.1'), isNotNull);
    });

    test('范围端口 a-b', () {
      expect(validateFirewallPort('8000-9000'), isNull);
      expect(validateFirewallPort('1-65535'), isNull);
      expect(validateFirewallPort('80-80'), isNull);
    });

    test('范围端口非法', () {
      expect(validateFirewallPort('9000-8000'), isNotNull); // 起始大于结束
      expect(validateFirewallPort('0-100'), isNotNull);
      expect(validateFirewallPort('1-65536'), isNotNull);
      expect(validateFirewallPort('80-'), isNotNull);
      expect(validateFirewallPort('80-81-82'), isNotNull);
    });
  });

  group('validateFirewallSource', () {
    test('留空表示任意来源', () {
      expect(validateFirewallSource(''), isNull);
      expect(validateFirewallSource(null), isNull);
    });

    test('IPv4 与 CIDR', () {
      expect(validateFirewallSource('192.168.1.1'), isNull);
      expect(validateFirewallSource('192.168.1.0/24'), isNull);
      expect(validateFirewallSource('0.0.0.0/0'), isNull);
    });

    test('IPv6', () {
      expect(validateFirewallSource('::1'), isNull);
      expect(validateFirewallSource('fe80::1'), isNull);
      expect(validateFirewallSource('fe80::/10'), isNull);
    });

    test('非法来源', () {
      expect(validateFirewallSource('example.com'), isNotNull);
      expect(validateFirewallSource('192.168.1'), isNotNull);
      expect(validateFirewallSource('192.168.1.0/24/8'), isNotNull);
      expect(validateFirewallSource('hello world'), isNotNull);
    });
  });
}
