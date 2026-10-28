import 'package:easyserver_mobile/domain/entities/file_share.dart';
import 'package:easyserver_mobile/domain/entities/web_server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileShare', () {
    test('JSON 解析（ShareListItem 全字段）', () {
      final s = FileShare.fromJson({
        'id': 3,
        'file_path': '/opt/www/demo.zip',
        'file_name': 'demo.zip',
        'file_size': 1048576,
        'token': 'abc123',
        'expires_at': '2026-11-01 00:00:00',
        'max_downloads': 10,
        'download_count': 2,
        'created_at': '2026-10-29 10:00:00',
        'file_exists': false,
        'is_dir': false,
        'current_size': 1048576,
        'has_password': true,
      });
      expect(s.fileName, 'demo.zip');
      expect(s.token, 'abc123');
      expect(s.hasPassword, isTrue);
      expect(s.fileExists, isFalse);
      expect(s.maxDownloads, 10);
      expect(s.downloadCount, 2);
    });

    test('缺省字段回退默认值', () {
      final s = FileShare.fromJson({'id': 1, 'token': 't'});
      expect(s.hasPassword, isFalse);
      expect(s.expiresAt, '');
      expect(s.fileExists, isTrue);
      expect(s.isDir, isFalse);
    });
  });

  group('CreateShareInput', () {
    test('toJson 字段映射', () {
      final json = const CreateShareInput(
        filePath: '/opt/a.zip',
        password: 'pw',
        expiresAt: '7d',
        maxDownloads: 5,
      ).toJson();
      expect(json['file_path'], '/opt/a.zip');
      expect(json['expires_at'], '7d');
      expect(json['max_downloads'], 5);
      expect(json['password'], 'pw');
    });
  });

  group('WebServer / Website', () {
    test('服务器 JSON 解析', () {
      final s = WebServer.fromJson({
        'id': 1,
        'name': 'nginx',
        'display_name': 'Nginx',
        'status': 'running',
        'version': '1.24.0',
        'memory_bytes': 5242880,
        'auto_start': true,
        'config_ok': true,
      });
      expect(s.displayName, 'Nginx');
      expect(s.status, 'running');
      expect(s.memoryBytes, 5242880);
      expect(s.autoStart, isTrue);
    });

    test('网站 JSON 解析与新建请求', () {
      final w = Website.fromJson({
        'id': 2,
        'web_server_id': 1,
        'name': 'demo',
        'domain': 'demo.example.com',
        'root_path': '/opt/www/demo',
        'port': 80,
        'project_type': 'proxy',
        'proxy_enabled': true,
        'proxy_pass': 'http://127.0.0.1:3000',
        'ssl_enabled': true,
        'status': 'active',
      });
      expect(w.domain, 'demo.example.com');
      expect(w.projectType, 'proxy');
      expect(w.sslEnabled, isTrue);

      final input = const CreateWebsiteInput(
        name: 'demo',
        domain: 'demo.example.com',
        rootPath: '/opt/www/demo',
        projectType: 'nodejs',
        appPort: 3000,
      ).toJson();
      expect(input['root_path'], '/opt/www/demo');
      expect(input['app_port'], 3000);
      expect(input['project_type'], 'nodejs');
    });
  });
}
