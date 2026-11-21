import 'package:equatable/equatable.dart';
import '../domain/product.dart';

abstract class ProductsState extends Equatable {
  const ProductsState();
  @override
  List<Object?> get props => [];
}

class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

class ProductsLoaded extends ProductsState {
  final List<Product> products;
  final String? activeFilterVerticalId;

  const ProductsLoaded(this.products, {this.activeFilterVerticalId});

  @override
  List<Object?> get props => [products, activeFilterVerticalId];
}

class ProductsError extends ProductsState {
  final String message;
  const ProductsError(this.message);

  @override
  List<Object?> get props => [message];
}
