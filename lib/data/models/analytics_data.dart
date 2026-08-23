class AnalyticsData {
  final double avgLatency;
  final double minLatency;
  final double maxLatency;
  final double p95Latency;
  final double retrieverLatency;
  final double llmLatency;
  final int totalTokens;
  final int promptTokens;
  final int completionTokens;
  final int avgTokensPerRun;
  final int totalRuns;
  final double successRate;
  final String projectName;
  final List<TraceRun> recentTraces;
  final List<LatencyDataPoint> latencyTrend;

  const AnalyticsData({
    required this.avgLatency,
    required this.minLatency,
    required this.maxLatency,
    required this.p95Latency,
    required this.retrieverLatency,
    required this.llmLatency,
    required this.totalTokens,
    required this.promptTokens,
    required this.completionTokens,
    required this.avgTokensPerRun,
    required this.totalRuns,
    required this.successRate,
    required this.projectName,
    required this.recentTraces,
    required this.latencyTrend,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    final tracesList = (json['recent_traces'] as List<dynamic>?)
            ?.map((e) => TraceRun.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final trendList = (json['latency_trend'] as List<dynamic>?)
            ?.map((e) => LatencyDataPoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return AnalyticsData(
      avgLatency: (json['avg_latency'] as num?)?.toDouble() ?? 0.0,
      minLatency: (json['min_latency'] as num?)?.toDouble() ?? 0.0,
      maxLatency: (json['max_latency'] as num?)?.toDouble() ?? 0.0,
      p95Latency: (json['p95_latency'] as num?)?.toDouble() ?? 0.0,
      retrieverLatency: (json['retriever_latency'] as num?)?.toDouble() ?? 0.0,
      llmLatency: (json['llm_latency'] as num?)?.toDouble() ?? 0.0,
      totalTokens: (json['total_tokens'] as num?)?.toInt() ?? 0,
      promptTokens: (json['prompt_tokens'] as num?)?.toInt() ?? 0,
      completionTokens: (json['completion_tokens'] as num?)?.toInt() ?? 0,
      avgTokensPerRun: (json['avg_tokens_per_run'] as num?)?.toInt() ?? 0,
      totalRuns: (json['total_runs'] as num?)?.toInt() ?? 0,
      successRate: (json['success_rate'] as num?)?.toDouble() ?? 100.0,
      projectName: (json['project_name'] as String?) ?? 'fusion-chat',
      recentTraces: tracesList,
      latencyTrend: trendList,
    );
  }

  factory AnalyticsData.empty() {
    return const AnalyticsData(
      avgLatency: 0.0,
      minLatency: 0.0,
      maxLatency: 0.0,
      p95Latency: 0.0,
      retrieverLatency: 0.0,
      llmLatency: 0.0,
      totalTokens: 0,
      promptTokens: 0,
      completionTokens: 0,
      avgTokensPerRun: 0,
      totalRuns: 0,
      successRate: 100.0,
      projectName: 'fusion-chat',
      recentTraces: [],
      latencyTrend: [],
    );
  }
}

class TraceRun {
  final String id;
  final String name;
  final String runType;
  final double latency;
  final int totalTokens;
  final int promptTokens;
  final int completionTokens;
  final String status;
  final String query;
  final String timestamp;
  final String? modelName;

  const TraceRun({
    required this.id,
    required this.name,
    required this.runType,
    required this.latency,
    required this.totalTokens,
    required this.promptTokens,
    required this.completionTokens,
    required this.status,
    required this.query,
    required this.timestamp,
    this.modelName,
  });

  factory TraceRun.fromJson(Map<String, dynamic> json) {
    return TraceRun(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'RAG Agent Query',
      runType: json['run_type']?.toString() ?? 'chain',
      latency: (json['latency'] as num?)?.toDouble() ?? 0.0,
      totalTokens: (json['total_tokens'] as num?)?.toInt() ?? 0,
      promptTokens: (json['prompt_tokens'] as num?)?.toInt() ?? 0,
      completionTokens: (json['completion_tokens'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'success',
      query: json['query']?.toString() ?? 'Query',
      timestamp: json['timestamp']?.toString() ?? '',
      modelName: json['model_name']?.toString(),
    );
  }
}

class LatencyDataPoint {
  final String label;
  final double latency;
  final int totalTokens;

  const LatencyDataPoint({
    required this.label,
    required this.latency,
    required this.totalTokens,
  });

  factory LatencyDataPoint.fromJson(Map<String, dynamic> json) {
    return LatencyDataPoint(
      label: json['label']?.toString() ?? '',
      latency: (json['latency'] as num?)?.toDouble() ?? 0.0,
      totalTokens: (json['total_tokens'] as num?)?.toInt() ?? 0,
    );
  }
}
