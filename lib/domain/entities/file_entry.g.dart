// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FileEntryImpl _$$FileEntryImplFromJson(Map<String, dynamic> json) =>
    _$FileEntryImpl(
      name: json['name'] as String,
      path: json['path'] as String,
      isDir: json['is_dir'] as bool,
      sizeBytes: (json['size_bytes'] as num).toInt(),
      mode: json['mode'] as String,
      modifiedAt: json['modified_at'] as String,
      isSymlink: json['is_symlink'] as bool? ?? false,
    );

Map<String, dynamic> _$$FileEntryImplToJson(_$FileEntryImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'is_dir': instance.isDir,
      'size_bytes': instance.sizeBytes,
      'mode': instance.mode,
      'modified_at': instance.modifiedAt,
      'is_symlink': instance.isSymlink,
    };
