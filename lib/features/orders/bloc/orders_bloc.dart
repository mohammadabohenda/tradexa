import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';
import 'orders_event.dart';
import 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrdersRepository _repository;
  OrderStatus? _currentFilter;

  OrdersBloc(this._repository) : super(const OrdersLoading()) {
    on<OrdersRequested>(_onRequested);
    on<OrdersStatusFilterChanged>(_onFilterChanged);
    on<ManualOrderCreated>(_onManualCreated);
    on<OrderStatusChanged>(_onStatusChanged);
    on<OrderDeleted>(_onDeleted);

    add(const OrdersRequested());
  }

  Future<void> _onRequested(OrdersRequested event, Emitter<OrdersState> emit) async {
    emit(const OrdersLoading());
    try {
      final list = await _repository.fetchAll(status: _currentFilter);
      emit(OrdersLoaded(list, activeFilter: _currentFilter));
    } catch (_) {
      emit(const OrdersError('تعذّر تحميل الطلبات، تحقق من الاتصال'));
    }
  }

  Future<void> _onFilterChanged(
    OrdersStatusFilterChanged event,
    Emitter<OrdersState> emit,
  ) async {
    _currentFilter = event.status;
    await _onRequested(const OrdersRequested(), emit);
  }

  Future<void> _onManualCreated(
    ManualOrderCreated event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      await _repository.createManualOrder(
        customerName: event.customerName,
        customerPhone: event.customerPhone,
        customerAddress: event.customerAddress,
        notes: event.notes,
        lines: event.lines,
      );
      event.onComplete(null);
      await _onRequested(const OrdersRequested(), emit);
    } on OrderOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onStatusChanged(
    OrderStatusChanged event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      await _repository.updateStatus(event.orderId, event.status);
      event.onComplete(null);
      await _onRequested(const OrdersRequested(), emit);
    } on OrderOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onDeleted(OrderDeleted event, Emitter<OrdersState> emit) async {
    try {
      await _repository.delete(event.orderId);
      event.onComplete(null);
      await _onRequested(const OrdersRequested(), emit);
    } on OrderOperationException catch (e) {
      event.onComplete(e.message);
    }
  }
}
