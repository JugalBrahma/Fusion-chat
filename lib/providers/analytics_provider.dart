import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:backendtest/services/analytics_service.dart';

class AnalyticsState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;

  const AnalyticsState({
    this.isLoading = false,
    this.data,
    this.error,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier(this._analyticsService) : super(const AnalyticsState());

  final AnalyticsService _analyticsService;

  Future<void> loadFolderAnalytics(String folderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final analytics = await _analyticsService.getFolderAnalyticsFromApi(folderId);
      state = state.copyWith(isLoading: false, data: analytics);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(AnalyticsService());
});
