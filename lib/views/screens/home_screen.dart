import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';    
import '../../data/services/notification_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/folder_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import 'folder_content_screen.dart';
import '../widgets/loading_overlay.dart';

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
          title: Text(
            'My Folders',
            style: TextStyle(
              color: Theme.of(context).appBarTheme.foregroundColor ??
                  (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            ),
          ),
          actions: [
            Consumer(
              builder: (context, ref, child) {
                final themeState = ref.watch(themeProvider);
                return IconButton(
                  icon: Icon(
                    themeState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
                  onPressed: () {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                  tooltip: themeState.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.logout,
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
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
                color: Theme.of(context).cardTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
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
                      color: Theme.of(context).textTheme.headlineMedium?.color,
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
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.folder_outlined,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No folders yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).textTheme.headlineMedium?.color,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Create your first folder to get started',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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
                            final isDark = Theme.of(context).brightness == Brightness.dark;
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
                                          ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2))
                                          : (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: _deletingFolders.contains(folderId)
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444)),
                                            ),
                                          )
                                        : Icon(
                                            Icons.folder,
                                            color: Theme.of(context).colorScheme.primary,
                                            size: 24,
                                          ),
                                  ),
                                  title: Text(
                                    folder['name'],
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: _deletingFolders.contains(folderId)
                                          ? Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)
                                          : Theme.of(context).textTheme.headlineMedium?.color,
                                    ),
                                  ),
                                  subtitle: Text(
                                    _deletingFolders.contains(folderId)
                                        ? 'Deleting folder...'
                                        : 'Tap to open and manage',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  trailing: _deletingFolders.contains(folderId)
                                      ? null
                                      : PopupMenuButton<String>(
                                          icon: Icon(Icons.more_vert,
                                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
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

  Future<void> _showDeleteConfirmation(BuildContext context, Map<String, dynamic> folder) async {
    NotificationService.showDeleteConfirmation(
      context,
      title: 'Delete Folder',
      itemName: folder['name'],
      warnings: [
        'Important: You must delete all PDFs from Upload section first!',
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
