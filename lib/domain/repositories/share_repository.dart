import '../entities/file_share.dart';

abstract class ShareRepository {
  /// 当前用户的外链列表（含文件现状：存在/大小/是否目录）
  Future<List<FileShare>> list();

  /// 创建外链，返回含 token 的完整记录
  Future<FileShare> create(CreateShareInput input);

  Future<void> delete(int id);

  /// 清理已过期的外链，返回清理条数
  Future<int> cleanup();

  /// 拼接公开下载链接：{baseUrl}/api/shares/public/{token}/download
  String downloadUrl(String baseUrl, String token);
}
