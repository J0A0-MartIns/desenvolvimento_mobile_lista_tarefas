import 'package:flutter/material.dart';

enum AuthState { idle, validating, loading, error, success }
enum AuthMode { login, register }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.idle;
  AuthMode _mode = AuthMode.login;
  String? _errorMessage;

  AuthState get state => _state;
  AuthMode get mode => _mode;
  String? get errorMessage => _errorMessage;

  void toggleMode() {
    _mode = _mode == AuthMode.login ? AuthMode.register : AuthMode.login;
    _state = AuthState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void validateForm() {
    if (_state != AuthState.loading) {
      _state = AuthState.validating;
      notifyListeners();
    }
  }

  Future<bool> submit(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Basic mock authentication
    if (_mode == AuthMode.login) {
      if (email == 'admin@teste.com' && password == '123456') {
        _state = AuthState.success;
        notifyListeners();
        return true;
      } else {
        _state = AuthState.error;
        _errorMessage = 'Credenciais inválidas.';
        notifyListeners();
        return false;
      }
    } else {
      // Mock register
      _state = AuthState.success;
      notifyListeners();
      return true;
    }
  }

  void logout() {
    _state = AuthState.idle;
    _mode = AuthMode.login;
    _errorMessage = null;
    notifyListeners();
  }
}
