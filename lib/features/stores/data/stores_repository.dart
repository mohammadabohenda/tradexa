import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/store.dart';

class StoreOperationException implements Exception {
  final String message;
  StoreOperationException(this.message);
}

class StoresRepository {
  final SupabaseClient _client;
  static const _table = 'stores';

  StoresRepository(this._client);

  /// نجلب الشركات مع بياناتها الأساسية، ثم نجلب إحصائياتها من
  /// store_stats بنداء واحد إضافي وندمجهم بالذاكرة — استعلامان
  /// بسيطان وواضحان أفضل من استعلام معقّد واحد يصعب صيانته.
  Future<List<Store>> fetchAll({String? verticalId}) async {
    var query = _client.from(_table).select(
        '*, verticals(name), profiles!stores_owner_id_fkey(username, full_name)');

    if (verticalId != null) {
      query = query.eq('vertical_id', verticalId);
    }

    final data = await query.order('created_at', ascending: false);
    final stores = (data as List)
        .map((row) => Store.fromMap(row as Map<String, dynamic>))
        .toList();

    if (stores.isEmpty) return stores;

    final storeIds = stores.map((s) => s.id).toList();
    final statsData = await _client
        .from('store_stats')
        .select()
        .inFilter('store_id', storeIds);

    final statsMap = <String, Map<String, dynamic>>{
      for (final row in statsData as List) row['store_id'] as String: row as Map<String, dynamic>,
    };

    return stores.map((store) {
      final stats = statsMap[store.id];
      return store.copyWithStats(
        productsCount: (stats?['products_count'] as num?)?.toInt() ?? 0,
        ordersCount: (stats?['orders_count'] as num?)?.toInt() ?? 0,
        customersCount: (stats?['customers_count'] as num?)?.toInt() ?? 0,
        lastOrderAt: stats?['last_order_at'] != null
            ? DateTime.parse(stats!['last_order_at'] as String)
            : null,
      );
    }).toList();
  }

  Future<void> setActive(String storeId, bool isActive) async {
    try {
      await _client.from(_table).update({'is_active': isActive}).eq('id', storeId);
    } on PostgrestException catch (_) {
      throw StoreOperationException(
        isActive ? 'تعذّر تفعيل الشركة، حاول مرة أخرى' : 'تعذّر إيقاف الشركة، حاول مرة أخرى',
      );
    }
  }

  Future<void> delete(String storeId) async {
    try {
      await _client.from(_table).delete().eq('id', storeId);
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        throw StoreOperationException(
          'لا يمكن حذف هذه الشركة لوجود طلبات مرتبطة بها. '
          'يمكنك إيقافها بدل حذفها للاحتفاظ بسجل الطلبات.',
        );
      }
      throw StoreOperationException('تعذّر حذف الشركة، حاول مرة أخرى');
    }
  }

  /// تعديل بيانات الشركة الأساسية (الاسم، الشعار، الدولة).
  Future<void> updateDetails(
    String storeId, {
    required String name,
    String? logoUrl,
    String? country,
  }) async {
    try {
      await _client.from(_table).update({
        'name': name,
        'logo_url': logoUrl,
        'country': country,
      }).eq('id', storeId);
    } on PostgrestException catch (_) {
      throw StoreOperationException('تعذّر تعديل بيانات الشركة، حاول مرة أخرى');
    }
  }

  /// تغيير باقة الاشتراك ودورة الفوترة.
  Future<void> changePlan(
    String storeId, {
    required SubscriptionPlan plan,
    required BillingCycle cycle,
  }) async {
    try {
      await _client.from(_table).update({
        'subscription_plan': plan.value,
        'billing_cycle': cycle.value,
      }).eq('id', storeId);
    } on PostgrestException catch (_) {
      throw StoreOperationException('تعذّر تغيير الباقة، حاول مرة أخرى');
    }
  }

  Future<void> createStoreWithMerchant({
    required String storeName,
    required String verticalId,
    required String ownerUsername,
    required String ownerFullName,
    required String ownerPhone,
    required String ownerPassword,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'admin-create-store',
        body: {
          'store_name': storeName,
          'vertical_id': verticalId,
          'owner_username': ownerUsername,
          'owner_full_name': ownerFullName,
          'owner_phone': ownerPhone,
          'owner_password': ownerPassword,
        },
      );

      if (response.status != 200) {
        final error = (response.data is Map) ? response.data['error'] as String? : null;
        throw StoreOperationException(error ?? 'تعذّر إنشاء الشركة، حاول مرة أخرى');
      }
    } on StoreOperationException {
      rethrow;
    } on FunctionException catch (e) {
      final error = (e.details is Map) ? e.details['error'] as String? : null;
      throw StoreOperationException(error ?? 'تعذّر إنشاء الشركة، حاول مرة أخرى');
    } catch (_) {
      throw StoreOperationException('تعذّر إنشاء الشركة، تحقق من الاتصال وحاول مرة أخرى');
    }
  }

  /// تسجيل دخول كمشرف (Support Impersonation): نطلب من Edge Function
  /// رابط دخول مؤقت (Magic Link) لحساب صاحب الشركة، لمساعدته بمشكلة
  /// دون معرفة كلمة سره. هذا يُنفَّذ بصلاحية service_role على السيرفر
  /// فقط، ولازم يُسجَّل لاحقًا بـ Audit Log (ميزة قادمة).
  Future<String> generateSupportLoginLink(String ownerId) async {
    try {
      final response = await _client.functions.invoke(
        'admin-impersonate-user',
        body: {'user_id': ownerId},
      );

      if (response.status != 200) {
        final error = (response.data is Map) ? response.data['error'] as String? : null;
        throw StoreOperationException(error ?? 'تعذّر إنشاء رابط الدخول');
      }

      return response.data['link'] as String;
    } on StoreOperationException {
      rethrow;
    } catch (_) {
      throw StoreOperationException('تعذّر إنشاء رابط الدخول، حاول مرة أخرى');
    }
  }
}
