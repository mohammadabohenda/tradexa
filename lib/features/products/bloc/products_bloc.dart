import 'package:flutter_bloc/flutter_bloc.dart';
import '../../categories/data/categories_repository.dart';
import '../data/products_repository.dart';
import 'products_event.dart';
import 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductsRepository _repository;
  final CategoriesRepository _categoriesRepository;
  String? _currentVerticalFilter;

  ProductsBloc(this._repository, this._categoriesRepository)
      : super(const ProductsLoading()) {
    on<ProductsRequested>(_onRequested);
    on<ProductsVerticalFilterChanged>(_onFilterChanged);
    on<ProductCreated>(_onCreated);
    on<ProductUpdated>(_onUpdated);
    on<ProductActiveToggled>(_onActiveToggled);
    on<ProductDeleted>(_onDeleted);

    add(const ProductsRequested());
  }

  Future<void> _onRequested(ProductsRequested event, Emitter<ProductsState> emit) async {
    emit(const ProductsLoading());
    try {
      final list = await _repository.fetchAll(verticalId: _currentVerticalFilter);
      emit(ProductsLoaded(list, activeFilterVerticalId: _currentVerticalFilter));
    } catch (e) {
      print('🔴 ERROR in ProductsBloc: $e');
      emit(ProductsError('تعذّر تحميل المنتجات: $e'));
    }
  }

  Future<void> _onFilterChanged(
    ProductsVerticalFilterChanged event,
    Emitter<ProductsState> emit,
  ) async {
    _currentVerticalFilter = event.verticalId;
    await _onRequested(const ProductsRequested(), emit);
  }

  Future<void> _onCreated(ProductCreated event, Emitter<ProductsState> emit) async {
    try {
      final productId = await _repository.create(
        verticalId: event.verticalId,
        name: event.name,
        originalPrice: event.originalPrice,
        sellingPrice: event.sellingPrice,
        description: event.description,
        imageUrl: event.imageUrl,
      );
      // الأصناف بتتحفظ بعد المنتج لأنها بتحتاج معرّفه
      await _categoriesRepository.setProductCategories(
          productId, event.categoryIds);
      event.onComplete(null);
      await _onRequested(const ProductsRequested(), emit);
    } on ProductOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onUpdated(ProductUpdated event, Emitter<ProductsState> emit) async {
    try {
      await _repository.update(
        event.productId,
        name: event.name,
        originalPrice: event.originalPrice,
        sellingPrice: event.sellingPrice,
        description: event.description,
        imageUrl: event.imageUrl,
      );
      await _categoriesRepository.setProductCategories(
          event.productId, event.categoryIds);
      event.onComplete(null);
      await _onRequested(const ProductsRequested(), emit);
    } on ProductOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onActiveToggled(
    ProductActiveToggled event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      await _repository.setActive(event.productId, event.isActive);
      event.onComplete(null);
      await _onRequested(const ProductsRequested(), emit);
    } on ProductOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onDeleted(ProductDeleted event, Emitter<ProductsState> emit) async {
    try {
      await _repository.delete(event.productId);
      event.onComplete(null);
      await _onRequested(const ProductsRequested(), emit);
    } on ProductOperationException catch (e) {
      event.onComplete(e.message);
    }
  }
}
