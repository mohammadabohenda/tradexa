import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/stats_repository.dart';
import '../domain/stats.dart';
import 'stats_event.dart';
import 'stats_state.dart';

class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final StatsRepository _repository;
  StatsSortBy _sortBy = StatsSortBy.unitsSold;

  StatsBloc(this._repository) : super(const StatsLoading()) {
    on<StatsRequested>(_onRequested);
    on<StatsSortChanged>(_onSortChanged);

    add(const StatsRequested());
  }

  Future<void> _onRequested(StatsRequested event, Emitter<StatsState> emit) async {
    emit(const StatsLoading());
    try {
      // نجلب الاثنين بالتوازي — ما في اعتماد بينهم فما في داعي
      // ننتظر الأول عشان نبلش التاني
      final summaryFuture = _repository.fetchSummary();
      final productsFuture = _repository.fetchTopProducts(sortBy: _sortBy);

      final ProfitSummary summary = await summaryFuture;
      final List<ProductStat> products = await productsFuture;

      emit(StatsLoaded(
        summary: summary,
        topProducts: products,
        sortBy: _sortBy,
      ));
    } on StatsException catch (e) {
      emit(StatsError(e.message));
    } catch (_) {
      emit(const StatsError('تعذّر تحميل الإحصائيات، تحقق من الاتصال'));
    }
  }

  Future<void> _onSortChanged(StatsSortChanged event, Emitter<StatsState> emit) async {
    _sortBy = event.sortBy;
    await _onRequested(const StatsRequested(), emit);
  }
}
