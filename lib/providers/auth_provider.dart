import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../models/auth_models.dart';
import '../models/models.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String _role = ''; // 'TEACHER' or 'STUDENT'
  StudentProfileResponse? _studentProfile;
  TeacherProfileModel? _teacherProfile;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  String? get token => _token;
  String get role => _role;
  bool get isTeacher => _role == 'TEACHER';
  bool get isStudent => _role == 'STUDENT';
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  // Backward-compat for student screens / drawer
  StudentProfileResponse? get profile => _studentProfile;
  TeacherProfileModel? get teacherProfile => _teacherProfile;

  // Common display fields regardless of role
  String get displayName {
    if (isTeacher && _teacherProfile != null) {
      return '${_teacherProfile!.firstName} ${_teacherProfile!.lastName}'.trim();
    }
    if (_studentProfile != null) {
      return '${_studentProfile!.firstName} ${_studentProfile!.lastName}'.trim();
    }
    return '';
  }

  String get displayEmail {
    if (isTeacher && _teacherProfile != null) return _teacherProfile!.email;
    return _studentProfile?.email ?? '';
  }

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _role = prefs.getString('user_role') ?? '';
    _isAuthenticated = _token != null && _token!.isNotEmpty;

    try {
      if (_isAuthenticated) {
        await _fetchProfile();
        if (_studentProfile == null && _teacherProfile == null) {
          await logout();
          return;
        }
        NotificationService().init().catchError((_) {});
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchProfile() async {
    if (_role == 'TEACHER') {
      _teacherProfile = await _apiService.getTeacherProfile();
    } else {
      _studentProfile = await _apiService.getMyProfile();
    }
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _fetchProfile();
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({int? course}) async {
    if (isTeacher) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final updated = await _apiService.updateMyProfile(course: course);
      if (updated != null) {
        _studentProfile = updated;
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

      // Determine role from response
      final roles = response.roles;
      if (roles.any((r) => r.toUpperCase().contains('TEACHER'))) {
        _role = 'TEACHER';
      } else {
        _role = 'STUDENT';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_role', _role);

      await _fetchProfile();
      NotificationService().init().catchError((_) {});
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
      return await _apiService.verifyOtp(VerifyOtpRequest(email: email, code: code));
    } catch (_) {
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
      return await _apiService.resendOtp(ResendOtpRequest(email: email));
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _role = '';
    _studentProfile = null;
    _teacherProfile = null;
    _isAuthenticated = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    notifyListeners();
  }
}
