import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/product.dart';

class ProductOperationException implements Exception {
  final String message;
  ProductOperationException(this.message);
}

class ProductsRepository {
  final SupabaseClient _client;
  static const _table = 'products';

  ProductsRepository(this._client);

  /// جلب كل المنتجات أو فلترة حسب قطاع معين
  Future<List<Product>> fetchAll({String? verticalId}) async {
    try {
      // جلب المنتجات فقط (بدون JOIN)
      var query = _client.from(_table).select();

      if (verticalId != null) {
        query = query.eq('vertical_id', verticalId);
      }

      final data = await query.order('created_at', ascending: false);
      
      if ((data as List).isEmpty) {
        return [];
      }

      // جلب أسماء الأقطاع
      final verticalIds = (data as List)
          .map((row) => (row as Map)['vertical_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      Map<String, String> verticalNames = {};
      if (verticalIds.isNotEmpty) {
        try {
          final verticals = await _client
              .from('verticals')
              .select('id, name')
              .inFilter('id', verticalIds);
          
          for (final v in verticals as List) {
            verticalNames[v['id'] as String] = v['name'] as String;
          }
        } catch (e) {
          print('Error fetching verticals: $e');
        }
      }

      // دمج البيانات
      return (data as List).map((row) {
        final map = row as Map<String, dynamic>;
        final vid = map['vertical_id'] as String?;
        map['verticals'] = {
          'name': verticalNames[vid] ?? '—'
        };
        return Product.fromMap(map);
      }).toList();
    } catch (e) {
      print('Error in fetchAll: $e');
      rethrow;
    }
  }

  /// إضافة منتج جديد — بترجع معرّفه عشان نربط أصنافه بعدها
  Future<String> create({
    required String verticalId,
    required String name,
    required double originalPrice,
    required double sellingPrice,
    String? description,
    String? imageUrl,
  }) async {
    if (name.trim().isEmpty) {
      throw ProductOperationException('اسم المنتج مطلوب');
    }
    if (originalPrice < 0 || sellingPrice < 0) {
      throw ProductOperationException('الأسعار لا يمكن أن تكون سالبة');
    }

    try {
      final inserted = await _client
          .from(_table)
          .insert({
            'vertical_id': verticalId,
            'name': name.trim(),
            'description': description?.trim(),
            'image_url': imageUrl?.trim(),
            'original_price': originalPrice,
            'selling_price': sellingPrice,
          })
          .select('id')
          .single();
      return inserted['id'] as String;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw ProductOperationException('منتج بنفس الاسم موجود بالفعل');
      }
      throw ProductOperationException('تعذّر إضافة المنتج، حاول مرة أخرى');
    }
  }

  /// تعديل منتج موجود
  Future<void> update(
    String productId, {
    required String name,
    required double originalPrice,
    required double sellingPrice,
    String? description,
    String? imageUrl,
  }) async {
    if (name.trim().isEmpty) {
      throw ProductOperationException('اسم المنتج مطلوب');
    }
    if (originalPrice < 0 || sellingPrice < 0) {
      throw ProductOperationException('الأسعار لا يمكن أن تكون سالبة');
    }

    try {
      await _client.from(_table).update({
        'name': name.trim(),
        'description': description?.trim(),
        'image_url': imageUrl?.trim(),
        'original_price': originalPrice,
        'selling_price': sellingPrice,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', productId);
    } on PostgrestException catch (_) {
      throw ProductOperationException('تعذّر تعديل المنتج، حاول مرة أخرى');
    }
  }

  /// حذف منتج
  Future<void> delete(String productId) async {
    try {
      await _client.from(_table).delete().eq('id', productId);
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        throw ProductOperationException(
          'لا يمكن حذف هذا المنتج — يوجد طلبات مرتبطة به.',
        );
      }
      throw ProductOperationException('تعذّر حذف المنتج، حاول مرة أخرى');
    }
  }

  /// تفعيل/تعطيل المنتج
  Future<void> setActive(String productId, bool isActive) async {
    try {
      await _client.from(_table).update({'is_active': isActive}).eq('id', productId);
    } on PostgrestException catch (_) {
      throw ProductOperationException('تعذّر تحديث حالة المنتج، حاول مرة أخرى');
    }
  }
}
