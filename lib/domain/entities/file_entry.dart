import 'package:freezed_annotation/freezed_annotation.dart';
part 'file_entry.freezed.dart';
part 'file_entry.g.dart';

@freezed
class FileEntry with _$FileEntry {
  const factory FileEntry({
    required String name,
    required String path,
    @JsonKey(name: 'is_dir') required bool isDir,
    @JsonKey(name: 'size_bytes') required int sizeBytes,
    required String mode,
    @JsonKey(name: 'modified_at') required String modifiedAt,
    @JsonKey(name: 'is_symlink') @Default(false) bool isSymlink,
  }) = _FileEntry;

  factory FileEntry.fromJson(Map<String, dynamic> json) => _$FileEntryFromJson(json);
}
