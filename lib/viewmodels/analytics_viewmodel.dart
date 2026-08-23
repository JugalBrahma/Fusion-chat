import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/analytics_data.dart';
import '../data/services/analytics_service.dart';

class AnalyticsState {
  final bool isLoading;
  final bool isRefreshing;
  final AnalyticsData? data;
  final String? error;

  const AnalyticsState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.data,
    this.error,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    AnalyticsData? data,
    String? error,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      data: data ?? this.data,
      error: error,
    );
  }
}

class AnalyticsViewModel extends StateNotifier<AnalyticsState> {
  final AnalyticsService _analyticsService;
  final String folderId;

  AnalyticsViewModel(this._analyticsService, this.folderId)
      : super(const AnalyticsState()) {
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _analyticsService.getAnalytics(folderId: folderId);
      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, error: null);
    try {
      final data = await _analyticsService.getAnalytics(folderId: folderId);
      state = state.copyWith(isRefreshing: false, data: data);
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

final analyticsProvider =
    StateNotifierProvider.family<AnalyticsViewModel, AnalyticsState, String>(
  (ref, folderId) {
    final service = ref.watch(analyticsServiceProvider);
    return AnalyticsViewModel(service, folderId);
  },
);
