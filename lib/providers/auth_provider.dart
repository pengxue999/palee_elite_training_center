import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../core/utils/http_helper.dart';

const _tokenKey = 'auth_token';
const _userIdKey = 'auth_user_id';
const _userNameKey = 'auth_user_name';
const _roleKey = 'auth_role';
const _teacherIdKey = 'auth_teacher_id';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isInitializing;
  final String? error;
  final int? userId;
  final String? userName;
  final String? role;
  final String? token;
  final String? teacherId;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isInitializing = true,
    this.error,
    this.userId,
    this.userName,
    this.role,
    this.token,
    this.teacherId,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isInitializing,
    String? error,
    int? userId,
    String? userName,
    String? role,
    String? token,
    String? teacherId,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      token: token ?? this.token,
      teacherId: teacherId ?? this.teacherId,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthState()) {
    state = state.copyWith(isInitializing: false);
  }

  Future<bool> login(String userName, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.login(
        AuthLoginRequest(userName: userName, userPassword: password),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, response.accessToken);
      await prefs.setInt(_userIdKey, response.userId);
      await prefs.setString(_userNameKey, response.userName);
      await prefs.setString(_roleKey, response.role);
      if (response.teacherId != null) {
        await prefs.setString(_teacherIdKey, response.teacherId!);
      } else {
        await prefs.remove(_teacherIdKey);
      }

      HttpHelper().setDefaultHeaders({
        'Authorization': 'Bearer ${response.accessToken}',
      });

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        token: response.accessToken,
        userId: response.userId,
        userName: response.userName,
        role: response.role,
        teacherId: response.teacherId,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_teacherIdKey);

    HttpHelper().setDefaultHeaders({'Authorization': ''});

    state = const AuthState(isInitializing: false);
  }
}

final authServiceProvider = Provider<AuthService>((_) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);
