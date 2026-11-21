import 'package:equatable/equatable.dart';
import '../data/stats_repository.dart';

abstract class StatsEvent extends Equatable {
  const StatsEvent();
  @override
  List<Object?> get props => [];
}

class StatsRequested extends StatsEvent {
  const StatsRequested();
}

class StatsSortChanged extends StatsEvent {
  final StatsSortBy sortBy;
  const StatsSortChanged(this.sortBy);

  @override
  List<Object?> get props => [sortBy];
}
