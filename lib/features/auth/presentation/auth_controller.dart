
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/supabase/supabase_config.dart';
import '../data/auth_remote_data_source.dart';
import '../data/auth_repository.dart';
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(SupabaseAuthRemoteDataSource(SupabaseConfig.client));
});

/// حالة شاشة تسجيل الدخول — تُعبّر بوضوح عن كل الحالات الممكنة
/// بدل استخدام Booleans متفرقة (isLoading, hasError...) بشكل منفصل.
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  const AuthSuccess();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthInitial());

  Future<void> login({required String username, required String password}) async {
    if (username.trim().isEmpty || password.isEmpty) {
      state = const AuthError('الرجاء إدخال اسم المستخدم وكلمة السر');
      return;
    }

    state = const AuthLoading();
    try {
      await _repository.signInWithUsername(
        username: username.trim(),
        password: password,
      );
      state = const AuthSuccess();
    } on LoginException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      print(e);
      state = const AuthError('حدث خطأ غير متوقع، حاول مرة أخرى');
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
