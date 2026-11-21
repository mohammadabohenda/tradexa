/// يمثل "الشركة" (Company) — تطوير كامل لمفهوم Store السابق ليشمل
/// بيانات SaaS: الاشتراك، الدولة، الشعار، وإحصائيات مجمّعة.
class Store {
  final String id;
  final String verticalId;
  final String verticalName;
  final String ownerId;
  final String ownerUsername;
  final String ownerFullName;
  final String name;
  final String? logoUrl;
  final String? country;
  final SubscriptionPlan subscriptionPlan;
  final BillingCycle billingCycle;
  final DateTime? subscriptionExpiresAt;
  final bool isActive;
  final DateTime createdAt;

  // إحصائيات مجمّعة من store_stats — قد تكون null لو لم تُحمّل بعد.
  final int? productsCount;
  final int? ordersCount;
  final int? customersCount;
  final DateTime? lastOrderAt;

  const Store({
    required this.id,
    required this.verticalId,
    required this.verticalName,
    required this.ownerId,
    required this.ownerUsername,
    required this.ownerFullName,
    required this.name,
    required this.logoUrl,
    required this.country,
    required this.subscriptionPlan,
    required this.billingCycle,
    required this.subscriptionExpiresAt,
    required this.isActive,
    required this.createdAt,
    this.productsCount,
    this.ordersCount,
    this.customersCount,
    this.lastOrderAt,
  });

  /// آخر نشاط فعلي = آخر طلبية، أو تاريخ التسجيل لو ما في طلبات بعد.
  DateTime get lastActivity => lastOrderAt ?? createdAt;

  factory Store.fromMap(Map<String, dynamic> map) {
    final verticalData = map['verticals'] as Map<String, dynamic>?;
    final ownerData = map['profiles'] as Map<String, dynamic>?;

    return Store(
      id: map['id'] as String,
      verticalId: map['vertical_id'] as String,
      verticalName: verticalData?['name'] as String? ?? '—',
      ownerId: map['owner_id'] as String,
      ownerUsername: ownerData?['username'] as String? ?? '—',
      ownerFullName: ownerData?['full_name'] as String? ?? '—',
      name: map['name'] as String,
      logoUrl: map['logo_url'] as String?,
      country: map['country'] as String?,
      subscriptionPlan: SubscriptionPlan.fromValue(map['subscription_plan'] as String?),
      billingCycle: BillingCycle.fromValue(map['billing_cycle'] as String?),
      subscriptionExpiresAt: map['subscription_expires_at'] != null
          ? DateTime.parse(map['subscription_expires_at'] as String)
          : null,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Store copyWithStats({
    required int productsCount,
    required int ordersCount,
    required int customersCount,
    required DateTime? lastOrderAt,
  }) {
    return Store(
      id: id,
      verticalId: verticalId,
      verticalName: verticalName,
      ownerId: ownerId,
      ownerUsername: ownerUsername,
      ownerFullName: ownerFullName,
      name: name,
      logoUrl: logoUrl,
      country: country,
      subscriptionPlan: subscriptionPlan,
      billingCycle: billingCycle,
      subscriptionExpiresAt: subscriptionExpiresAt,
      isActive: isActive,
      createdAt: createdAt,
      productsCount: productsCount,
      ordersCount: ordersCount,
      customersCount: customersCount,
      lastOrderAt: lastOrderAt,
    );
  }
}

enum SubscriptionPlan {
  starter('starter', 'Starter'),
  business('business', 'Business'),
  enterprise('enterprise', 'Enterprise');

  final String value;
  final String label;
  const SubscriptionPlan(this.value, this.label);

  static SubscriptionPlan fromValue(String? value) {
    return SubscriptionPlan.values.firstWhere(
      (p) => p.value == value,
      orElse: () => SubscriptionPlan.starter,
    );
  }
}

enum BillingCycle {
  monthly('monthly', 'شهري'),
  yearly('yearly', 'سنوي');

  final String value;
  final String label;
  const BillingCycle(this.value, this.label);

  static BillingCycle fromValue(String? value) {
    return BillingCycle.values.firstWhere(
      (c) => c.value == value,
      orElse: () => BillingCycle.monthly,
    );
  }
}
