import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_constants.dart';

enum AuthState { idle, validating, loading, error, success }

enum AuthMode { login, register }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.idle;
  AuthMode _mode = AuthMode.login;
  String? _errorMessage;
  String? _currentUserEmail;
  String? _token;
  String? _refreshToken;
  Map<String, dynamic>? _aiInsights;

  AuthState get state => _state;
  AuthMode get mode => _mode;
  String? get errorMessage => _errorMessage;
  String? get currentUserEmail => _currentUserEmail;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get aiInsights => _aiInsights;

  void clearAiInsights() {
    _aiInsights = null;
    notifyListeners();
  }

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('token') && prefs.containsKey('email')) {
      _token = prefs.getString('token');
      _refreshToken = prefs.getString('refresh_token');
      _currentUserEmail = prefs.getString('email');
      notifyListeners();
    }
  }

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

    try {
      if (_mode == AuthMode.login) {
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          _token = data['access_token'];
          _refreshToken = data['refresh_token'];
          _currentUserEmail = data['user']['email'];
          _aiInsights = data['ai_insights'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          if (_refreshToken != null) {
            await prefs.setString('refresh_token', _refreshToken!);
          }
          await prefs.setString('email', _currentUserEmail!);

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
        // A API exige o campo 'name', como a UI não tem esse campo, vamos usar a primeira parte do email
        final name = email.split('@').first;
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/users'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          _state = AuthState.success;
          notifyListeners();
          return true;
        } else if (response.statusCode == 409) {
          _state = AuthState.error;
          _errorMessage = 'Esse e-mail já existe no sistema.';
          notifyListeners();
          return false;
        } else {
          final errorData = jsonDecode(response.body);
          _state = AuthState.error;
          _errorMessage = errorData['message'] is List
              ? errorData['message'][0]
              : errorData['message'];
          notifyListeners();
          return false;
        }
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Erro de conexão com o servidor.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _state = AuthState.idle;
    _mode = AuthMode.login;
    _errorMessage = null;
    _currentUserEmail = null;
    _token = null;
    _refreshToken = null;
    _aiInsights = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refresh_token');
    await prefs.remove('email');

    notifyListeners();
  }
}
