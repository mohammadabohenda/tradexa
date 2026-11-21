import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/vertical.dart';

class VerticalOperationException implements Exception {
  final String message;
  VerticalOperationException(this.message);
}

class VerticalsRepository {
  final SupabaseClient _client;
  static const _table = 'verticals';

  VerticalsRepository(this._client);

  Future<List<Vertical>> fetchAll() async {
    final data =
        await _client.from(_table).select().order('created_at', ascending: false);

    return (data as List)
        .map((row) => Vertical.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> create(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw VerticalOperationException('اسم القطاع لا يمكن أن يكون فارغًا');
    }

    try {
      await _client.from(_table).insert({
        'name': trimmed,
        'slug': generateSlug(trimmed),
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw VerticalOperationException('يوجد قطاع بنفس الاسم مسبقًا');
      }
      throw VerticalOperationException('تعذّر إنشاء القطاع، حاول مرة أخرى');
    }
  }

  Future<void> updateName(String id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw VerticalOperationException('اسم القطاع لا يمكن أن يكون فارغًا');
    }

    try {
      await _client.from(_table).update({'name': trimmed}).eq('id', id);
    } on PostgrestException catch (_) {
      throw VerticalOperationException('تعذّر تعديل اسم القطاع، حاول مرة أخرى');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        throw VerticalOperationException(
          'لا يمكن حذف هذا القطاع لأنه يحتوي على متاجر مرتبطة به. '
          'قم بحذف أو نقل المتاجر أولًا.',
        );
      }
      throw VerticalOperationException('تعذّر حذف القطاع، حاول مرة أخرى');
    }
  }
}
