import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/analytics_provider.dart';

class FolderAnalyticsTab extends ConsumerStatefulWidget {
  final String folderId;
  
  const FolderAnalyticsTab({super.key, required this.folderId});

  @override
  ConsumerState<FolderAnalyticsTab> createState() => _FolderAnalyticsTabState();
}

class _FolderAnalyticsTabState extends ConsumerState<FolderAnalyticsTab> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(analyticsProvider.notifier).loadFolderAnalytics(widget.folderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);
    final analytics = analyticsState.data;
    return Container(
      color: const Color(0xFFF9FAFB),
      child: analyticsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : analytics == null
              ? Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        analyticsState.error?.isNotEmpty == true
                            ? analyticsState.error!
                            : 'Failed to load analytics',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(analyticsProvider.notifier)
                              .loadFolderAnalytics(widget.folderId);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics_outlined, color: Color(0xFF1F2937), size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Folder Analytics',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                            ref
                                .read(analyticsProvider.notifier)
                                .loadFolderAnalytics(widget.folderId);
                          },
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _AnalyticsGrid(analytics: analytics),
                    ],
                  ),
                ),
    );
  }
}

class _AnalyticsGrid extends StatelessWidget {
  final Map<String, dynamic>? analytics;

  const _AnalyticsGrid({required this.analytics});

  @override
  Widget build(BuildContext context) {
    if (analytics == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No analytics data available',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start chatting to see your analytics',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final stats = [
      _AnalyticsCard(
        title: 'Total Messages',
        value: '${analytics!['total_messages'] ?? 0}',
        icon: Icons.chat,
        color: const Color(0xFF3B82F6),
        subtitle: 'All conversations',
      ),
      _AnalyticsCard(
        title: 'MCQ Questions',
        value: '${analytics!['mcq_count'] ?? 0}',
        icon: Icons.quiz,
        color: const Color(0xFF10B981),
        subtitle: 'Questions generated',
      ),
      _AnalyticsCard(
        title: 'Document References',
        value: '${analytics!['doc_retrieval_count'] ?? 0}',
        icon: Icons.description,
        color: const Color(0xFF8B5CF6),
        subtitle: 'Data retrieved from docs',
      ),
      _AnalyticsCard(
        title: 'User Messages',
        value: '${analytics!['user_messages'] ?? 0}',
        icon: Icons.person,
        color: const Color(0xFFF59E0B),
        subtitle: 'Your messages',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 210,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => stats[index],
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              color: const Color(0xFF111827),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
