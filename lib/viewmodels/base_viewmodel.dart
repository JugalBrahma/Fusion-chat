import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base ViewModel class for MVVM architecture
/// All ViewModels should extend this class
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// Extension to easily convert ViewModels to StateNotifierProvider
abstract class StateNotifierViewModel<T> extends StateNotifier<T> {
  StateNotifierViewModel(super.state);
}
