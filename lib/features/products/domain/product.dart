class Product {
  final String id;
  final String verticalId;
  final String verticalName;
  final String name;
  final String? description;
  final String? imageUrl;
  final double originalPrice;
  final double sellingPrice;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.verticalId,
    required this.verticalName,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.originalPrice,
    required this.sellingPrice,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// الهامش (الفرق بين السعر الأصلي وسعر البيع)
  double get margin => sellingPrice - originalPrice;

  /// نسبة الهامش كنسبة مئوية
  double get marginPercent => originalPrice > 0 ? (margin / originalPrice) * 100 : 0;

  factory Product.fromMap(Map<String, dynamic> map) {
    final verticalData = map['verticals'] as Map<String, dynamic>?;

    return Product(
      id: map['id'] as String,
      verticalId: map['vertical_id'] as String,
      verticalName: verticalData?['name'] as String? ?? '—',
      name: map['name'] as String,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      originalPrice: (map['original_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0.0,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }
}
