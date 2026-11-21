class Category {
  final String id;
  final String verticalId;
  final String verticalName;
  final String name;
  final int sortOrder;
  final bool isActive;
  final int productsCount;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.verticalId,
    required this.verticalName,
    required this.name,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    this.productsCount = 0,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    final verticalRel = map['verticals'] as Map<String, dynamic>?;
    final countRel = map['product_categories'] as List?;

    return Category(
      id: map['id'] as String,
      verticalId: map['vertical_id'] as String,
      verticalName: verticalRel?['name'] as String? ?? '—',
      name: map['name'] as String,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      productsCount: countRel?.length ?? 0,
    );
  }
}
