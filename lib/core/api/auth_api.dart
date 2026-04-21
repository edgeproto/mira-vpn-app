import 'package:dio/dio.dart';

import 'models/auth_response_dto.dart';
import 'models/user_dto.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthResponseDto> register({
    required String email,
    required String password,
    bool isPro = false,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: <String, dynamic>{
        'email': email,
        'password': password,
        'isPro': isPro,
      },
    );
    return AuthResponseDto.fromJson(res.data!);
  }

  Future<AuthResponseDto> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: <String, dynamic>{
        'email': email,
        'password': password,
      },
    );
    return AuthResponseDto.fromJson(res.data!);
  }

  Future<AuthResponseDto> socialGoogle({
    required String idToken,
    bool isPro = false,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/social/google',
      data: <String, dynamic>{
        'idToken': idToken,
        'isPro': isPro,
      },
    );
    return AuthResponseDto.fromJson(res.data!);
  }

  Future<AuthResponseDto> socialApple({
    required String idToken,
    bool isPro = false,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/social/apple',
      data: <String, dynamic>{
        'idToken': idToken,
        'isPro': isPro,
      },
    );
    return AuthResponseDto.fromJson(res.data!);
  }

  Future<UserDto> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/auth/me');
    return UserDto.fromJson(res.data!);
  }
}
