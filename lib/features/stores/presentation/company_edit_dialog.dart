import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/store.dart';

class CompanyEditDialog extends StatefulWidget {
  final Store store;
  final Future<String?> Function(String name, String? logoUrl, String? country) onSubmit;

  const CompanyEditDialog({super.key, required this.store, required this.onSubmit});

  @override
  State<CompanyEditDialog> createState() => _CompanyEditDialogState();
}

class _CompanyEditDialogState extends State<CompanyEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _logoController;
  late final TextEditingController _countryController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store.name);
    _logoController = TextEditingController(text: widget.store.logoUrl ?? '');
    _countryController = TextEditingController(text: widget.store.country ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _logoController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final error = await widget.onSubmit(
      _nameController.text.trim(),
      _logoController.text.trim().isEmpty ? null : _logoController.text.trim(),
      _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
    );

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
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('تعديل بيانات الشركة',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.lg),
                const Text('اسم الشركة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'الرجاء إدخال اسم الشركة' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text('رابط الشعار (اختياري)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _logoController,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(hintText: 'https://...'),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text('الدولة (اختياري)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(controller: _countryController),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: AppRadius.sm),
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
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('حفظ'),
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
