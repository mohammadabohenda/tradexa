import 'package:equatable/equatable.dart';
import '../domain/store.dart';

abstract class StoresEvent extends Equatable {
  const StoresEvent();
  @override
  List<Object?> get props => [];
}

class StoresRequested extends StoresEvent {
  const StoresRequested();
}

/// فلترة حسب قطاع معيّن، أو null لعرض كل المتاجر.
class StoresVerticalFilterChanged extends StoresEvent {
  final String? verticalId;
  const StoresVerticalFilterChanged(this.verticalId);

  @override
  List<Object?> get props => [verticalId];
}

class StoreCreated extends StoresEvent {
  final String storeName;
  final String verticalId;
  final String ownerUsername;
  final String ownerFullName;
  final String ownerPhone;
  final String ownerPassword;
  final void Function(String? error) onComplete;

  const StoreCreated({
    required this.storeName,
    required this.verticalId,
    required this.ownerUsername,
    required this.ownerFullName,
    required this.ownerPhone,
    required this.ownerPassword,
    required this.onComplete,
  });

  @override
  List<Object?> get props => [storeName, verticalId, ownerUsername];
}

class StoreActiveToggled extends StoresEvent {
  final String storeId;
  final bool isActive;
  final void Function(String? error) onComplete;

  const StoreActiveToggled(this.storeId, this.isActive, this.onComplete);

  @override
  List<Object?> get props => [storeId, isActive];
}

class StoreDeleted extends StoresEvent {
  final String storeId;
  final void Function(String? error) onComplete;

  const StoreDeleted(this.storeId, this.onComplete);

  @override
  List<Object?> get props => [storeId];
}

class StoreDetailsUpdated extends StoresEvent {
  final String storeId;
  final String name;
  final String? logoUrl;
  final String? country;
  final void Function(String? error) onComplete;

  const StoreDetailsUpdated({
    required this.storeId,
    required this.name,
    required this.logoUrl,
    required this.country,
    required this.onComplete,
  });

  @override
  List<Object?> get props => [storeId, name, logoUrl, country];
}

class StorePlanChanged extends StoresEvent {
  final String storeId;
  final SubscriptionPlan plan;
  final BillingCycle cycle;
  final void Function(String? error) onComplete;

  const StorePlanChanged({
    required this.storeId,
    required this.plan,
    required this.cycle,
    required this.onComplete,
  });

  @override
  List<Object?> get props => [storeId, plan, cycle];
}

class SupportLoginRequested extends StoresEvent {
  final String ownerId;
  final void Function(String? link, String? error) onComplete;

  const SupportLoginRequested(this.ownerId, this.onComplete);

  @override
  List<Object?> get props => [ownerId];
}
