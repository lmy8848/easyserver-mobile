// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FileEntry _$FileEntryFromJson(Map<String, dynamic> json) {
  return _FileEntry.fromJson(json);
}

/// @nodoc
mixin _$FileEntry {
  String get name => throw _privateConstructorUsedError;
  String get path => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_dir')
  bool get isDir => throw _privateConstructorUsedError;
  @JsonKey(name: 'size_bytes')
  int get sizeBytes => throw _privateConstructorUsedError;
  String get mode => throw _privateConstructorUsedError;
  @JsonKey(name: 'modified_at')
  String get modifiedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_symlink')
  bool get isSymlink => throw _privateConstructorUsedError;

  /// Serializes this FileEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FileEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FileEntryCopyWith<FileEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FileEntryCopyWith<$Res> {
  factory $FileEntryCopyWith(FileEntry value, $Res Function(FileEntry) then) =
      _$FileEntryCopyWithImpl<$Res, FileEntry>;
  @useResult
  $Res call(
      {String name,
      String path,
      @JsonKey(name: 'is_dir') bool isDir,
      @JsonKey(name: 'size_bytes') int sizeBytes,
      String mode,
      @JsonKey(name: 'modified_at') String modifiedAt,
      @JsonKey(name: 'is_symlink') bool isSymlink});
}

/// @nodoc
class _$FileEntryCopyWithImpl<$Res, $Val extends FileEntry>
    implements $FileEntryCopyWith<$Res> {
  _$FileEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FileEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? path = null,
    Object? isDir = null,
    Object? sizeBytes = null,
    Object? mode = null,
    Object? modifiedAt = null,
    Object? isSymlink = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      isDir: null == isDir
          ? _value.isDir
          : isDir // ignore: cast_nullable_to_non_nullable
              as bool,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String,
      modifiedAt: null == modifiedAt
          ? _value.modifiedAt
          : modifiedAt // ignore: cast_nullable_to_non_nullable
              as String,
      isSymlink: null == isSymlink
          ? _value.isSymlink
          : isSymlink // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FileEntryImplCopyWith<$Res>
    implements $FileEntryCopyWith<$Res> {
  factory _$$FileEntryImplCopyWith(
          _$FileEntryImpl value, $Res Function(_$FileEntryImpl) then) =
      __$$FileEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String path,
      @JsonKey(name: 'is_dir') bool isDir,
      @JsonKey(name: 'size_bytes') int sizeBytes,
      String mode,
      @JsonKey(name: 'modified_at') String modifiedAt,
      @JsonKey(name: 'is_symlink') bool isSymlink});
}

/// @nodoc
class __$$FileEntryImplCopyWithImpl<$Res>
    extends _$FileEntryCopyWithImpl<$Res, _$FileEntryImpl>
    implements _$$FileEntryImplCopyWith<$Res> {
  __$$FileEntryImplCopyWithImpl(
      _$FileEntryImpl _value, $Res Function(_$FileEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of FileEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? path = null,
    Object? isDir = null,
    Object? sizeBytes = null,
    Object? mode = null,
    Object? modifiedAt = null,
    Object? isSymlink = null,
  }) {
    return _then(_$FileEntryImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      isDir: null == isDir
          ? _value.isDir
          : isDir // ignore: cast_nullable_to_non_nullable
              as bool,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String,
      modifiedAt: null == modifiedAt
          ? _value.modifiedAt
          : modifiedAt // ignore: cast_nullable_to_non_nullable
              as String,
      isSymlink: null == isSymlink
          ? _value.isSymlink
          : isSymlink // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FileEntryImpl implements _FileEntry {
  const _$FileEntryImpl(
      {required this.name,
      required this.path,
      @JsonKey(name: 'is_dir') required this.isDir,
      @JsonKey(name: 'size_bytes') required this.sizeBytes,
      required this.mode,
      @JsonKey(name: 'modified_at') required this.modifiedAt,
      @JsonKey(name: 'is_symlink') this.isSymlink = false});

  factory _$FileEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$FileEntryImplFromJson(json);

  @override
  final String name;
  @override
  final String path;
  @override
  @JsonKey(name: 'is_dir')
  final bool isDir;
  @override
  @JsonKey(name: 'size_bytes')
  final int sizeBytes;
  @override
  final String mode;
  @override
  @JsonKey(name: 'modified_at')
  final String modifiedAt;
  @override
  @JsonKey(name: 'is_symlink')
  final bool isSymlink;

  @override
  String toString() {
    return 'FileEntry(name: $name, path: $path, isDir: $isDir, sizeBytes: $sizeBytes, mode: $mode, modifiedAt: $modifiedAt, isSymlink: $isSymlink)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileEntryImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.isDir, isDir) || other.isDir == isDir) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.modifiedAt, modifiedAt) ||
                other.modifiedAt == modifiedAt) &&
            (identical(other.isSymlink, isSymlink) ||
                other.isSymlink == isSymlink));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, path, isDir, sizeBytes, mode, modifiedAt, isSymlink);

  /// Create a copy of FileEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FileEntryImplCopyWith<_$FileEntryImpl> get copyWith =>
      __$$FileEntryImplCopyWithImpl<_$FileEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FileEntryImplToJson(
      this,
    );
  }
}

abstract class _FileEntry implements FileEntry {
  const factory _FileEntry(
      {required final String name,
      required final String path,
      @JsonKey(name: 'is_dir') required final bool isDir,
      @JsonKey(name: 'size_bytes') required final int sizeBytes,
      required final String mode,
      @JsonKey(name: 'modified_at') required final String modifiedAt,
      @JsonKey(name: 'is_symlink') final bool isSymlink}) = _$FileEntryImpl;

  factory _FileEntry.fromJson(Map<String, dynamic> json) =
      _$FileEntryImpl.fromJson;

  @override
  String get name;
  @override
  String get path;
  @override
  @JsonKey(name: 'is_dir')
  bool get isDir;
  @override
  @JsonKey(name: 'size_bytes')
  int get sizeBytes;
  @override
  String get mode;
  @override
  @JsonKey(name: 'modified_at')
  String get modifiedAt;
  @override
  @JsonKey(name: 'is_symlink')
  bool get isSymlink;

  /// Create a copy of FileEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FileEntryImplCopyWith<_$FileEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
