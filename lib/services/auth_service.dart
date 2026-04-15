import '../core/utils/http_helper.dart';

class AuthLoginRequest {
  final String userName;
  final String userPassword;

  const AuthLoginRequest({required this.userName, required this.userPassword});

  Map<String, dynamic> toJson() => {
    'user_name': userName,
    'user_password': userPassword,
  };
}

class AuthLoginResponse {
  final String accessToken;
  final String tokenType;
  final int userId;
  final String userName;
  final String role;
  final String? teacherId;

  const AuthLoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.userId,
    required this.userName,
    required this.role,
    this.teacherId,
  });

  factory AuthLoginResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return AuthLoginResponse(
      accessToken: data['access_token'] as String,
      tokenType: data['token_type'] as String? ?? 'bearer',
      userId: data['user_id'] as int,
      userName: data['user_name'] as String,
      role: data['role'] as String,
      teacherId: data['teacher_id'] as String?,
    );
  }
}

class AuthService {
  final HttpHelper _http = HttpHelper();

  Future<AuthLoginResponse> login(AuthLoginRequest request) async {
    final response = await _http.post('/auth/login', body: request.toJson());
    final json = _http.handleJson(response);
    return AuthLoginResponse.fromJson(json);
  }
}
