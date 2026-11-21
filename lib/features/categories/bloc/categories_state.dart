import 'package:equatable/equatable.dart';
import '../domain/category.dart';

abstract class CategoriesState extends Equatable {
  const CategoriesState();
  @override
  List<Object?> get props => [];
}

class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
}

class CategoriesLoaded extends CategoriesState {
  final List<Category> categories;
  final String? activeFilterVerticalId;

  const CategoriesLoaded(this.categories, {this.activeFilterVerticalId});

  /// أصناف قطاع معيّن — يستعملها نموذج المنتج لعرض الخيارات
  /// المناسبة للقطاع المختار فقط.
  List<Category> forVertical(String verticalId) =>
      categories.where((c) => c.verticalId == verticalId).toList();

  @override
  List<Object?> get props => [categories, activeFilterVerticalId];
}

class CategoriesError extends CategoriesState {
  final String message;
  const CategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}
