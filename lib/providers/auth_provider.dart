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
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _isAuthenticated = _token != null;
    
    if (_isAuthenticated) {
      fetchProfile(); // Initial fetch
    }
    
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    try {
      _profile = await _apiService.getMyProfile();
      notifyListeners();
    } catch (e) {
      // Handle error silently or via a snackbar
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(LoginRequest(email: email, password: password));
      _token = response.token;
      _isAuthenticated = true;
      
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
