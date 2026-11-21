class Shop {
  final String id;
  final String slug;
  final String name;
  final String? logoUrl;
  final String primaryColor;
  final String currencySymbol;
  final String textDirection;
  final String? whatsappNumber;
  final int maxQtyPerItem;
  final bool isActive;
  final DateTime createdAt;

  final String? ownerUsername;
  final String? ownerFullName;

  final int productsCount;
  final int ordersCount;

  const Shop({
    required this.id,
    required this.slug,
    required this.name,
    required this.logoUrl,
    required this.primaryColor,
    required this.currencySymbol,
    required this.textDirection,
    required this.whatsappNumber,
    required this.maxQtyPerItem,
    required this.isActive,
    required this.createdAt,
    this.ownerUsername,
    this.ownerFullName,
    this.productsCount = 0,
    this.ordersCount = 0,
  });

  bool get hasOwner => ownerUsername != null;

  factory Shop.fromMap(Map<String, dynamic> map) {
    final owner = map['profiles'] as Map<String, dynamic>?;
    final products = map['products'] as List?;
    final orders = map['orders'] as List?;

    return Shop(
      id: map['id'] as String,
      slug: map['slug'] as String,
      name: map['name'] as String,
      logoUrl: map['logo_url'] as String?,
      primaryColor: map['primary_color'] as String? ?? '#E8720C',
      currencySymbol: map['currency_symbol'] as String? ?? 'ل.س',
      textDirection: map['text_direction'] as String? ?? 'rtl',
      whatsappNumber: map['whatsapp_number'] as String?,
      maxQtyPerItem: (map['max_qty_per_item'] as num?)?.toInt() ?? 99,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      ownerUsername: owner?['username'] as String?,
      ownerFullName: owner?['full_name'] as String?,
      productsCount: products?.length ?? 0,
      ordersCount: orders?.length ?? 0,
    );
  }
}

/// بيانات إنشاء محل جديد مع صاحبه.
class NewShopRequest {
  final String shopName;
  final String slug;
  final String primaryColor;
  final String currencySymbol;
  final String textDirection;
  final String? whatsappNumber;
  final int maxQtyPerItem;
  final String? logoUrl;

  final String ownerFullName;
  final String ownerUsername;
  final String ownerPassword;
  final String? ownerPhone;

  const NewShopRequest({
    required this.shopName,
    required this.slug,
    required this.primaryColor,
    required this.currencySymbol,
    required this.textDirection,
    required this.whatsappNumber,
    required this.maxQtyPerItem,
    required this.logoUrl,
    required this.ownerFullName,
    required this.ownerUsername,
    required this.ownerPassword,
    required this.ownerPhone,
  });

  Map<String, dynamic> toBody() => {
        'shop_name': shopName,
        'slug': slug,
        'primary_color': primaryColor,
        'currency_symbol': currencySymbol,
        'text_direction': textDirection,
        'whatsapp_number': whatsappNumber,
        'max_qty_per_item': maxQtyPerItem,
        'logo_url': logoUrl,
        'owner_full_name': ownerFullName,
        'owner_username': ownerUsername,
        'owner_password': ownerPassword,
        'owner_phone': ownerPhone,
      };
}

/// يحوّل اسمًا عربيًا أو إنجليزيًا لرابط صالح. العربي ما بينفع
/// بالروابط، فبنرجع فاضي والمستخدم بيكتبه بنفسه.
String suggestSlug(String name) {
  final ascii = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .trim()
      .replaceAll(RegExp(r'[\s-]+'), '-');

  return RegExp(r'^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$').hasMatch(ascii)
      ? ascii
      : '';
}
