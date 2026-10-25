import 'package:dio/dio.dart';
import '../../domain/entities/file_entry.dart';
import '../../domain/repositories/file_repository.dart';
import '../datasources/remote/api_client.dart';

class FileRepositoryImpl implements FileRepository {
  final ApiClient _api;
  FileRepositoryImpl(this._api);

  @override
  Future<FileListResult> list(String path) async {
    final json = await _api.get('/files', queryParameters: {'path': path});
    final entries = (json['entries'] as List<dynamic>?)
            ?.map((e) => FileEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return FileListResult(
        path: json['path'] as String? ?? path,
        parent: json['parent'] as String?,
        entries: entries);
  }

  @override
  Future<void> mkdir(String path) async {
    await _api.post('/files/mkdir', data: {'path': path});
  }

  @override
  Future<void> upload(String path, String filePath) async {
    final formData = FormData.fromMap(
        {'file': await MultipartFile.fromFile(filePath), 'path': path});
    await _api.upload('/files/upload', formData);
  }

  @override
  Future<void> download(String path, String savePath) async {
    await _api
        .download('/files/download', savePath, queryParameters: {'path': path});
  }

  @override
  Future<void> rename(String oldPath, String newPath) async {
    await _api
        .put('/files/rename', data: {'old_path': oldPath, 'new_path': newPath});
  }

  @override
  Future<void> delete(String path, {bool recursive = false}) async {
    await _api.delete('/files',
        queryParameters: {'path': path, 'recursive': recursive});
  }

  @override
  Future<void> move(List<String> paths, String dest) async {
    await _api.post('/files/move', data: {'paths': paths, 'dest': dest});
  }

  @override
  Future<void> copy(String source, String dest) async {
    await _api.post('/files/copy', data: {'source': source, 'dest': dest});
  }

  @override
  Future<String> getContent(String path) async {
    final json =
        await _api.get('/files/content', queryParameters: {'path': path});
    return json['content'] as String? ?? '';
  }

  @override
  Future<void> saveContent(String path, String content) async {
    await _api.put('/files/content', data: {'path': path, 'content': content});
  }

  @override
  Future<List<FileSearchResult>> search(String path, String query,
      {int? limit}) async {
    final params = <String, dynamic>{'path': path, 'q': query};
    if (limit != null) params['limit'] = limit;
    final data = await _api.get('/files/search', queryParameters: params);
    return (data as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return FileSearchResult(
        path: m['path'] as String,
        name: m['name'] as String,
        isDir: m['is_dir'] as bool? ?? false,
        size: m['size'] as int? ?? 0,
        match: m['match'] as String?,
      );
    }).toList();
  }

  @override
  Future<void> compress(List<String> sources, String dest) async {
    await _api
        .post('/files/compress', data: {'sources': sources, 'dest': dest});
  }

  @override
  Future<void> extract(String source, String dest) async {
    await _api.post('/files/extract', data: {'source': source, 'dest': dest});
  }

  @override
  Future<void> chmod(String path, String mode) async {
    await _api.put('/files/chmod', data: {'path': path, 'mode': mode});
  }

  @override
  Future<void> chown(String path, int uid, int gid) async {
    await _api
        .put('/files/chown', data: {'path': path, 'uid': uid, 'gid': gid});
  }
}
