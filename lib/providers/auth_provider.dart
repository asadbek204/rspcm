import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/auth_models.dart';
import '../models/models.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  StudentProfileResponse? _profile;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  String? get token => _token;
  StudentProfileResponse? get profile => _profile;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _isAuthenticated = _token != null && _token!.isNotEmpty;

    try {
      if (_isAuthenticated) {
        final profile = await _apiService.getMyProfile();
        if (profile != null) {
          _profile = profile;
        } else {
          await logout();
          return;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final profile = await _apiService.getMyProfile();
      if (profile != null) {
        _profile = profile;
      }
    } catch (e) {
      // Handle error silently or via a snackbar
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({int? course}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updated = await _apiService.updateMyProfile(course: course);
      if (updated != null) {
        _profile = updated;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String identifier, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(LoginRequest(identifier: identifier, password: password));
      if (response.token.isEmpty) {
        throw Exception('Login failed: empty token in response');
      }
      _token = response.token;
      _isAuthenticated = true;
      _profile = await _apiService.getMyProfile();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
    } catch (e) {
      _isAuthenticated = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(RegisterRequest request) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.register(request);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String email, String code) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _apiService.verifyOtp(VerifyOtpRequest(email: email, code: code));
      return success;
    } catch (e) {
      print('OTP Verification Failed: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resendOtp(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _apiService.resendOtp(ResendOtpRequest(email: email));
      return success;
    } catch (e) {
      print('Resend OTP Failed: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _profile = null;
    _isAuthenticated = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }
}
