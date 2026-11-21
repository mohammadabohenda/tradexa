import 'package:equatable/equatable.dart';

abstract class CategoriesEvent extends Equatable {
  const CategoriesEvent();
  @override
  List<Object?> get props => [];
}

class CategoriesRequested extends CategoriesEvent {
  const CategoriesRequested();
}

class CategoriesVerticalFilterChanged extends CategoriesEvent {
  final String? verticalId;
  const CategoriesVerticalFilterChanged(this.verticalId);

  @override
  List<Object?> get props => [verticalId];
}

class CategoryCreated extends CategoriesEvent {
  final String verticalId;
  final String name;
  final int sortOrder;
  final void Function(String? error) onComplete;

  const CategoryCreated({
    required this.verticalId,
    required this.name,
    required this.sortOrder,
    required this.onComplete,
  });

  @override
  List<Object?> get props => [verticalId, name, sortOrder];
}

class CategoryUpdated extends CategoriesEvent {
  final String categoryId;
  final String name;
  final int sortOrder;
  final void Function(String? error) onComplete;

  const CategoryUpdated({
    required this.categoryId,
    required this.name,
    required this.sortOrder,
    required this.onComplete,
  });

  @override
  List<Object?> get props => [categoryId, name, sortOrder];
}

class CategoryActiveToggled extends CategoriesEvent {
  final String categoryId;
  final bool isActive;
  final void Function(String? error) onComplete;

  const CategoryActiveToggled(this.categoryId, this.isActive, this.onComplete);

  @override
  List<Object?> get props => [categoryId, isActive];
}

class CategoryDeleted extends CategoriesEvent {
  final String categoryId;
  final void Function(String? error) onComplete;

  const CategoryDeleted(this.categoryId, this.onComplete);

  @override
  List<Object?> get props => [categoryId];
}
