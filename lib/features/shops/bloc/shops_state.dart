import 'package:equatable/equatable.dart';
import '../domain/shop.dart';

abstract class ShopsState extends Equatable {
  const ShopsState();
  @override
  List<Object?> get props => [];
}

class ShopsLoading extends ShopsState {
  const ShopsLoading();
}

class ShopsLoaded extends ShopsState {
  final List<Shop> shops;
  const ShopsLoaded(this.shops);

  @override
  List<Object?> get props => [shops];
}

class ShopsError extends ShopsState {
  final String message;
  const ShopsError(this.message);

  @override
  List<Object?> get props => [message];
}
