import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FolderAnalyticsTab extends StatelessWidget {
  const FolderAnalyticsTab({super.key});

  static const _segments = [
    _AnalyticsSegment('Concept Clarity', 42, Color(0xFF3B82F6)),
    _AnalyticsSegment('Speed', 30, Color(0xFF22C55E)),
    _AnalyticsSegment('Accuracy', 18, Color(0xFFF97316)),
    _AnalyticsSegment('Revision', 10, Color(0xFF6366F1)),
  ];

  static const _quickStats = [
    _QuickStat('Questions Practiced', '1,247', Icons.bolt, Color(0xFF3B82F6)),
    _QuickStat('Avg Accuracy', '87%', Icons.check_circle, Color(0xFF22C55E)),
    _QuickStat('Streak', '12 days', Icons.local_fire_department, Color(0xFFF59E0B)),
    _QuickStat('Folders Synced', '8', Icons.folder, Color(0xFF6366F1)),
  ];

  static const _history = [
    _HistoryItem('Physics - Mechanics', 'JEE · 50 questions · 2 hours ago', 0.88, Color(0xFF7C3BED)),
    _HistoryItem('Biology - Cell Biology', 'NEET · 40 questions · Yesterday', 0.92, Color(0xFF00D6C4)),
    _HistoryItem('Computer Science - DSA', 'GATE · 60 questions · 2 days ago', 0.85, Color(0xFFE7B008)),
    _HistoryItem('Chemistry - Organic', 'JEE · 45 questions · 3 days ago', 0.78, Color(0xFFAB30E8)),
  ];

  static const _progress = [
    _ProgressStat('Hard', 0.75, Color(0xFF7C3BED)),
    _ProgressStat('Medium', 0.6, Color(0xFF00D6C4)),
    _ProgressStat('Easy', 0.85, Color(0xFFE7B008)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: Color(0xFF1F2937), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Analytics Pulse',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ChartSummaryCard(segments: _segments),
            const SizedBox(height: 24),
            _QuickStatGrid(stats: _quickStats),
            const SizedBox(height: 24),
            _HistoryCard(items: _history),
            const SizedBox(height: 24),
            _ProgressCard(stats: _progress),
          ],
        ),
      ),
    );
  }
}

class _ChartSummaryCard extends StatelessWidget {
  final List<_AnalyticsSegment> segments;

  const _ChartSummaryCard({required this.segments});

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (sum, item) => sum + item.value);
    final topSegment = segments.first;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final chartSize = isNarrow ? 140.0 : 160.0;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Focus',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                topSegment.label,
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${topSegment.value.toStringAsFixed(0)}% of weekly sessions',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: segments
                    .map(
                      (segment) => _LegendDot(
                        label: segment.label,
                        value: '${segment.value.toStringAsFixed(0)}%',
                        color: segment.color,
                      ),
                    )
                    .toList(),
              ),
            ],
          );

          final chart = SizedBox(
            width: chartSize,
            height: chartSize,
            child: _PieChart(total: total, segments: segments),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 20),
                Center(child: chart),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              chart,
            ],
          );
        },
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  final double total;
  final List<_AnalyticsSegment> segments;

  const _PieChart({required this.total, required this.segments});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size.square(160),
          painter: _RingChartPainter(
            segments: segments,
            total: total,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${segments.first.value.toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                color: const Color(0xFF111827),
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'focus',
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RingChartPainter extends CustomPainter {
  final List<_AnalyticsSegment> segments;
  final double total;

  _RingChartPainter({required this.segments, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final startAngle = -90.0;
    double currentAngle = startAngle;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    for (final segment in segments) {
      final sweepAngle = (segment.value / total) * 360;
      paint.color = segment.color;
      canvas.drawArc(
        rect.deflate(8),
        currentAngle * (3.141592653589793 / 180),
        sweepAngle * (3.141592653589793 / 180),
        false,
        paint,
      );
      currentAngle += sweepAngle;
    }

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(size.center(Offset.zero), size.width / 2 - 32, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LegendDot extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LegendDot({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(color: const Color(0xFF111827), fontSize: 12),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QuickStatGrid extends StatelessWidget {
  final List<_QuickStat> stats;

  const _QuickStatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: stats.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 180,
      ),
      itemBuilder: (_, index) {
        final stat = stats[index];
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
                  color: stat.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(stat.icon, color: stat.color, size: 20),
              ),
              const SizedBox(height: 24),
              Text(
                stat.value,
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stat.label,
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final List<_HistoryItem> items;

  const _HistoryCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              Text(
                'Practice History',
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => _HistoryTile(item: item)).toList(),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final _HistoryItem item;

  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.accent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.auto_graph, color: item.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(item.score * 100).round()}%',
                style: GoogleFonts.inter(
                  color: item.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 80,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: item.score,
                  child: Container(
                    decoration: BoxDecoration(
                      color: item.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final List<_ProgressStat> stats;

  const _ProgressCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timelapse, color: Color(0xFF6366F1), size: 20),
              const SizedBox(width: 8),
              Text(
                'Difficulty Progress',
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...stats.map((stat) => _ProgressRow(stat: stat)).toList(),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final _ProgressStat stat;

  const _ProgressRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                stat.label,
                style: GoogleFonts.inter(color: const Color(0xFF111827), fontSize: 14),
              ),
              const Spacer(),
              Text(
                '${(stat.value * 100).round()}%',
                style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: stat.value,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation(stat.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsSegment {
  final String label;
  final double value;
  final Color color;

  const _AnalyticsSegment(this.label, this.value, this.color);
}

class _QuickStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickStat(this.label, this.value, this.icon, this.color);
}

class _HistoryItem {
  final String title;
  final String subtitle;
  final double score;
  final Color accent;

  const _HistoryItem(this.title, this.subtitle, this.score, this.accent);
}

class _ProgressStat {
  final String label;
  final double value;
  final Color color;

  const _ProgressStat(this.label, this.value, this.color);
}
