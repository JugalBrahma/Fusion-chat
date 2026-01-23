import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/folder_service.dart';

// State class for home page
class HomePageState {
  final bool isActionLoading;
  final Set<String> deletingFolders;

  HomePageState({
    this.isActionLoading = false,
    this.deletingFolders = const {},
  });

  HomePageState copyWith({
    bool? isActionLoading,
    Set<String>? deletingFolders,
  }) {
    return HomePageState(
      isActionLoading: isActionLoading ?? this.isActionLoading,
      deletingFolders: deletingFolders ?? this.deletingFolders,
    );
  }
}

// StateNotifier for home page
class HomePageNotifier extends StateNotifier<HomePageState> {
  HomePageNotifier() : super(HomePageState());

  void setActionLoading(bool loading) {
    state = state.copyWith(isActionLoading: loading);
  }

  void addDeletingFolder(String folderId) {
    final newSet = Set<String>.from(state.deletingFolders)..add(folderId);
    state = state.copyWith(deletingFolders: newSet);
  }

  void removeDeletingFolder(String folderId) {
    final newSet = Set<String>.from(state.deletingFolders)..remove(folderId);
    state = state.copyWith(deletingFolders: newSet);
  }
}

// Provider for home page state
final homePageProvider = StateNotifierProvider<HomePageNotifier, HomePageState>((ref) {
  return HomePageNotifier();
});

// Provider for folder service
final folderServiceProvider = Provider<FolderService>((ref) {
  return FolderService();
});
