enum UserRole {
  platformAdmin('platform_admin', 'مدير المنصة'),
  buyer('buyer', 'عميل');

  final String value;
  final String label;
  const UserRole(this.value, this.label);

  static UserRole fromValue(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => UserRole.buyer,
    );
  }
}

class AppUser {
  final String id;
  final String username;
  final String fullName;
  final String? phone;
  final UserRole role;
  final String? accessToken;
  final DateTime? tokenIssuedAt;
  final bool isActive;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.accessToken,
    required this.tokenIssuedAt,
    required this.isActive,
    required this.createdAt,
  });

  /// أول حرف من الاسم للأفاتار
  String get initial => fullName.isNotEmpty ? fullName[0] : '؟';

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      username: map['username'] as String? ?? '—',
      fullName: map['full_name'] as String? ?? '—',
      phone: map['phone'] as String?,
      role: UserRole.fromValue(map['role'] as String?),
      accessToken: map['access_token'] as String?,
      tokenIssuedAt: map['token_issued_at'] != null
          ? DateTime.parse(map['token_issued_at'] as String)
          : null,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
