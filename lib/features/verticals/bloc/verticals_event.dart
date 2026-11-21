import 'package:equatable/equatable.dart';

abstract class VerticalsEvent extends Equatable {
  const VerticalsEvent();
  @override
  List<Object?> get props => [];
}

class VerticalsRequested extends VerticalsEvent {
  const VerticalsRequested();
}

class VerticalCreated extends VerticalsEvent {
  final String name;
  final void Function(String? error) onComplete;
  const VerticalCreated(this.name, this.onComplete);

  @override
  List<Object?> get props => [name];
}

class VerticalNameUpdated extends VerticalsEvent {
  final String id;
  final String newName;
  final void Function(String? error) onComplete;
  const VerticalNameUpdated(this.id, this.newName, this.onComplete);

  @override
  List<Object?> get props => [id, newName];
}

class VerticalDeleted extends VerticalsEvent {
  final String id;
  final void Function(String? error) onComplete;
  const VerticalDeleted(this.id, this.onComplete);

  @override
  List<Object?> get props => [id];
}
