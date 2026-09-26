import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isStudent => _currentUser?.role == 'student';
  bool get isTeacher => _currentUser?.role == 'teacher';
  bool get isAdmin => _currentUser?.role == 'admin';

  // Initialize & Check auto-login
  Future<bool> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await ApiClient.getToken();
      if (token != null && token.isNotEmpty) {
        final profile = await AuthService.getProfile();
        if (profile != null) {
          _currentUser = profile;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await AuthService.login(email: email, password: password);
    _isLoading = false;

    if (res['success'] == true) {
      _currentUser = res['user'];
      notifyListeners();
      return true;
    } else {
      _errorMessage = res['message'];
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await AuthService.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
    _isLoading = false;

    if (res['success'] == true) {
      _currentUser = res['user'];
      notifyListeners();
      return true;
    } else {
      _errorMessage = res['message'];
      notifyListeners();
      return false;
    }
  }

  // Update Profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? studentId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await AuthService.updateProfile(
      name: name,
      phone: phone,
      studentId: studentId,
    );
    _isLoading = false;

    if (res['success'] == true) {
      _currentUser = res['user'];
      notifyListeners();
      return true;
    } else {
      _errorMessage = res['message'];
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await AuthService.logout();
    _currentUser = null;
    notifyListeners();
  }
}
