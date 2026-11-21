class Vertical {
  final String id;
  final String name;
  final String slug;
  final bool isActive;
  final DateTime createdAt;

  const Vertical({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
    required this.createdAt,
  });

  factory Vertical.fromMap(Map<String, dynamic> map) {
    return Vertical(
      id: map['id'] as String,
      name: map['name'] as String,
      slug: map['slug'] as String,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

String generateSlug(String name) {
  final base = name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'[^\w\-]'), '');

  final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
  return base.isEmpty ? 'vertical-$suffix' : '$base-$suffix';
}
