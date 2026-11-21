import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/verticals_repository.dart';
import 'verticals_event.dart';
import 'verticals_state.dart';

/// ملاحظة معمارية: عمليات الإنشاء/التعديل/الحذف تمرّر دالة onComplete
/// بدل إصدار حالة منفصلة، لأن نافذة الحوار (Dialog) بحاجة تعرف نتيجة
/// عمليتها تحديدًا (تقفل أو تعرض خطأ) دون التأثر بإعادة تحميل القائمة
/// كحالة عامة. هذا نمط عملي شائع لعمليات الفورم القصيرة داخل BLoC.
class VerticalsBloc extends Bloc<VerticalsEvent, VerticalsState> {
  final VerticalsRepository _repository;

  VerticalsBloc(this._repository) : super(const VerticalsLoading()) {
    on<VerticalsRequested>(_onRequested);
    on<VerticalCreated>(_onCreated);
    on<VerticalNameUpdated>(_onNameUpdated);
    on<VerticalDeleted>(_onDeleted);

    add(const VerticalsRequested());
  }

  Future<void> _onRequested(
    VerticalsRequested event,
    Emitter<VerticalsState> emit,
  ) async {
    emit(const VerticalsLoading());
    try {
      final list = await _repository.fetchAll();
      emit(VerticalsLoaded(list));
    } catch (_) {
      emit(const VerticalsError('تعذّر تحميل القطاعات، تحقق من الاتصال'));
    }
  }

  Future<void> _onCreated(
    VerticalCreated event,
    Emitter<VerticalsState> emit,
  ) async {
    try {
      await _repository.create(event.name);
      event.onComplete(null);
      await _onRequested(const VerticalsRequested(), emit);
    } on VerticalOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onNameUpdated(
    VerticalNameUpdated event,
    Emitter<VerticalsState> emit,
  ) async {
    try {
      await _repository.updateName(event.id, event.newName);
      event.onComplete(null);
      await _onRequested(const VerticalsRequested(), emit);
    } on VerticalOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onDeleted(
    VerticalDeleted event,
    Emitter<VerticalsState> emit,
  ) async {
    try {
      await _repository.delete(event.id);
      event.onComplete(null);
      await _onRequested(const VerticalsRequested(), emit);
    } on VerticalOperationException catch (e) {
      event.onComplete(e.message);
    }
  }
}
