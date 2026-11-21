import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  group('AuthRepository.signInWithUsername', () {
    test('يرفض برسالة عامة عندما لا يوجد مستخدم بهذا الاسم', () async {
      when(() => mockRemote.resolveEmailByUsername(any()))
          .thenAnswer((_) async => null);

      await expectLater(
        repository.signInWithUsername(username: 'not_existing_user', password: 'anyPassword'),
        throwsA(isA<LoginException>().having(
          (e) => e.message,
          'message',
          'اسم المستخدم أو كلمة السر غير صحيحة',
        )),
      );
    });

    test('يرفض الدخول لمستخدم موجود لكن ليس platform_admin', () async {
      when(() => mockRemote.resolveEmailByUsername(any()))
          .thenAnswer((_) async => 'buyer_internal@tradexa.internal');
      when(() => mockRemote.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => 'user-id-123');
      when(() => mockRemote.fetchUserRole(any())).thenAnswer((_) async => 'buyer');
      when(() => mockRemote.signOut()).thenAnswer((_) async {});

      await expectLater(
        repository.signInWithUsername(username: 'some_buyer', password: 'correctPassword'),
        throwsA(isA<LoginException>().having(
          (e) => e.message,
          'message',
          'هذا الحساب غير مصرّح له بالدخول لهذا التطبيق',
        )),
      );

      verify(() => mockRemote.signOut()).called(1);
    });
  });
}
