import 'package:backendtest/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/folder_content_screen.dart';
import 'widgets/loading_overlay.dart';
import 'providers/auth_provider.dart';
import 'providers/folder_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _folderNameController = TextEditingController();
  bool _isActionLoading = false;
  final Set<String> _deletingFolders = <String>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(folderProvider.notifier).loadFolders();
    });
  }

  @override
  Widget build(BuildContext context) {

    return LoadingOverlay(
      isLoading: _isActionLoading,
      message: 'Working...',
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Folders'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Add Folder Section
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Folder',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _folderNameController,
                          decoration: InputDecoration(
                            labelText: 'Folder Name',
                            hintText: 'Enter folder name...',
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (_folderNameController.text.isNotEmpty) {
                            final folderName = _folderNameController.text;
                            try {
                              _folderNameController.clear();
                              await ref
                                  .read(folderProvider.notifier)
                                  .addFolder(folderName);
                              if (mounted) {
                                NotificationService.showSuccess(
                                  context,
                                  'Folder created successfully',
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                _folderNameController.text = folderName;
                              }
                              if (mounted) {
                                NotificationService.showError(
                                  context,
                                  'Error: $e',
                                );
                              }
                            }
                          }
                        },
                        icon: Icon(Icons.add, size: 18),
                        label: Text('Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Folders List
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Builder(
                  builder: (context) {
                    final foldersAsync = ref.watch(folderProvider);

                    return foldersAsync.when(
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      error: (error, stackTrace) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Color(0xFFEF4444)),
                            SizedBox(height: 16),
                            Text(
                              'Error loading folders',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                      data: (folders) {
                        if (folders.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.folder_outlined,
                                    size: 48,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No folders yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Create your first folder to get started',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.only(bottom: 16),
                          itemCount: folders.length,
                          itemBuilder: (context, index) {
                            final folder = folders[index];
                            final folderId = folder['id'] as String?;
                            return Container(
                              margin: EdgeInsets.only(bottom: 8),
                              child: Card(
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 8),
                                  leading: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _deletingFolders.contains(folderId)
                                          ? Color(0xFFFEE2E2)
                                          : Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: _deletingFolders.contains(folderId)
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                                            ),
                                          )
                                        : Icon(
                                            Icons.folder,
                                            color: Color(0xFF3B82F6),
                                            size: 24,
                                          ),
                                  ),
                                  title: Text(
                                    folder['name'],
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: _deletingFolders.contains(folderId)
                                          ? Color(0xFF94A3B8)
                                          : Color(0xFF1E293B),
                                    ),
                                  ),
                                  subtitle: Text(
                                    _deletingFolders.contains(folderId)
                                        ? 'Deleting folder...'
                                        : 'Tap to open and manage',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  trailing: _deletingFolders.contains(folderId)
                                      ? null
                                      : PopupMenuButton<String>(
                                          icon: Icon(Icons.more_vert,
                                              color: Color(0xFF94A3B8)),
                                          onSelected: (value) {
                                            if (value == 'delete') {
                                              _showDeleteConfirmation(context, folder);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete,
                                                      color: Color(0xFFEF4444),
                                                      size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Delete'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                  onTap: _deletingFolders.contains(folderId)
                                      ? null
                                      : () {
                                          if (folderId == null) {
                                            return;
                                          }
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => FolderContentScreen(
                                                folderId: folderId,
                                                folderName: folder['name'],
                                              ),
                                            ),
                                          );
                                        },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, Map<String, dynamic> folder) async {
    NotificationService.showDeleteConfirmation(
      context,
      title: 'Delete Folder',
      itemName: folder['name'],
      warnings: [
        '⚠️ Important: You must delete all PDFs from Upload section first!',
        'This will permanently delete:',
        '• All progress data and analytics',
        '• All associated files and metadata',
      ],
      onConfirm: () async {
        setState(() {
          _deletingFolders.add(folder['id']);
        });

        try {
          await ref.read(folderProvider.notifier).deleteFolder(folder['id']);
          if (mounted) {
            NotificationService.showSuccess(
              context,
              'Folder "${folder['name']}" deleted successfully',
            );
          }
        } catch (e) {
          if (mounted) {
            NotificationService.showError(
              context,
              'Failed to delete folder: $e',
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _deletingFolders.remove(folder['id']);
            });
          }
        }
      },
    );
  }

}
