import '../../domain/entities/file_share.dart';
import '../../domain/repositories/share_repository.dart';
import '../datasources/remote/api_client.dart';

class ShareRepositoryImpl implements ShareRepository {
  final ApiClient _api;

  ShareRepositoryImpl(this._api);

  @override
  Future<List<FileShare>> list() async {
    // 后端分页默认 20 上限 100，一次取满
    final data = await _api
        .get('/shares', queryParameters: {'page': 1, 'page_size': 100});
    final items = (data['items'] ?? data['_items']) as List<dynamic>? ?? [];
    return items
        .map((e) => FileShare.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FileShare> create(CreateShareInput input) async {
    final json = await _api.post('/shares', data: input.toJson());
    return FileShare.fromJson(json);
  }

  @override
  Future<void> delete(int id) async {
    await _api.delete('/shares/$id');
  }

  @override
  Future<int> cleanup() async {
    final json = await _api.post('/shares/cleanup');
    final n = json['deleted'] ?? json['count'] ?? json['cleaned'];
    return n is int ? n : 0;
  }

  @override
  String downloadUrl(String baseUrl, String token) =>
      '$baseUrl/api/shares/public/$token/download';
}
