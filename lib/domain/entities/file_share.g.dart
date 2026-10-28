// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_share.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FileShareImpl _$$FileShareImplFromJson(Map<String, dynamic> json) =>
    _$FileShareImpl(
      id: (json['id'] as num?)?.toInt() ?? 0,
      filePath: json['file_path'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      token: json['token'] as String? ?? '',
      expiresAt: json['expires_at'] as String? ?? '',
      maxDownloads: (json['max_downloads'] as num?)?.toInt() ?? 0,
      downloadCount: (json['download_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      fileExists: json['file_exists'] as bool? ?? true,
      isDir: json['is_dir'] as bool? ?? false,
      currentSize: (json['current_size'] as num?)?.toInt() ?? 0,
      hasPassword: json['has_password'] as bool? ?? false,
    );

Map<String, dynamic> _$$FileShareImplToJson(_$FileShareImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'file_path': instance.filePath,
      'file_name': instance.fileName,
      'file_size': instance.fileSize,
      'token': instance.token,
      'expires_at': instance.expiresAt,
      'max_downloads': instance.maxDownloads,
      'download_count': instance.downloadCount,
      'created_at': instance.createdAt,
      'file_exists': instance.fileExists,
      'is_dir': instance.isDir,
      'current_size': instance.currentSize,
      'has_password': instance.hasPassword,
    };
