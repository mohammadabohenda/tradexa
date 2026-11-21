import 'package:equatable/equatable.dart';
import '../domain/vertical.dart';

abstract class VerticalsState extends Equatable {
  const VerticalsState();
  @override
  List<Object?> get props => [];
}

class VerticalsLoading extends VerticalsState {
  const VerticalsLoading();
}

class VerticalsLoaded extends VerticalsState {
  final List<Vertical> verticals;
  const VerticalsLoaded(this.verticals);

  @override
  List<Object?> get props => [verticals];
}

class VerticalsError extends VerticalsState {
  final String message;
  const VerticalsError(this.message);

  @override
  List<Object?> get props => [message];
}
