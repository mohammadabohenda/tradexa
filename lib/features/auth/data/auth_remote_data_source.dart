import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<String?> resolveEmailByUsername(String username);
  Future<String?> signInWithPassword({required String email, required String password});
  Future<String?> fetchUserRole(String userId);
  Future<void> signOut();
  bool get isSignedIn;
}

class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final SupabaseClient _client;
  SupabaseAuthRemoteDataSource(this._client);

  /// جدول profiles ما فيه عمود email — الإيميل موجود بجدول auth.users
  /// المحمي. كمان المستخدم لسا ما سجّل دخول هون (anon)، فما بيقدر يقرأ
  /// profiles بسبب RLS. الحل هو دالة get_email_by_username المعرّفة
  /// بقاعدة البيانات كـ SECURITY DEFINER، فبتقدر تعمل الترجمة بأمان
  /// قبل تسجيل الدخول.
  @override
  Future<String?> resolveEmailByUsername(String username) async {
    try {
      final email = await _client.rpc(
        'get_email_by_username',
        params: {'input_username': username},
      );
      return email as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response =
        await _client.auth.signInWithPassword(email: email, password: password);
    return response.user?.id;
  }

  @override
  Future<String?> fetchUserRole(String userId) async {
    final profile = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    return profile?['role'] as String?;
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  bool get isSignedIn => _client.auth.currentUser != null;
}
