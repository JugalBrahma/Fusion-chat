import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:backendtest/services/folder_service.dart';

class FolderProvider extends AsyncNotifier<List<Map<String, dynamic>>> {
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
        final folders = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>
        }).toList();
        state = AsyncValue.data(folders);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addFolder(Map<String, dynamic> folder) async {
    final currentState = state.value ?? [];
    state = AsyncValue.data([...currentState, folder]);
  }

  Future<void> updateFolder(String folderId, Map<String, dynamic> updatedFolder) async {
    final currentState = state.value ?? [];
    state = AsyncValue.data(currentState.map((folder) => 
      folder['id'] == folderId ? updatedFolder : folder
    ).toList());
  }

  Future<void> deleteFolder(String folderId) async {
    final currentState = state.value ?? [];
    state = AsyncValue.data(currentState.where((folder) => folder['id'] != folderId).toList());
  }
}

final folderProvider = AsyncNotifierProvider<FolderProvider, List<Map<String, dynamic>>>(FolderProvider.new);
