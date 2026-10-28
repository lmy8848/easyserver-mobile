import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_share.freezed.dart';
part 'file_share.g.dart';

/// 文件外链（后端 filemanager.ShareListItem = FileShare + 文件现状）
@freezed
class FileShare with _$FileShare {
  const factory FileShare({
    @Default(0) int id,
    @JsonKey(name: 'file_path') @Default('') String filePath,
    @JsonKey(name: 'file_name') @Default('') String fileName,
    @JsonKey(name: 'file_size') @Default(0) int fileSize,
    @Default('') String token,
    @JsonKey(name: 'expires_at') @Default('') String expiresAt,
    @JsonKey(name: 'max_downloads') @Default(0) int maxDownloads,
    @JsonKey(name: 'download_count') @Default(0) int downloadCount,
    @JsonKey(name: 'created_at') @Default('') String createdAt,
    @JsonKey(name: 'file_exists') @Default(true) bool fileExists,
    @JsonKey(name: 'is_dir') @Default(false) bool isDir,
    @JsonKey(name: 'current_size') @Default(0) int currentSize,
    @JsonKey(name: 'has_password') @Default(false) bool hasPassword,
  }) = _FileShare;

  factory FileShare.fromJson(Map<String, dynamic> json) =>
      _$FileShareFromJson(json);
}

/// 创建外链请求。expiresAt 支持相对值（30m/1h/7d）或
/// YYYY-MM-DD HH:MM:SS，空 = 永久有效；maxDownloads 0 = 不限次数。
class CreateShareInput {
  final String filePath;
  final String password;
  final String expiresAt;
  final int maxDownloads;

  const CreateShareInput({
    required this.filePath,
    this.password = '',
    this.expiresAt = '',
    this.maxDownloads = 0,
  });

  Map<String, dynamic> toJson() => {
        'file_path': filePath,
        'password': password,
        'expires_at': expiresAt,
        'max_downloads': maxDownloads,
      };
}
