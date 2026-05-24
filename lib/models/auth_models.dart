class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class AuthResponse {
  final String token;
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final List<String> roles;

  AuthResponse({
    required this.token,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.roles,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      userId: json['userId'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      roles: json['roles'] != null ? List<String>.from(json['roles']) : [],
    );
  }
}

// Swagger RegisterRequest
class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final List<String> roles;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.roles = const ['STUDENT'],
  });

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'password': password,
    'roles': roles,
  };
}

class VerifyOtpRequest {
  final String email;
  final String code;

  VerifyOtpRequest({required this.email, required this.code});

  Map<String, dynamic> toJson() => {
    'email': email,
    'code': code,
  };
}

class ResendOtpRequest {
  final String email;

  ResendOtpRequest({required this.email});

  Map<String, dynamic> toJson() => {
    'email': email,
  };
}
