import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/auth_api.dart';
import '../../core/api/models/user_dto.dart';
import '../../core/providers/dependency_providers.dart';
import '../../core/storage/token_store.dart';

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
  });

  final UserDto? user;
  final bool isLoading;

  bool get isSignedIn => user != null;
}

class AuthController extends Notifier<AuthState> {
  AuthApi get _auth => ref.read(authApiProvider);
  TokenStore get _tokens => ref.read(tokenStoreProvider);

  @override
  AuthState build() {
    Future.microtask(_hydrate);
    return const AuthState(isLoading: true, user: null);
  }

  Future<void> _hydrate() async {
    state = const AuthState(isLoading: true, user: null);
    final token = await _tokens.read();
    if (token == null || token.isEmpty) {
      state = const AuthState(isLoading: false, user: null);
      return;
    }
    try {
      final user = await _auth.me();
      state = AuthState(isLoading: false, user: user);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final api = ApiException.fromDio(e);
      if (code == 401 || code == 403) {
        await _tokens.delete();
      }
      if (kDebugMode && api != null) {
        debugPrint('Auth hydrate failed: ${api.message}');
      }
      state = const AuthState(isLoading: false, user: null);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Auth hydrate failed: $e\n$st');
      }
      state = const AuthState(isLoading: false, user: null);
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthState(isLoading: true, user: state.user);
    try {
      final res = await _auth.login(email: email, password: password);
      await _tokens.write(res.token);
      state = AuthState(isLoading: false, user: res.user);
    } catch (e, st) {
      state = const AuthState(isLoading: false, user: null);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    bool isPro = false,
  }) async {
    state = AuthState(isLoading: true, user: state.user);
    try {
      final res = await _auth.register(
        email: email,
        password: password,
        isPro: isPro,
      );
      await _tokens.write(res.token);
      state = AuthState(isLoading: false, user: res.user);
    } catch (e, st) {
      state = const AuthState(isLoading: false, user: null);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> signOut() async {
    await _tokens.delete();
    state = const AuthState(isLoading: false, user: null);
  }
}
