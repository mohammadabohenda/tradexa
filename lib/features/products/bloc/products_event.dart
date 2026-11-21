import 'package:equatable/equatable.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();
  @override
  List<Object?> get props => [];
}

class ProductsRequested extends ProductsEvent {
  const ProductsRequested();
}

class ProductsVerticalFilterChanged extends ProductsEvent {
  final String? verticalId;
  const ProductsVerticalFilterChanged(this.verticalId);

  @override
  List<Object?> get props => [verticalId];
}

class ProductCreated extends ProductsEvent {
  final String verticalId;
  final String name;
  final double originalPrice;
  final double sellingPrice;
  final String? description;
  final String? imageUrl;
  final List<String> categoryIds;
  final void Function(String? error) onComplete;

  const ProductCreated({
    required this.verticalId,
    required this.name,
    required this.originalPrice,
    required this.sellingPrice,
    required this.description,
    required this.imageUrl,
    required this.categoryIds,
    required this.onComplete,
  });

  @override
  List<Object?> get props => [verticalId, name, originalPrice, sellingPrice];
}

class ProductUpdated extends ProductsEvent {
  final String productId;
  final String name;
  final double originalPrice;
  final double sellingPrice;
  final String? description;
  final String? imageUrl;
  final List<String> categoryIds;
  final void Function(String? error) onComplete;

  const ProductUpdated({
    required this.productId,
    required this.name,
    required this.originalPrice,
    required this.sellingPrice,
    required this.description,
    required this.imageUrl,
    required this.categoryIds,
    required this.onComplete,
  });

  @override
  List<Object?> get props => [productId, name, originalPrice, sellingPrice];
}

class ProductActiveToggled extends ProductsEvent {
  final String productId;
  final bool isActive;
  final void Function(String? error) onComplete;

  const ProductActiveToggled(this.productId, this.isActive, this.onComplete);

  @override
  List<Object?> get props => [productId, isActive];
}

class ProductDeleted extends ProductsEvent {
  final String productId;
  final void Function(String? error) onComplete;

  const ProductDeleted(this.productId, this.onComplete);

  @override
  List<Object?> get props => [productId];
}
