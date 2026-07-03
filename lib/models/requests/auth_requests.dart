class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  final String email;
  final String password;
  final String role;
  final String? phone;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.role,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'role': role,
        if (phone != null) 'phone': phone,
      };
}

class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}
