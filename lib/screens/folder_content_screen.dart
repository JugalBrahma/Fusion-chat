import 'package:flutter/material.dart';
import 'folder_upload_screen.dart';
import 'chat_screen.dart';
import 'widgets/folder_analytics_tab_new.dart';

class FolderContentScreen extends StatefulWidget {
  final String folderId;
  final String folderName;

  const FolderContentScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<FolderContentScreen> createState() => _FolderContentScreenState();
}

class _FolderContentScreenState extends State<FolderContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Refresh control
  final GlobalKey<RefreshIndicatorState> _uploadRefreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _refreshCurrentTab() async {
    switch (_tabController.index) {
      case 0: // Upload
        _uploadRefreshKey.currentState?.show();
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.red),
            tooltip: 'Chat legend',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Chat Legend'),
                  content: const Text(
                    'Blue highlight = exact words from documents.\n'
                    'Purple label = response used documents.\n'
                    'Tip: Use correct spellings and matching words from your documents when querying.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCurrentTab,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chat'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.cloud_upload_outlined), text: 'Upload'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ChatScreen(
            folderId: widget.folderId,
            folderName: widget.folderName,
          ),
          FolderAnalyticsTab(folderId: widget.folderId),
          RefreshIndicator(
            key: _uploadRefreshKey,
            onRefresh: () async {
              // Trigger upload refresh
              setState(() {});
            },
            child: FolderUploadScreen(
              folderId: widget.folderId,
              folderName: widget.folderName,
            ),
          ),
        ],
      ),
    );
  }
}
