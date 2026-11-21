import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../verticals/bloc/verticals_bloc.dart';
import '../../verticals/bloc/verticals_state.dart';
import '../../verticals/domain/vertical.dart';

class StoreFormResult {
  final String storeName;
  final String verticalId;
  final String ownerUsername;
  final String ownerFullName;
  final String ownerPhone;
  final String ownerPassword;

  const StoreFormResult({
    required this.storeName,
    required this.verticalId,
    required this.ownerUsername,
    required this.ownerFullName,
    required this.ownerPhone,
    required this.ownerPassword,
  });
}

/// نافذة بخطوتين منطقيتين بنفس الشاشة: بيانات الشركة، ثم بيانات
/// حساب التاجر المسؤول عنه. فصلناهم بصريًا بعناوين فرعية بدل ما
/// نبني Stepper كامل — أبسط وأسرع لنموذج بهذا الحجم.
class StoreFormDialog extends StatefulWidget {
  final Future<String?> Function(StoreFormResult result) onSubmit;

  const StoreFormDialog({super.key, required this.onSubmit});

  @override
  State<StoreFormDialog> createState() => _StoreFormDialogState();
}

class _StoreFormDialogState extends State<StoreFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedVerticalId;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _storeNameController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVerticalId == null) {
      setState(() => _errorMessage = 'الرجاء اختيار القطاع');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final error = await widget.onSubmit(StoreFormResult(
      storeName: _storeNameController.text.trim(),
      verticalId: _selectedVerticalId!,
      ownerUsername: _usernameController.text.trim(),
      ownerFullName: _fullNameController.text.trim(),
      ownerPhone: _phoneController.text.trim(),
      ownerPassword: _passwordController.text,
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
                const Text('إضافة شركة جديدة',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.lg),

                _SectionLabel('بيانات الشركة'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _storeNameController,
                  decoration: const InputDecoration(hintText: 'اسم الشركة'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'الرجاء إدخال اسم الشركة' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                _VerticalDropdown(
                  selectedId: _selectedVerticalId,
                  onChanged: (id) => setState(() => _selectedVerticalId = id),
                ),

                const SizedBox(height: AppSpacing.lg),
                _SectionLabel('حساب التاجر المسؤول'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(hintText: 'الاسم الكامل'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'الرجاء إدخال الاسم الكامل' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _usernameController,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(hintText: 'اسم المستخدم (بالإنجليزي)'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'الرجاء إدخال اسم المستخدم';
                    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(v.trim())) {
                      return '3-20 حرف/رقم إنجليزي أو (_) بدون مسافات';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _phoneController,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: 'رقم الهاتف'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'الرجاء إدخال رقم الهاتف' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _passwordController,
                  textDirection: TextDirection.ltr,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'كلمة سر مبدئية'),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'كلمة السر يجب أن تكون 6 أحرف على الأقل'
                      : null,
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppColors.dangerLight, borderRadius: AppRadius.sm),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!,
                              style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                        ),
                      ],
                    ),
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
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('إنشاء الشركة'),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary));
  }
}

class _VerticalDropdown extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _VerticalDropdown({required this.selectedId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VerticalsBloc, VerticalsState>(
      builder: (context, state) {
        final verticals = state is VerticalsLoaded ? state.verticals : <Vertical>[];

        return DropdownButtonFormField<String>(
          value: selectedId,
          decoration: const InputDecoration(hintText: 'اختر القطاع'),
          items: verticals
              .map((v) => DropdownMenuItem(value: v.id, child: Text(v.name)))
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}
