import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState {
  final bool isDarkMode;

  const ThemeState({this.isDarkMode = false});

  ThemeState copyWith({bool? isDarkMode}) {
    return ThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

class ThemeViewModel extends StateNotifier<ThemeState> {
  static const String _themeKey = 'is_dark_mode';

  ThemeViewModel() : super(const ThemeState()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themeKey) ?? false;
      state = state.copyWith(isDarkMode: isDark);
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    final newValue = !state.isDarkMode;
    state = state.copyWith(isDarkMode: newValue);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, newValue);
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(isDarkMode: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, value);
    } catch (e) {
      print('Error saving theme: $e');
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeViewModel, ThemeState>((ref) {
  return ThemeViewModel();
});
