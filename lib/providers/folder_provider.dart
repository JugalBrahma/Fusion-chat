import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fusion_chat/services/folder_service.dart';

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

  Future<void> addFolder(String folderName) async {
    try {
      await _folderService.createFolder(folderName);
      // Reload folders to get the newly created folder with its ID
      await loadFolders();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateFolder(String folderId, Map<String, dynamic> updatedFolder) async {
    try {
      // Note: FolderService doesn't have an update method yet
      // You would need to add this to FolderService if needed:
      // await _folderService.updateFolder(folderId, updatedFolder);
      
      // For now, just update local state
      final currentState = state.value ?? [];
      state = AsyncValue.data(currentState.map((folder) => 
        folder['id'] == folderId ? {...folder, ...updatedFolder} : folder
      ).toList());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteFolder(String folderId) async {
    try {
      await _folderService.deleteFolder(folderId);
      // Remove from local state immediately
      final currentState = state.value ?? [];
      state = AsyncValue.data(currentState.where((folder) => folder['id'] != folderId).toList());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final folderProvider = AsyncNotifierProvider<FolderProvider, List<Map<String, dynamic>>>(FolderProvider.new);
