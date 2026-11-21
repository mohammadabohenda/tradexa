import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/category.dart';

class CategoryOperationException implements Exception {
  final String message;
  CategoryOperationException(this.message);
}

class CategoriesRepository {
  final SupabaseClient _client;
  static const _table = 'categories';

  CategoriesRepository(this._client);

  Future<List<Category>> fetchAll({String? verticalId}) async {
    var query = _client
        .from(_table)
        .select('*, verticals(name), product_categories(product_id)');

    if (verticalId != null) {
      query = query.eq('vertical_id', verticalId);
    }

    final data = await query.order('sort_order').order('name');

    return (data as List)
        .map((row) => Category.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String verticalId,
    required String name,
    int sortOrder = 0,
  }) async {
    if (name.trim().isEmpty) {
      throw CategoryOperationException('اسم الصنف مطلوب');
    }

    try {
      await _client.from(_table).insert({
        'vertical_id': verticalId,
        'name': name.trim(),
        'sort_order': sortOrder,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw CategoryOperationException('في صنف بنفس الاسم داخل هذا القطاع');
      }
      throw CategoryOperationException('تعذّر إضافة الصنف، حاول مرة أخرى');
    }
  }

  Future<void> update(
    String categoryId, {
    required String name,
    required int sortOrder,
  }) async {
    if (name.trim().isEmpty) {
      throw CategoryOperationException('اسم الصنف مطلوب');
    }

    try {
      await _client.from(_table).update({
        'name': name.trim(),
        'sort_order': sortOrder,
      }).eq('id', categoryId);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw CategoryOperationException('في صنف بنفس الاسم داخل هذا القطاع');
      }
      throw CategoryOperationException('تعذّر تعديل الصنف، حاول مرة أخرى');
    }
  }

  Future<void> setActive(String categoryId, bool isActive) async {
    try {
      await _client.from(_table).update({'is_active': isActive}).eq('id', categoryId);
    } on PostgrestException catch (_) {
      throw CategoryOperationException('تعذّر تحديث حالة الصنف');
    }
  }

  /// حذف الصنف بيحذف روابطه بالمنتجات تلقائيًا (ON DELETE CASCADE)
  /// بس المنتجات نفسها بتضل موجودة.
  Future<void> delete(String categoryId) async {
    try {
      await _client.from(_table).delete().eq('id', categoryId);
    } on PostgrestException catch (_) {
      throw CategoryOperationException('تعذّر حذف الصنف، حاول مرة أخرى');
    }
  }

  /// أصناف منتج معيّن — للتعبئة المسبقة بنموذج التعديل.
  Future<List<String>> fetchProductCategoryIds(String productId) async {
    final data = await _client
        .from('product_categories')
        .select('category_id')
        .eq('product_id', productId);

    return (data as List).map((r) => r['category_id'] as String).toList();
  }

  /// استبدال كامل لأصناف المنتج بمعاملة وحدة.
  Future<void> setProductCategories(
    String productId,
    List<String> categoryIds,
  ) async {
    try {
      await _client.rpc('set_product_categories', params: {
        'p_product_id': productId,
        'p_category_ids': categoryIds,
      });
    } catch (_) {
      throw CategoryOperationException('تعذّر حفظ أصناف المنتج');
    }
  }
}
