/// حالات الطلب — مرتبة حسب دورة الحياة الطبيعية.
enum OrderStatus {
  pending('pending', 'قيد الانتظار'),
  confirmed('confirmed', 'مؤكّد'),
  shipped('shipped', 'قيد التوصيل'),
  delivered('delivered', 'تم التسليم'),
  cancelled('cancelled', 'ملغي');

  final String value;
  final String label;
  const OrderStatus(this.value, this.label);

  static OrderStatus fromValue(String? value) {
    return OrderStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => OrderStatus.pending,
    );
  }

  /// الحالات اللي بيقدر الطلب ينتقل لها من الحالة الحالية.
  /// الطلب المسلَّم أو الملغي نهائي — ما بينتقل لحالة تانية.
  List<OrderStatus> get allowedNext {
    switch (this) {
      case OrderStatus.pending:
        return [OrderStatus.confirmed, OrderStatus.cancelled];
      case OrderStatus.confirmed:
        return [OrderStatus.shipped, OrderStatus.cancelled];
      case OrderStatus.shipped:
        return [OrderStatus.delivered, OrderStatus.cancelled];
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return [];
    }
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String? productImageUrl;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => quantity * unitPrice;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    final productData = map['products'] as Map<String, dynamic>?;

    return OrderItem(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: productData?['name'] as String? ?? 'منتج محذوف',
      productImageUrl: productData?['image_url'] as String?,
      quantity: (map['quantity'] as num).toInt(),
      unitPrice: (map['unit_price'] as num).toDouble(),
    );
  }
}

class Order {
  final String id;
  final String customerName;
  final String customerPhone;
  final String? customerAddress;
  final String? notes;
  final OrderStatus status;
  final double total;
  final DateTime createdAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.notes,
    required this.status,
    required this.total,
    required this.createdAt,
    this.items = const [],
  });

  int get itemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  factory Order.fromMap(Map<String, dynamic> map) {
    final itemsData = map['order_items'] as List?;

    return Order(
      id: map['id'] as String,
      customerName: map['customer_name'] as String? ?? '—',
      customerPhone: map['customer_phone'] as String? ?? '—',
      customerAddress: map['customer_address'] as String?,
      notes: map['notes'] as String?,
      status: OrderStatus.fromValue(map['status'] as String?),
      // العمود بقاعدة البيانات اسمه total_amount مش total
      total: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
      items: itemsData
              ?.map((row) => OrderItem.fromMap(row as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
