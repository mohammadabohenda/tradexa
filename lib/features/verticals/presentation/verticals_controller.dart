import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/supabase/supabase_config.dart';
import '../data/verticals_repository.dart';
import '../domain/vertical.dart';

final verticalsRepositoryProvider = Provider<VerticalsRepository>((ref) {
  return VerticalsRepository(SupabaseConfig.client);
});

abstract class VerticalsState {
  const VerticalsState();
}

class VerticalsLoading extends VerticalsState {
  const VerticalsLoading();
}

class VerticalsLoaded extends VerticalsState {
  final List<Vertical> verticals;
  const VerticalsLoaded(this.verticals);
}

class VerticalsError extends VerticalsState {
  final String message;
  const VerticalsError(this.message);
}

class VerticalsController extends StateNotifier<VerticalsState> {
  final VerticalsRepository _repository;

  VerticalsController(this._repository) : super(const VerticalsLoading()) {
    load();
  }

  Future<void> load() async {
    state = const VerticalsLoading();
    try {
      final list = await _repository.fetchAll();
      state = VerticalsLoaded(list);
    }catch (e) {
      print(e);
      state = const VerticalsError('تعذّر تحميل القطاعات، تحقق من الاتصال');
    }
  }

  /// يرجع رسالة خطأ لعرضها بالنافذة المنبثقة (null = نجاح).
  /// هذا يسمح للـ Dialog يبقى مفتوح ويعرض الخطأ بدل ما يقفل ويضيع السياق.
  Future<String?> create(String name) async {
    try {
      await _repository.create(name);
      await load();
      return null;
    } on VerticalOperationException catch (e) {
      return e.message;
    }
  }

  Future<String?> updateName(String id, String newName) async {
    try {
      await _repository.updateName(id, newName);
      await load();
      return null;
    } on VerticalOperationException catch (e) {
      return e.message;
    }
  }

  Future<String?> delete(String id) async {
    try {
      await _repository.delete(id);
      await load();
      return null;
    } on VerticalOperationException catch (e) {
      return e.message;
    }
  }
}

final verticalsControllerProvider =
    StateNotifierProvider<VerticalsController, VerticalsState>((ref) {
  return VerticalsController(ref.watch(verticalsRepositoryProvider));
});
