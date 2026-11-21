/// ملخّص الأرباح العام.
///
/// نفرّق بين "المحقّق" (طلبات تم تسليمها فعليًا) و"المتوقّع" (كل
/// الطلبات ما عدا الملغي). الفرق بينهم مهم: طلب قيد الانتظار مش
/// ربح بالجيب بعد.
class ProfitSummary {
  final double realizedRevenue;
  final double realizedProfit;
  final double expectedRevenue;
  final double expectedProfit;
  final int ordersDelivered;
  final int ordersPending;
  final int unitsSold;

  const ProfitSummary({
    required this.realizedRevenue,
    required this.realizedProfit,
    required this.expectedRevenue,
    required this.expectedProfit,
    required this.ordersDelivered,
    required this.ordersPending,
    required this.unitsSold,
  });

  static const empty = ProfitSummary(
    realizedRevenue: 0,
    realizedProfit: 0,
    expectedRevenue: 0,
    expectedProfit: 0,
    ordersDelivered: 0,
    ordersPending: 0,
    unitsSold: 0,
  );

  /// هامش الربح كنسبة من الإيراد المحقّق.
  double get realizedMarginPercent =>
      realizedRevenue > 0 ? (realizedProfit / realizedRevenue) * 100 : 0;

  /// الربح اللي لسا معلّق بطلبات ما تسلّمت.
  double get pendingProfit => expectedProfit - realizedProfit;

  factory ProfitSummary.fromMap(Map<String, dynamic> map) {
    double num_(String key) => (map[key] as num?)?.toDouble() ?? 0;
    int int_(String key) => (map[key] as num?)?.toInt() ?? 0;

    return ProfitSummary(
      realizedRevenue: num_('realized_revenue'),
      realizedProfit: num_('realized_profit'),
      expectedRevenue: num_('expected_revenue'),
      expectedProfit: num_('expected_profit'),
      ordersDelivered: int_('orders_delivered'),
      ordersPending: int_('orders_pending'),
      unitsSold: int_('units_sold'),
    );
  }
}

/// إحصائيات منتج واحد.
class ProductStat {
  final String productId;
  final String productName;
  final String? imageUrl;
  final double sellingPrice;
  final double originalPrice;
  final int unitsSold;
  final double revenue;
  final double profit;
  final int ordersCount;

  const ProductStat({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.sellingPrice,
    required this.originalPrice,
    required this.unitsSold,
    required this.revenue,
    required this.profit,
    required this.ordersCount,
  });

  double get unitProfit => sellingPrice - originalPrice;

  factory ProductStat.fromMap(Map<String, dynamic> map) {
    return ProductStat(
      productId: map['product_id'] as String,
      productName: map['product_name'] as String? ?? '—',
      imageUrl: map['image_url'] as String?,
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0,
      originalPrice: (map['original_price'] as num?)?.toDouble() ?? 0,
      unitsSold: (map['units_sold'] as num?)?.toInt() ?? 0,
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0,
      profit: (map['profit'] as num?)?.toDouble() ?? 0,
      ordersCount: (map['orders_count'] as num?)?.toInt() ?? 0,
    );
  }
}
