import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/categories_repository.dart';
import 'categories_event.dart';
import 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoriesRepository _repository;
  String? _currentFilter;

  CategoriesBloc(this._repository) : super(const CategoriesLoading()) {
    on<CategoriesRequested>(_onRequested);
    on<CategoriesVerticalFilterChanged>(_onFilterChanged);
    on<CategoryCreated>(_onCreated);
    on<CategoryUpdated>(_onUpdated);
    on<CategoryActiveToggled>(_onActiveToggled);
    on<CategoryDeleted>(_onDeleted);

    add(const CategoriesRequested());
  }

  /// ملاحظة: منجيب كل الأصناف دايمًا (بدون فلترة بالاستعلام) لأن
  /// نموذج المنتج بيحتاج أصناف أي قطاع بيختاره المستخدم. الفلترة
  /// بالشاشة بتصير على الحالة المحمّلة.
  Future<void> _onRequested(
    CategoriesRequested event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(const CategoriesLoading());
    try {
      final list = await _repository.fetchAll();
      emit(CategoriesLoaded(list, activeFilterVerticalId: _currentFilter));
    } catch (_) {
      emit(const CategoriesError('تعذّر تحميل الأصناف، تحقق من الاتصال'));
    }
  }

  Future<void> _onFilterChanged(
    CategoriesVerticalFilterChanged event,
    Emitter<CategoriesState> emit,
  ) async {
    _currentFilter = event.verticalId;
    final current = state;
    if (current is CategoriesLoaded) {
      emit(CategoriesLoaded(current.categories,
          activeFilterVerticalId: _currentFilter));
    }
  }

  Future<void> _onCreated(
    CategoryCreated event,
    Emitter<CategoriesState> emit,
  ) async {
    try {
      await _repository.create(
        verticalId: event.verticalId,
        name: event.name,
        sortOrder: event.sortOrder,
      );
      event.onComplete(null);
      await _onRequested(const CategoriesRequested(), emit);
    } on CategoryOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onUpdated(
    CategoryUpdated event,
    Emitter<CategoriesState> emit,
  ) async {
    try {
      await _repository.update(
        event.categoryId,
        name: event.name,
        sortOrder: event.sortOrder,
      );
      event.onComplete(null);
      await _onRequested(const CategoriesRequested(), emit);
    } on CategoryOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onActiveToggled(
    CategoryActiveToggled event,
    Emitter<CategoriesState> emit,
  ) async {
    try {
      await _repository.setActive(event.categoryId, event.isActive);
      event.onComplete(null);
      await _onRequested(const CategoriesRequested(), emit);
    } on CategoryOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onDeleted(
    CategoryDeleted event,
    Emitter<CategoriesState> emit,
  ) async {
    try {
      await _repository.delete(event.categoryId);
      event.onComplete(null);
      await _onRequested(const CategoriesRequested(), emit);
    } on CategoryOperationException catch (e) {
      event.onComplete(e.message);
    }
  }
}
