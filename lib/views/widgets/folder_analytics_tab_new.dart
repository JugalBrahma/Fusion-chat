import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/analytics_viewmodel.dart';

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
    final theme = Theme.of(context);
    
    return Container(
      color: theme.scaffoldBackgroundColor,
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
                          Icon(Icons.analytics_outlined, color: Theme.of(context).textTheme.headlineMedium?.color, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Folder Analytics',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).textTheme.headlineMedium?.color,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    final mainAxisExtent = screenHeight * 0.18;
    
    if (analytics == null) {
      return Container(
        padding: EdgeInsets.all(screenWidth * 0.08),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: screenWidth * 0.12,
              color: Colors.grey[400],
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'No analytics data available',
              style: GoogleFonts.inter(
                fontSize: screenWidth * 0.04,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              'Start chatting to see your analytics',
              style: GoogleFonts.inter(
                fontSize: screenWidth * 0.035,
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
        title: 'Total Tokens',
        value: '${analytics!['total_tokens'] ?? 0}',
        icon: Icons.token,
        color: const Color(0xFF14B8A6),
        subtitle: 'AI tokens used',
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
      _AnalyticsCard(
        title: 'AI Responses',
        value: '${analytics!['assistant_messages'] ?? 0}',
        icon: Icons.smart_toy,
        color: const Color(0xFF6366F1),
        subtitle: 'Successful AI replies',
      ),
      _AnalyticsCard(
        title: 'AI Failures',
        value: '${analytics!['failed_ai_messages'] ?? 0}',
        icon: Icons.error_outline,
        color: const Color(0xFFEF4444),
        subtitle: 'Errors from assistant',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: screenWidth * 0.04,
        mainAxisSpacing: screenHeight * 0.02,
        mainAxisExtent: mainAxisExtent,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.025),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
              ),
              child: Icon(icon, color: color, size: screenWidth * 0.05),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              value,
              style: GoogleFonts.inter(
                color: Theme.of(context).textTheme.headlineMedium?.color ?? const Color(0xFF111827),
                fontSize: screenWidth * 0.055,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: screenHeight * 0.003),
            Text(
              title,
              style: GoogleFonts.inter(
                color: Theme.of(context).textTheme.bodyMedium?.color ?? const Color(0xFF6B7280),
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF9CA3AF),
                fontSize: screenWidth * 0.026,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
