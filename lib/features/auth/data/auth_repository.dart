import 'auth_remote_data_source.dart';

class LoginException implements Exception {
  final String message;
  LoginException(this.message);
}

class AuthRepository {
  final AuthRemoteDataSource _remote;

  AuthRepository(this._remote);

  Future<void> signInWithUsername({
    required String username,
    required String password,
  }) async {
    final email = await _safeResolveEmail(username);

    if (email == null) {
      throw LoginException('اسم المستخدم أو كلمة السر غير صحيحة');
    }

    try {
      final userId = await _remote.signInWithPassword(email: email, password: password);

      if (userId == null) {
        throw LoginException('اسم المستخدم أو كلمة السر غير صحيحة');
      }

      await _verifyIsPlatformAdmin(userId);
    } on LoginException {
      rethrow;
    } catch (_) {
      throw LoginException('اسم المستخدم أو كلمة السر غير صحيحة');
    }
  }

  Future<String?> _safeResolveEmail(String username) async {
    try {
      return await _remote.resolveEmailByUsername(username);
    } catch (_) {
      return null;
    }
  }

  Future<void> _verifyIsPlatformAdmin(String userId) async {
    final role = await _remote.fetchUserRole(userId);
    if (role != 'platform_admin') {
      await _remote.signOut();
      throw LoginException('هذا الحساب غير مصرّح له بالدخول لهذا التطبيق');
    }
  }

  Future<void> signOut() => _remote.signOut();

  bool get isSignedIn => _remote.isSignedIn;
}
