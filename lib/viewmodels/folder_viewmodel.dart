import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/folder_service.dart';

final folderProvider =
    AsyncNotifierProvider<FolderViewModel, List<Map<String, dynamic>>>(
      FolderViewModel.new,
    );

class FolderViewModel extends AsyncNotifier<List<Map<String, dynamic>>> {
  final FolderService _folderService = FolderService();

  @override
  Future<List<Map<String, dynamic>>> build() async {
    return [];
  }

  Future<void> loadFolders() async {
    state = const AsyncValue.loading();

    try {
      final stream = _folderService.getFolders();
      await for (final snapshot in stream) {
        final folders = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
        state = AsyncValue.data(folders);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addFolder(String folderName) async {
    try {
      await _folderService.createFolder(folderName);
      await loadFolders();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateFolder(
    String folderId,
    Map<String, dynamic> updatedFolder,
  ) async {
    try {
      final currentState = state.value ?? [];
      state = AsyncValue.data(
        currentState
            .map(
              (folder) => folder['id'] == folderId
                  ? {...folder, ...updatedFolder}
                  : folder,
            )
            .toList(),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteFolder(String folderId) async {
    try {
      await _folderService.deleteFolder(folderId);
      final currentState = state.value ?? [];
      final updatedFolders = currentState
          .where((folder) => folder['id'] != folderId)
          .toList();
      state = AsyncValue.data(updatedFolders);
      await loadFolders();
    } catch (error, stackTrace) {
      await loadFolders();
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
