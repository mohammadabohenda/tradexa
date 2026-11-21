import 'package:equatable/equatable.dart';
import '../data/stats_repository.dart';
import '../domain/stats.dart';

abstract class StatsState extends Equatable {
  const StatsState();
  @override
  List<Object?> get props => [];
}

class StatsLoading extends StatsState {
  const StatsLoading();
}

class StatsLoaded extends StatsState {
  final ProfitSummary summary;
  final List<ProductStat> topProducts;
  final StatsSortBy sortBy;

  const StatsLoaded({
    required this.summary,
    required this.topProducts,
    required this.sortBy,
  });

  @override
  List<Object?> get props => [summary, topProducts, sortBy];
}

class StatsError extends StatsState {
  final String message;
  const StatsError(this.message);

  @override
  List<Object?> get props => [message];
}
