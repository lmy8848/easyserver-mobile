// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_share.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FileShare _$FileShareFromJson(Map<String, dynamic> json) {
  return _FileShare.fromJson(json);
}

/// @nodoc
mixin _$FileShare {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_path')
  String get filePath => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_name')
  String get fileName => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_size')
  int get fileSize => throw _privateConstructorUsedError;
  String get token => throw _privateConstructorUsedError;
  @JsonKey(name: 'expires_at')
  String get expiresAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_downloads')
  int get maxDownloads => throw _privateConstructorUsedError;
  @JsonKey(name: 'download_count')
  int get downloadCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_exists')
  bool get fileExists => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_dir')
  bool get isDir => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_size')
  int get currentSize => throw _privateConstructorUsedError;
  @JsonKey(name: 'has_password')
  bool get hasPassword => throw _privateConstructorUsedError;

  /// Serializes this FileShare to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FileShare
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FileShareCopyWith<FileShare> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FileShareCopyWith<$Res> {
  factory $FileShareCopyWith(FileShare value, $Res Function(FileShare) then) =
      _$FileShareCopyWithImpl<$Res, FileShare>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'file_path') String filePath,
      @JsonKey(name: 'file_name') String fileName,
      @JsonKey(name: 'file_size') int fileSize,
      String token,
      @JsonKey(name: 'expires_at') String expiresAt,
      @JsonKey(name: 'max_downloads') int maxDownloads,
      @JsonKey(name: 'download_count') int downloadCount,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'file_exists') bool fileExists,
      @JsonKey(name: 'is_dir') bool isDir,
      @JsonKey(name: 'current_size') int currentSize,
      @JsonKey(name: 'has_password') bool hasPassword});
}

/// @nodoc
class _$FileShareCopyWithImpl<$Res, $Val extends FileShare>
    implements $FileShareCopyWith<$Res> {
  _$FileShareCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FileShare
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? filePath = null,
    Object? fileName = null,
    Object? fileSize = null,
    Object? token = null,
    Object? expiresAt = null,
    Object? maxDownloads = null,
    Object? downloadCount = null,
    Object? createdAt = null,
    Object? fileExists = null,
    Object? isDir = null,
    Object? currentSize = null,
    Object? hasPassword = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as String,
      maxDownloads: null == maxDownloads
          ? _value.maxDownloads
          : maxDownloads // ignore: cast_nullable_to_non_nullable
              as int,
      downloadCount: null == downloadCount
          ? _value.downloadCount
          : downloadCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      fileExists: null == fileExists
          ? _value.fileExists
          : fileExists // ignore: cast_nullable_to_non_nullable
              as bool,
      isDir: null == isDir
          ? _value.isDir
          : isDir // ignore: cast_nullable_to_non_nullable
              as bool,
      currentSize: null == currentSize
          ? _value.currentSize
          : currentSize // ignore: cast_nullable_to_non_nullable
              as int,
      hasPassword: null == hasPassword
          ? _value.hasPassword
          : hasPassword // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FileShareImplCopyWith<$Res>
    implements $FileShareCopyWith<$Res> {
  factory _$$FileShareImplCopyWith(
          _$FileShareImpl value, $Res Function(_$FileShareImpl) then) =
      __$$FileShareImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'file_path') String filePath,
      @JsonKey(name: 'file_name') String fileName,
      @JsonKey(name: 'file_size') int fileSize,
      String token,
      @JsonKey(name: 'expires_at') String expiresAt,
      @JsonKey(name: 'max_downloads') int maxDownloads,
      @JsonKey(name: 'download_count') int downloadCount,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'file_exists') bool fileExists,
      @JsonKey(name: 'is_dir') bool isDir,
      @JsonKey(name: 'current_size') int currentSize,
      @JsonKey(name: 'has_password') bool hasPassword});
}

/// @nodoc
class __$$FileShareImplCopyWithImpl<$Res>
    extends _$FileShareCopyWithImpl<$Res, _$FileShareImpl>
    implements _$$FileShareImplCopyWith<$Res> {
  __$$FileShareImplCopyWithImpl(
      _$FileShareImpl _value, $Res Function(_$FileShareImpl) _then)
      : super(_value, _then);

  /// Create a copy of FileShare
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? filePath = null,
    Object? fileName = null,
    Object? fileSize = null,
    Object? token = null,
    Object? expiresAt = null,
    Object? maxDownloads = null,
    Object? downloadCount = null,
    Object? createdAt = null,
    Object? fileExists = null,
    Object? isDir = null,
    Object? currentSize = null,
    Object? hasPassword = null,
  }) {
    return _then(_$FileShareImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as String,
      maxDownloads: null == maxDownloads
          ? _value.maxDownloads
          : maxDownloads // ignore: cast_nullable_to_non_nullable
              as int,
      downloadCount: null == downloadCount
          ? _value.downloadCount
          : downloadCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      fileExists: null == fileExists
          ? _value.fileExists
          : fileExists // ignore: cast_nullable_to_non_nullable
              as bool,
      isDir: null == isDir
          ? _value.isDir
          : isDir // ignore: cast_nullable_to_non_nullable
              as bool,
      currentSize: null == currentSize
          ? _value.currentSize
          : currentSize // ignore: cast_nullable_to_non_nullable
              as int,
      hasPassword: null == hasPassword
          ? _value.hasPassword
          : hasPassword // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FileShareImpl implements _FileShare {
  const _$FileShareImpl(
      {this.id = 0,
      @JsonKey(name: 'file_path') this.filePath = '',
      @JsonKey(name: 'file_name') this.fileName = '',
      @JsonKey(name: 'file_size') this.fileSize = 0,
      this.token = '',
      @JsonKey(name: 'expires_at') this.expiresAt = '',
      @JsonKey(name: 'max_downloads') this.maxDownloads = 0,
      @JsonKey(name: 'download_count') this.downloadCount = 0,
      @JsonKey(name: 'created_at') this.createdAt = '',
      @JsonKey(name: 'file_exists') this.fileExists = true,
      @JsonKey(name: 'is_dir') this.isDir = false,
      @JsonKey(name: 'current_size') this.currentSize = 0,
      @JsonKey(name: 'has_password') this.hasPassword = false});

  factory _$FileShareImpl.fromJson(Map<String, dynamic> json) =>
      _$$FileShareImplFromJson(json);

  @override
  @JsonKey()
  final int id;
  @override
  @JsonKey(name: 'file_path')
  final String filePath;
  @override
  @JsonKey(name: 'file_name')
  final String fileName;
  @override
  @JsonKey(name: 'file_size')
  final int fileSize;
  @override
  @JsonKey()
  final String token;
  @override
  @JsonKey(name: 'expires_at')
  final String expiresAt;
  @override
  @JsonKey(name: 'max_downloads')
  final int maxDownloads;
  @override
  @JsonKey(name: 'download_count')
  final int downloadCount;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  @JsonKey(name: 'file_exists')
  final bool fileExists;
  @override
  @JsonKey(name: 'is_dir')
  final bool isDir;
  @override
  @JsonKey(name: 'current_size')
  final int currentSize;
  @override
  @JsonKey(name: 'has_password')
  final bool hasPassword;

  @override
  String toString() {
    return 'FileShare(id: $id, filePath: $filePath, fileName: $fileName, fileSize: $fileSize, token: $token, expiresAt: $expiresAt, maxDownloads: $maxDownloads, downloadCount: $downloadCount, createdAt: $createdAt, fileExists: $fileExists, isDir: $isDir, currentSize: $currentSize, hasPassword: $hasPassword)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileShareImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.maxDownloads, maxDownloads) ||
                other.maxDownloads == maxDownloads) &&
            (identical(other.downloadCount, downloadCount) ||
                other.downloadCount == downloadCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.fileExists, fileExists) ||
                other.fileExists == fileExists) &&
            (identical(other.isDir, isDir) || other.isDir == isDir) &&
            (identical(other.currentSize, currentSize) ||
                other.currentSize == currentSize) &&
            (identical(other.hasPassword, hasPassword) ||
                other.hasPassword == hasPassword));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      filePath,
      fileName,
      fileSize,
      token,
      expiresAt,
      maxDownloads,
      downloadCount,
      createdAt,
      fileExists,
      isDir,
      currentSize,
      hasPassword);

  /// Create a copy of FileShare
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FileShareImplCopyWith<_$FileShareImpl> get copyWith =>
      __$$FileShareImplCopyWithImpl<_$FileShareImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FileShareImplToJson(
      this,
    );
  }
}

abstract class _FileShare implements FileShare {
  const factory _FileShare(
      {final int id,
      @JsonKey(name: 'file_path') final String filePath,
      @JsonKey(name: 'file_name') final String fileName,
      @JsonKey(name: 'file_size') final int fileSize,
      final String token,
      @JsonKey(name: 'expires_at') final String expiresAt,
      @JsonKey(name: 'max_downloads') final int maxDownloads,
      @JsonKey(name: 'download_count') final int downloadCount,
      @JsonKey(name: 'created_at') final String createdAt,
      @JsonKey(name: 'file_exists') final bool fileExists,
      @JsonKey(name: 'is_dir') final bool isDir,
      @JsonKey(name: 'current_size') final int currentSize,
      @JsonKey(name: 'has_password') final bool hasPassword}) = _$FileShareImpl;

  factory _FileShare.fromJson(Map<String, dynamic> json) =
      _$FileShareImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'file_path')
  String get filePath;
  @override
  @JsonKey(name: 'file_name')
  String get fileName;
  @override
  @JsonKey(name: 'file_size')
  int get fileSize;
  @override
  String get token;
  @override
  @JsonKey(name: 'expires_at')
  String get expiresAt;
  @override
  @JsonKey(name: 'max_downloads')
  int get maxDownloads;
  @override
  @JsonKey(name: 'download_count')
  int get downloadCount;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  @JsonKey(name: 'file_exists')
  bool get fileExists;
  @override
  @JsonKey(name: 'is_dir')
  bool get isDir;
  @override
  @JsonKey(name: 'current_size')
  int get currentSize;
  @override
  @JsonKey(name: 'has_password')
  bool get hasPassword;

  /// Create a copy of FileShare
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FileShareImplCopyWith<_$FileShareImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
