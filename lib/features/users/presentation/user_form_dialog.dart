import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/app_user.dart';

class UserFormResult {
  final String username;
  final String fullName;
  final String password;
  final String? phone;
  final UserRole role;

  const UserFormResult({
    required this.username,
    required this.fullName,
    required this.password,
    required this.phone,
    required this.role,
  });
}

class UserFormDialog extends StatefulWidget {
  final Future<String?> Function(UserFormResult result) onSubmit;

  const UserFormDialog({super.key, required this.onSubmit});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _role = UserRole.buyer;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final error = await widget.onSubmit(UserFormResult(
      username: _usernameController.text.trim(),
      fullName: _fullNameController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      role: _role,
    ));

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('إضافة مستخدم جديد',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('رح ينولّد للمستخدم باركود دخول تلقائيًا بعد الإنشاء',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.lg),
                const _Label('الاسم الكامل'),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(hintText: 'مثال: أحمد خالد'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'الاسم الكامل مطلوب' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                const _Label('اسم المستخدم'),
                TextFormField(
                  controller: _usernameController,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(hintText: 'ahmad_k'),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'اسم المستخدم مطلوب';
                    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(value)) {
                      return 'حروف إنجليزية وأرقام و_ فقط، من 3 لـ 20 خانة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                const _Label('رقم الهاتف (اختياري)'),
                TextFormField(
                  controller: _phoneController,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.sm),
                const _Label('كلمة السر'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: '6 خانات على الأقل',
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'كلمة السر مطلوبة';
                    if (v.length < 6) return '6 خانات على الأقل';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                const _Label('الدور'),
                const SizedBox(height: 4),
                Row(
                  children: UserRole.values
                      .map((role) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _RoleChip(
                                role: role,
                                selected: _role == role,
                                onTap: () => setState(() => _role = role),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppColors.dangerLight, borderRadius: AppRadius.sm),
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('إنشاء المستخدم'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({required this.role, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : AppColors.background,
      borderRadius: AppRadius.sm,
      child: InkWell(
        borderRadius: AppRadius.sm,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: AppRadius.sm,
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(role.label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textSecondary)),
        ),
      ),
    );
  }
}
