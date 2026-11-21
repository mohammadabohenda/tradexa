import 'package:equatable/equatable.dart';
import '../domain/order.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;
  final OrderStatus? activeFilter;

  const OrdersLoaded(this.orders, {this.activeFilter});

  /// إجمالي قيمة الطلبات المعروضة — يستثني الملغي لأنه ما بيمثّل
  /// إيرادًا فعليًا.
  double get displayedTotal => orders
      .where((o) => o.status != OrderStatus.cancelled)
      .fold(0, (sum, o) => sum + o.total);

  @override
  List<Object?> get props => [orders, activeFilter];
}

class OrdersError extends OrdersState {
  final String message;
  const OrdersError(this.message);

  @override
  List<Object?> get props => [message];
}
