import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
      auth: false,
    );

    if (response.success && response.data != null) {
      final token = response.data['token'];
      if (token != null) {
        await ApiClient.saveToken(token);
      }
      final user = UserModel.fromJson(response.data['user'] ?? {});
      return {'success': true, 'user': user, 'token': token};
    } else {
      return {'success': false, 'message': response.message ?? 'Login failed'};
    }
  }

  // Register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.register,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      },
      auth: false,
    );

    if (response.success && response.data != null) {
      final token = response.data['token'];
      if (token != null) {
        await ApiClient.saveToken(token);
      }
      final user = UserModel.fromJson(response.data['user'] ?? {});
      return {'success': true, 'user': user, 'token': token};
    } else {
      return {'success': false, 'message': response.message ?? 'Registration failed'};
    }
  }

  // Get Current User Profile
  static Future<UserModel?> getProfile() async {
    final response = await ApiClient.get(ApiConstants.userProfile);
    if (response.success && response.data != null && response.data['user'] != null) {
      return UserModel.fromJson(response.data['user']);
    }
    return null;
  }

  // Update Profile
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? studentId,
  }) async {
    final response = await ApiClient.put(
      ApiConstants.userProfile,
      body: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (studentId != null) 'studentId': studentId,
      },
    );

    if (response.success && response.data != null && response.data['user'] != null) {
      final user = UserModel.fromJson(response.data['user']);
      return {'success': true, 'user': user, 'message': response.data['message']};
    } else {
      return {'success': false, 'message': response.message ?? 'Update profile failed'};
    }
  }

  // Logout
  static Future<void> logout() async {
    await ApiClient.clearToken();
  }
}
