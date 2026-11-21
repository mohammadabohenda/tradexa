import 'package:equatable/equatable.dart';
import '../domain/shop.dart';

abstract class ShopsEvent extends Equatable {
  const ShopsEvent();
  @override
  List<Object?> get props => [];
}

class ShopsRequested extends ShopsEvent {
  const ShopsRequested();
}

class ShopCreated extends ShopsEvent {
  final NewShopRequest request;
  final void Function(String? slug, String? error) onComplete;

  const ShopCreated(this.request, this.onComplete);

  @override
  List<Object?> get props => [request.slug];
}

class ShopActiveToggled extends ShopsEvent {
  final String shopId;
  final bool isActive;
  final void Function(String? error) onComplete;

  const ShopActiveToggled(this.shopId, this.isActive, this.onComplete);

  @override
  List<Object?> get props => [shopId, isActive];
}

class ShopDeleted extends ShopsEvent {
  final String shopId;
  final void Function(String? error) onComplete;

  const ShopDeleted(this.shopId, this.onComplete);

  @override
  List<Object?> get props => [shopId];
}
