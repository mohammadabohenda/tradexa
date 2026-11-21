import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/stores_repository.dart';
import 'stores_event.dart';
import 'stores_state.dart';

class StoresBloc extends Bloc<StoresEvent, StoresState> {
  final StoresRepository _repository;
  String? _currentVerticalFilter;

  StoresBloc(this._repository) : super(const StoresLoading()) {
    on<StoresRequested>(_onRequested);
    on<StoresVerticalFilterChanged>(_onFilterChanged);
    on<StoreCreated>(_onCreated);
    on<StoreActiveToggled>(_onActiveToggled);
    on<StoreDeleted>(_onDeleted);
    on<StoreDetailsUpdated>(_onDetailsUpdated);
    on<StorePlanChanged>(_onPlanChanged);
    on<SupportLoginRequested>(_onSupportLoginRequested);

    add(const StoresRequested());
  }

  Future<void> _onRequested(
    StoresRequested event,
    Emitter<StoresState> emit,
  ) async {
    emit(const StoresLoading());
    try {
      final list = await _repository.fetchAll(verticalId: _currentVerticalFilter);
      emit(StoresLoaded(list, activeFilterVerticalId: _currentVerticalFilter));
    } catch (_) {
      emit(const StoresError('تعذّر تحميل المتاجر، تحقق من الاتصال'));
    }
  }

  Future<void> _onFilterChanged(
    StoresVerticalFilterChanged event,
    Emitter<StoresState> emit,
  ) async {
    _currentVerticalFilter = event.verticalId;
    await _onRequested(const StoresRequested(), emit);
  }

  Future<void> _onCreated(
    StoreCreated event,
    Emitter<StoresState> emit,
  ) async {
    try {
      await _repository.createStoreWithMerchant(
        storeName: event.storeName,
        verticalId: event.verticalId,
        ownerUsername: event.ownerUsername,
        ownerFullName: event.ownerFullName,
        ownerPhone: event.ownerPhone,
        ownerPassword: event.ownerPassword,
      );
      event.onComplete(null);
      await _onRequested(const StoresRequested(), emit);
    } on StoreOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onActiveToggled(
    StoreActiveToggled event,
    Emitter<StoresState> emit,
  ) async {
    try {
      await _repository.setActive(event.storeId, event.isActive);
      event.onComplete(null);
      await _onRequested(const StoresRequested(), emit);
    } on StoreOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onDeleted(
    StoreDeleted event,
    Emitter<StoresState> emit,
  ) async {
    try {
      await _repository.delete(event.storeId);
      event.onComplete(null);
      await _onRequested(const StoresRequested(), emit);
    } on StoreOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onDetailsUpdated(
    StoreDetailsUpdated event,
    Emitter<StoresState> emit,
  ) async {
    try {
      await _repository.updateDetails(
        event.storeId,
        name: event.name,
        logoUrl: event.logoUrl,
        country: event.country,
      );
      event.onComplete(null);
      await _onRequested(const StoresRequested(), emit);
    } on StoreOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onPlanChanged(
    StorePlanChanged event,
    Emitter<StoresState> emit,
  ) async {
    try {
      await _repository.changePlan(event.storeId, plan: event.plan, cycle: event.cycle);
      event.onComplete(null);
      await _onRequested(const StoresRequested(), emit);
    } on StoreOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  /// لا تُعيد تحميل القائمة — هذا الحدث لا يغيّر أي بيانات معروضة،
  /// فقط يولّد رابطًا مؤقتًا.
  Future<void> _onSupportLoginRequested(
    SupportLoginRequested event,
    Emitter<StoresState> emit,
  ) async {
    try {
      final link = await _repository.generateSupportLoginLink(event.ownerId);
      event.onComplete(link, null);
    } on StoreOperationException catch (e) {
      event.onComplete(null, e.message);
    }
  }
}
