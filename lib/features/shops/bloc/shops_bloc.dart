import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/shops_repository.dart';
import 'shops_event.dart';
import 'shops_state.dart';

class ShopsBloc extends Bloc<ShopsEvent, ShopsState> {
  final ShopsRepository _repository;

  ShopsBloc(this._repository) : super(const ShopsLoading()) {
    on<ShopsRequested>(_onRequested);
    on<ShopCreated>(_onCreated);
    on<ShopActiveToggled>(_onActiveToggled);
    on<ShopDeleted>(_onDeleted);

    add(const ShopsRequested());
  }

  Future<void> _onRequested(ShopsRequested event, Emitter<ShopsState> emit) async {
    emit(const ShopsLoading());
    try {
      final list = await _repository.fetchAll();
      emit(ShopsLoaded(list));
    } catch (_) {
      emit(const ShopsError('تعذّر تحميل المتاجر، تحقق من الاتصال'));
    }
  }

  Future<void> _onCreated(ShopCreated event, Emitter<ShopsState> emit) async {
    try {
      final slug = await _repository.createShop(event.request);
      event.onComplete(slug, null);
      await _onRequested(const ShopsRequested(), emit);
    } on ShopOperationException catch (e) {
      event.onComplete(null, e.message);
    }
  }

  Future<void> _onActiveToggled(
    ShopActiveToggled event,
    Emitter<ShopsState> emit,
  ) async {
    try {
      await _repository.setActive(event.shopId, event.isActive);
      event.onComplete(null);
      await _onRequested(const ShopsRequested(), emit);
    } on ShopOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onDeleted(ShopDeleted event, Emitter<ShopsState> emit) async {
    try {
      await _repository.delete(event.shopId);
      event.onComplete(null);
      await _onRequested(const ShopsRequested(), emit);
    } on ShopOperationException catch (e) {
      event.onComplete(e.message);
    }
  }
}
