import 'package:equatable/equatable.dart';
import '../domain/store.dart';

abstract class StoresState extends Equatable {
  const StoresState();
  @override
  List<Object?> get props => [];
}

class StoresLoading extends StoresState {
  const StoresLoading();
}

class StoresLoaded extends StoresState {
  final List<Store> stores;
  final String? activeFilterVerticalId;

  const StoresLoaded(this.stores, {this.activeFilterVerticalId});

  @override
  List<Object?> get props => [stores, activeFilterVerticalId];
}

class StoresError extends StoresState {
  final String message;
  const StoresError(this.message);

  @override
  List<Object?> get props => [message];
}
