import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/stats.dart';

class StatsException implements Exception {
  final String message;
  StatsException(this.message);
}

class StatsRepository {
  final SupabaseClient _client;

  StatsRepository(this._client);

  Future<ProfitSummary> fetchSummary() async {
    try {
      final data = await _client.rpc('get_profit_summary');

      // الدالة بترجع صفًا واحدًا داخل قائمة
      if (data is List && data.isNotEmpty) {
        return ProfitSummary.fromMap(data.first as Map<String, dynamic>);
      }
      return ProfitSummary.empty;
    } catch (_) {
      throw StatsException('تعذّر تحميل ملخّص الأرباح');
    }
  }

  /// المنتجات مرتّبة حسب المعيار المطلوب. نستثني المنتجات اللي ما
  /// انباعت ولا مرة عشان القائمة تضل مفيدة.
  Future<List<ProductStat>> fetchTopProducts({
    required StatsSortBy sortBy,
    int limit = 10,
  }) async {
    try {
      final data = await _client
          .from('product_sales_stats')
          .select()
          .gt('units_sold', 0)
          .order(sortBy.column, ascending: false)
          .limit(limit);

      return (data as List)
          .map((row) => ProductStat.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw StatsException('تعذّر تحميل إحصائيات المنتجات');
    }
  }
}

enum StatsSortBy {
  unitsSold('units_sold', 'الأكثر طلبًا'),
  profit('profit', 'الأعلى ربحًا'),
  revenue('revenue', 'الأعلى مبيعًا');

  final String column;
  final String label;
  const StatsSortBy(this.column, this.label);
}
