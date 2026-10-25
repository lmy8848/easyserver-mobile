import '../entities/file_entry.dart';

abstract class FileRepository {
  Future<FileListResult> list(String path);
  Future<void> mkdir(String path);
  Future<void> upload(String path, String localFilePath);
  Future<void> download(String path, String savePath);
  Future<void> rename(String oldPath, String newPath);
  Future<void> delete(String path, {bool recursive = false});
  Future<void> move(List<String> paths, String dest);
  Future<void> copy(String source, String dest);
  Future<String> getContent(String path);
  Future<void> saveContent(String path, String content);
  Future<List<FileSearchResult>> search(String path, String query,
      {int? limit});
  Future<void> compress(List<String> sources, String dest);
  Future<void> extract(String source, String dest);
  Future<void> chmod(String path, String mode);
  Future<void> chown(String path, int uid, int gid);
}

class FileListResult {
  final String path;
  final String? parent;
  final List<FileEntry> entries;
  FileListResult({required this.path, this.parent, required this.entries});
}

class FileSearchResult {
  final String path;
  final String name;
  final bool isDir;
  final int size;
  final String? match;
  FileSearchResult(
      {required this.path,
      required this.name,
      required this.isDir,
      required this.size,
      this.match});
}
