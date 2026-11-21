import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tradexa_admin/features/auth/bloc/auth_bloc.dart';
import 'package:tradexa_admin/features/auth/bloc/auth_event.dart';
import 'package:tradexa_admin/features/auth/bloc/auth_state.dart';
import 'package:tradexa_admin/features/auth/data/auth_remote_data_source.dart';
import 'package:tradexa_admin/features/auth/data/auth_repository.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late MockAuthRemoteDataSource mockRemote;
  late AuthRepository repository;

  setUp(() {
    mockRemote = MockAuthRemoteDataSource();
    repository = AuthRepository(mockRemote);
  });

  blocTest<AuthBloc, AuthState>(
    'يصدر [AuthLoading, AuthSuccess] عند بيانات صحيحة لـ platform_admin',
    setUp: () {
      when(() => mockRemote.resolveEmailByUsername(any()))
          .thenAnswer((_) async => 'admin@tradexa.internal');
      when(() => mockRemote.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => 'admin-id');
      when(() => mockRemote.fetchUserRole(any())).thenAnswer((_) async => 'platform_admin');
    },
    build: () => AuthBloc(repository),
    act: (bloc) => bloc.add(
      const AuthLoginRequested(username: 'admin', password: 'correctPassword'),
    ),
    expect: () => [const AuthLoading(), const AuthSuccess()],
  );

  blocTest<AuthBloc, AuthState>(
    'يصدر [AuthFailure] فورًا بدون نداء الشبكة إذا كانت الحقول فارغة',
    build: () => AuthBloc(repository),
    act: (bloc) => bloc.add(const AuthLoginRequested(username: '', password: '')),
    expect: () => [const AuthFailure('الرجاء إدخال اسم المستخدم وكلمة السر')],
    verify: (_) {
      verifyNever(() => mockRemote.resolveEmailByUsername(any()));
    },
  );
}
