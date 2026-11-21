import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/app_user.dart';

class UserOperationException implements Exception {
  final String message;
  UserOperationException(this.message);
}

class UsersRepository {
  final SupabaseClient _client;
  static const _table = 'profiles';

  UsersRepository(this._client);

  Future<List<AppUser>> fetchAll({UserRole? role, String? search}) async {
    var query = _client.from(_table).select();

    if (role != null) query = query.eq('role', role.value);
    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim()}%';
      query = query.or('full_name.ilike.$term,username.ilike.$term,phone.ilike.$term');
    }

    final data = await query.order('created_at', ascending: false);

    return (data as List)
        .map((row) => AppUser.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// إنشاء الحساب يمر عبر Edge Function — إنشاء مستخدم مصادقة
  /// يحتاج service_role وما بينعمل من التطبيق مباشرة.
  Future<void> createUser({
    required String username,
    required String fullName,
    required String password,
    String? phone,
    required UserRole role,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'admin-create-user',
        body: {
          'username': username,
          'full_name': fullName,
          'password': password,
          'phone': phone,
          'role': role.value,
        },
      );

      if (response.status != 200) {
        final error = (response.data is Map) ? response.data['error'] as String? : null;
        throw UserOperationException(error ?? 'تعذّر إنشاء المستخدم');
      }
    } on UserOperationException {
      rethrow;
    } on FunctionException catch (e) {
      final error = (e.details is Map) ? e.details['error'] as String? : null;
      throw UserOperationException(error ?? 'تعذّر إنشاء المستخدم');
    } catch (_) {
      throw UserOperationException('تعذّر إنشاء المستخدم، تحقق من الاتصال');
    }
  }

  Future<void> updateDetails(
    String userId, {
    required String fullName,
    String? phone,
  }) async {
    try {
      await _client.from(_table).update({
        'full_name': fullName.trim(),
        'phone': phone?.trim(),
      }).eq('id', userId);
    } on PostgrestException catch (_) {
      throw UserOperationException('تعذّر تعديل بيانات المستخدم');
    }
  }

  Future<void> setActive(String userId, bool isActive) async {
    try {
      await _client.from(_table).update({'is_active': isActive}).eq('id', userId);
    } on PostgrestException catch (_) {
      throw UserOperationException('تعذّر تحديث حالة المستخدم');
    }
  }

  /// إبطال الرمز القديم وتوليد بديل — يُستعمل لو تسرّب الباركود.
  /// الرمز القديم بيصير غير صالح فورًا.
  Future<String> regenerateToken(String userId) async {
    try {
      final newToken = await _client.rpc('generate_access_token');

      await _client.from(_table).update({
        'access_token': newToken,
        'token_issued_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      return newToken as String;
    } on PostgrestException catch (_) {
      throw UserOperationException('تعذّر توليد رمز جديد');
    }
  }
}
