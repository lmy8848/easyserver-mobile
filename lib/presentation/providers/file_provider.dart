import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/file_repository.dart';
import '../../di/providers.dart';

final fileListProvider = StateNotifierProvider.family<FileListNotifier, FileListState, String>((ref, path) {
  return FileListNotifier(ref.read(fileRepositoryProvider), path);
});

class FileListState {
  final bool isLoading;
  final String? error;
  final FileListResult? result;
  final String currentPath;

  FileListState({this.isLoading = false, this.error, this.result, required this.currentPath});

  FileListState copyWith({bool? isLoading, String? error, FileListResult? result, String? currentPath}) {
    return FileListState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
      currentPath: currentPath ?? this.currentPath,
    );
  }
}

class FileListNotifier extends StateNotifier<FileListState> {
  final FileRepository _repo;
  FileListNotifier(this._repo, String path) : super(FileListState(currentPath: path));

  Future<void> load(String path) async {
    state = state.copyWith(isLoading: true, error: null, currentPath: path);
    try {
      final result = await _repo.list(path);
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> navigateTo(String path) async => await load(path);
  Future<void> navigateUp(String? parent) async { if (parent != null) await load(parent); }

  Future<void> mkdir(String path) async {
    await _repo.mkdir(path);
    await load(state.currentPath);
  }

  Future<void> delete(String path, {bool recursive = false}) async {
    await _repo.delete(path, recursive: recursive);
    await load(state.currentPath);
  }

  Future<void> rename(String oldPath, String newPath) async {
    await _repo.rename(oldPath, newPath);
    await load(state.currentPath);
  }
}
