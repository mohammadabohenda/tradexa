import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.username.trim().isEmpty || event.password.isEmpty) {
      emit(const AuthFailure('الرجاء إدخال اسم المستخدم وكلمة السر'));
      return;
    }

    emit(const AuthLoading());
    try {
      await _repository.signInWithUsername(
        username: event.username.trim(),
        password: event.password,
      );
      emit(const AuthSuccess());
    } on LoginException catch (e) {
      emit(AuthFailure(e.message));
    } catch (_) {
      emit(const AuthFailure('حدث خطأ غير متوقع، حاول مرة أخرى'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.signOut();
    emit(const AuthInitial());
  }
}
