import 'package:equatable/equatable.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();
  @override
  List<Object?> get props => [];
}

class OrdersRequested extends OrdersEvent {
  const OrdersRequested();
}

class OrdersStatusFilterChanged extends OrdersEvent {
  final OrderStatus? status;
  const OrdersStatusFilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}

class ManualOrderCreated extends OrdersEvent {
  final String customerName;
  final String customerPhone;
  final String? customerAddress;
  final String? notes;
  final List<NewOrderLine> lines;
  final void Function(String? error) onComplete;

  const ManualOrderCreated({
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.notes,
    required this.lines,
    required this.onComplete,
  });

  @override
  List<Object?> get props => [customerName, customerPhone, lines.length];
}

class OrderStatusChanged extends OrdersEvent {
  final String orderId;
  final OrderStatus status;
  final void Function(String? error) onComplete;

  const OrderStatusChanged(this.orderId, this.status, this.onComplete);

  @override
  List<Object?> get props => [orderId, status];
}

class OrderDeleted extends OrdersEvent {
  final String orderId;
  final void Function(String? error) onComplete;

  const OrderDeleted(this.orderId, this.onComplete);

  @override
  List<Object?> get props => [orderId];
}
