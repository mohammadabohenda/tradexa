import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/order.dart';

class OrderOperationException implements Exception {
  final String message;
  OrderOperationException(this.message);
}

/// سطر واحد بالطلب وقت الإنشاء — قبل ما ينحفظ بقاعدة البيانات.
class NewOrderLine {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  const NewOrderLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => quantity * unitPrice;
}

class OrdersRepository {
  final SupabaseClient _client;

  OrdersRepository(this._client);

  Future<List<Order>> fetchAll({OrderStatus? status}) async {
    var query =
        _client.from('orders').select('*, order_items(*, products(name, image_url))');

    if (status != null) {
      query = query.eq('status', status.value);
    }

    final data = await query.order('created_at', ascending: false);

    return (data as List)
        .map((row) => Order.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// إنشاء طلب يدوي: نحفظ رأس الطلب أولاً للحصول على معرّفه، ثم
  /// نحفظ الأسطر. لو فشل حفظ الأسطر نحذف رأس الطلب عشان ما يضل
  /// طلب فاضي بقاعدة البيانات.
  Future<void> createManualOrder({
    required String customerName,
    required String customerPhone,
    String? customerAddress,
    String? notes,
    required List<NewOrderLine> lines,
  }) async {
    if (customerName.trim().isEmpty) {
      throw OrderOperationException('اسم العميل مطلوب');
    }
    if (customerPhone.trim().isEmpty) {
      throw OrderOperationException('رقم هاتف العميل مطلوب');
    }
    if (lines.isEmpty) {
      throw OrderOperationException('أضف منتجًا واحدًا على الأقل للطلب');
    }

    final total = lines.fold<double>(0, (sum, line) => sum + line.lineTotal);
    String? createdOrderId;

    try {
      final inserted = await _client
          .from('orders')
          .insert({
            'customer_name': customerName.trim(),
            'customer_phone': customerPhone.trim(),
            'customer_address': customerAddress?.trim(),
            'notes': notes?.trim(),
            'status': OrderStatus.pending.value,
            'total_amount': total,
            'is_manual': true,
          })
          .select('id')
          .single();

      createdOrderId = inserted['id'] as String;

      await _client.from('order_items').insert(lines
          .map((line) => {
                'order_id': createdOrderId,
                'product_id': line.productId,
                'quantity': line.quantity,
                'unit_price': line.unitPrice,
              })
          .toList());
    } on PostgrestException catch (e) {
      if (createdOrderId != null) {
        // تراجع: نحذف رأس الطلب عشان ما يضل طلب بدون أسطر.
        await _client.from('orders').delete().eq('id', createdOrderId);
      }
      throw OrderOperationException(
        e.message.contains('permission')
            ? 'ليس لديك صلاحية إنشاء طلبات'
            : 'تعذّر إنشاء الطلب، حاول مرة أخرى',
      );
    } catch (_) {
      if (createdOrderId != null) {
        await _client.from('orders').delete().eq('id', createdOrderId);
      }
      throw OrderOperationException('تعذّر إنشاء الطلب، تحقق من الاتصال');
    }
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    try {
      await _client.from('orders').update({'status': status.value}).eq('id', orderId);
    } on PostgrestException catch (_) {
      throw OrderOperationException('تعذّر تحديث حالة الطلب، حاول مرة أخرى');
    }
  }

  /// الأسطر بتنحذف تلقائيًا عبر ON DELETE CASCADE بقاعدة البيانات.
  Future<void> delete(String orderId) async {
    try {
      await _client.from('orders').delete().eq('id', orderId);
    } on PostgrestException catch (_) {
      throw OrderOperationException('تعذّر حذف الطلب، حاول مرة أخرى');
    }
  }
}
