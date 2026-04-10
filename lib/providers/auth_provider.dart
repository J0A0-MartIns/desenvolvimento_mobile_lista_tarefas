import 'package:flutter/material.dart';

enum AuthState { idle, validating, loading, error, success }
enum AuthMode { login, register }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.idle;
  AuthMode _mode = AuthMode.login;
  String? _errorMessage;
  String? _currentUserEmail;

  final Map<String, String> _registeredAccounts = {
    'admin@teste.com': '123456' 
  };

  AuthState get state => _state;
  AuthMode get mode => _mode;
  String? get errorMessage => _errorMessage;
  String? get currentUserEmail => _currentUserEmail;

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

    await Future.delayed(const Duration(seconds: 2));

    if (_mode == AuthMode.login) {
      if (_registeredAccounts.containsKey(email) && _registeredAccounts[email] == password) {
        _state = AuthState.success;
        _currentUserEmail = email;
        notifyListeners();
        return true;
      } else {
        _state = AuthState.error;
        _errorMessage = 'Credenciais inválidas ou conta inexistente.';
        notifyListeners();
        return false;
      }
    } else {
      if (_registeredAccounts.containsKey(email)) {
        _state = AuthState.error;
        _errorMessage = 'Esse e-mail já existe no sistema.';
        notifyListeners();
        return false;
      } else {
        _registeredAccounts[email] = password; 
        _state = AuthState.success;
        // Não loga automaticamente no cadastro, continua nulo!
        notifyListeners();
        return true;
      }
    }
  }

  void logout() {
    _state = AuthState.idle;
    _mode = AuthMode.login;
    _errorMessage = null;
    _currentUserEmail = null;
    notifyListeners();
  }
}
