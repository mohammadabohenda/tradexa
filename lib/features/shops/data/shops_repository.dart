import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/shop.dart';

class ShopOperationException implements Exception {
  final String message;
  ShopOperationException(this.message);
}

class ShopsRepository {
  final SupabaseClient _client;

  ShopsRepository(this._client);

  Future<List<Shop>> fetchAll() async {
    final data = await _client
        .from('shops')
        .select('*, profiles(username, full_name), products(id), orders(id)')
        .order('created_at', ascending: false);

    return (data as List)
        .map((r) => Shop.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// إنشاء المحل وحساب صاحبه يمر عبر Edge Function — إنشاء مستخدم
  /// مصادقة بيحتاج service_role وما بينعمل من التطبيق.
  Future<String> createShop(NewShopRequest request) async {
    try {
      final response = await _client.functions.invoke(
        'admin-create-shop',
        body: request.toBody(),
      );

      if (response.status != 200) {
        final error =
            (response.data is Map) ? response.data['error'] as String? : null;
        throw ShopOperationException(error ?? 'تعذّر إنشاء المحل');
      }

      return response.data['slug'] as String;
    } on ShopOperationException {
      rethrow;
    } on FunctionException catch (e) {
      final error = (e.details is Map) ? e.details['error'] as String? : null;
      throw ShopOperationException(error ?? 'تعذّر إنشاء المحل');
    } catch (_) {
      throw ShopOperationException('تعذّر إنشاء المحل، تحقق من الاتصال');
    }
  }

  Future<void> setActive(String shopId, bool isActive) async {
    try {
      await _client.from('shops').update({'is_active': isActive}).eq('id', shopId);
    } on PostgrestException catch (_) {
      throw ShopOperationException('تعذّر تحديث حالة المحل');
    }
  }

  Future<void> delete(String shopId) async {
    try {
      await _client.from('shops').delete().eq('id', shopId);
    } on PostgrestException catch (_) {
      throw ShopOperationException(
        'تعذّر حذف المحل — أوقفه بدل ما تحذفه للاحتفاظ بالطلبات',
      );
    }
  }
}
