import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../verticals/bloc/verticals_bloc.dart';
import '../../verticals/bloc/verticals_state.dart';
import '../../verticals/domain/vertical.dart';
import '../domain/category.dart';

class CategoryFormResult {
  final String verticalId;
  final String name;
  final int sortOrder;

  const CategoryFormResult({
    required this.verticalId,
    required this.name,
    required this.sortOrder,
  });
}

class CategoryFormDialog extends StatefulWidget {
  final Category? category;
  final Future<String?> Function(CategoryFormResult result) onSubmit;

  const CategoryFormDialog({super.key, this.category, required this.onSubmit});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _sortController;

  String? _verticalId;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _sortController =
        TextEditingController(text: '${widget.category?.sortOrder ?? 0}');
    _verticalId = widget.category?.verticalId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_verticalId == null) {
      setState(() => _errorMessage = 'اختر القطاع');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final error = await widget.onSubmit(CategoryFormResult(
      verticalId: _verticalId!,
      name: _nameController.text.trim(),
      sortOrder: int.tryParse(_sortController.text) ?? 0,
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
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_isEdit ? 'تعديل الصنف' : 'إضافة صنف جديد',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.lg),
                const _Label('القطاع'),
                BlocBuilder<VerticalsBloc, VerticalsState>(
                  builder: (context, state) {
                    final verticals =
                        state is VerticalsLoaded ? state.verticals : <Vertical>[];

                    return DropdownButtonFormField<String>(
                      value: _verticalId,
                      decoration: const InputDecoration(hintText: 'اختر القطاع'),
                      items: verticals
                          .map((v) => DropdownMenuItem(
                                value: v.id,
                                child: Text(v.name),
                              ))
                          .toList(),
                      // القطاع ما بينتغيّر بالتعديل — نقله لقطاع تاني
                      // بيكسر ارتباطه بالمنتجات الحالية
                      onChanged: _isEdit
                          ? null
                          : (id) => setState(() => _verticalId = id),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                const _Label('اسم الصنف'),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'مثال: شامبو'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'اسم الصنف مطلوب' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                const _Label('ترتيب العرض'),
                TextFormField(
                  controller: _sortController,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '0'),
                ),
                const SizedBox(height: 4),
                const Text(
                  'الرقم الأصغر بيظهر أول — استعمله لترتيب الأصناف عند الزبون',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppColors.dangerLight, borderRadius: AppRadius.sm),
                    child: Text(_errorMessage!,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 12.5)),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
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
                            : Text(_isEdit ? 'حفظ' : 'إضافة'),
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
      child: Text(text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
