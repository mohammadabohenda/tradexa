import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../verticals/bloc/verticals_bloc.dart';
import '../../verticals/bloc/verticals_state.dart';
import '../../verticals/domain/vertical.dart';
import '../../categories/bloc/categories_bloc.dart';
import '../../categories/bloc/categories_state.dart';
import '../data/product_image_storage.dart';
import '../domain/product.dart';
import 'product_image_field.dart';

class ProductFormResult {
  final String verticalId;
  final String name;
  final double originalPrice;
  final double sellingPrice;
  final String? description;
  final String? imageUrl;
  final List<String> categoryIds;

  const ProductFormResult({
    required this.verticalId,
    required this.name,
    required this.originalPrice,
    required this.sellingPrice,
    required this.description,
    required this.imageUrl,
    required this.categoryIds,
  });
}

class ProductFormDialog extends StatefulWidget {
  final String? title;
  final Product? product; // null = إضافة جديد، مع قيمة = تعديل
  final List<String> initialCategoryIds;
  final Future<String?> Function(ProductFormResult result) onSubmit;

  const ProductFormDialog({
    super.key,
    this.title,
    this.product,
    this.initialCategoryIds = const [],
    required this.onSubmit,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _originalPriceController;
  late TextEditingController _sellingPriceController;

  String? _selectedVerticalId;
  String? _imageUrl;
  late Set<String> _categoryIds;
  late final ProductImageStorage _imageStorage;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _originalPriceController =
        TextEditingController(text: widget.product?.originalPrice.toStringAsFixed(2) ?? '');
    _sellingPriceController =
        TextEditingController(text: widget.product?.sellingPrice.toStringAsFixed(2) ?? '');
    _selectedVerticalId = widget.product?.verticalId;
    _imageUrl = widget.product?.imageUrl;
    _categoryIds = widget.initialCategoryIds.toSet();
    _imageStorage = ProductImageStorage(SupabaseConfig.client);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _sellingPriceController.dispose();
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

    final error = await widget.onSubmit(ProductFormResult(
      verticalId: _selectedVerticalId!,
      name: _nameController.text.trim(),
      originalPrice: double.tryParse(_originalPriceController.text) ?? 0,
      sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      imageUrl: _imageUrl,
      categoryIds: _categoryIds.toList(),
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
    final isEdit = widget.product != null;

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.title ?? (isEdit ? 'تعديل المنتج' : 'إضافة منتج جديد'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.lg),
                const Text('القطاع', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                _VerticalDropdown(
                  selectedId: _selectedVerticalId,
                  onChanged: (id) => setState(() => _selectedVerticalId = id),
                  disabled: isEdit, // عند التعديل، لا يمكن تغيير القطاع
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text('اسم المنتج', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'مثال: قميص أزرق'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'اسم المنتج مطلوب' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text('الوصف (اختياري)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'تفاصيل المنتج...'),
                ),
                const SizedBox(height: AppSpacing.sm),
                ProductImageField(
                  initialUrl: widget.product?.imageUrl,
                  storage: _imageStorage,
                  onChanged: (url) => _imageUrl = url,
                ),
                const SizedBox(height: AppSpacing.md),
                _CategorySelector(
                  verticalId: _selectedVerticalId,
                  selected: _categoryIds,
                  onToggle: (id) => setState(() {
                    if (!_categoryIds.remove(id)) _categoryIds.add(id);
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('السعر الأصلي',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _originalPriceController,
                            textDirection: TextDirection.ltr,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(hintText: '0.00'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'مطلوب';
                              if (double.tryParse(v) == null) return 'رقم غير صحيح';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('سعر البيع',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _sellingPriceController,
                            textDirection: TextDirection.ltr,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(hintText: '0.00'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'مطلوب';
                              if (double.tryParse(v) == null) return 'رقم غير صحيح';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                            : Text(isEdit ? 'تحديث المنتج' : 'إضافة المنتج'),
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

class _VerticalDropdown extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final bool disabled;

  const _VerticalDropdown({
    required this.selectedId,
    required this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VerticalsBloc, VerticalsState>(
      builder: (context, state) {
        final verticals = state is VerticalsLoaded ? state.verticals : <Vertical>[];

        return DropdownButtonFormField<String>(
          value: selectedId,
          decoration: const InputDecoration(hintText: 'اختر القطاع'),
          disabledHint: Text(
            verticals.firstWhere((v) => v.id == selectedId, orElse: () => Vertical(id: '', name: '—', slug: '', isActive: false, createdAt: DateTime.now())).name,
          ),
          items: verticals
              .map((v) => DropdownMenuItem(value: v.id, child: Text(v.name)))
              .toList(),
          onChanged: disabled ? null : onChanged,
        );
      },
    );
  }
}


/// اختيار أصناف المنتج — الأصناف بتتفلتر حسب القطاع المختار،
/// فما بيصير المستخدم يربط منتج بصنف من قطاع تاني.
class _CategorySelector extends StatelessWidget {
  final String? verticalId;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _CategorySelector({
    required this.verticalId,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('الأصناف (اختياري)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (verticalId == null)
          _Hint('اختر القطاع أولاً لعرض أصنافه')
        else
          BlocBuilder<CategoriesBloc, CategoriesState>(
            builder: (context, state) {
              if (state is! CategoriesLoaded) {
                return _Hint('جارِ تحميل الأصناف…');
              }

              final categories = state.forVertical(verticalId!);

              if (categories.isEmpty) {
                return _Hint('ما في أصناف لهذا القطاع — أضفها من شاشة الأصناف');
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((c) {
                  final isSelected = selected.contains(c.id);
                  return Material(
                    color: isSelected ? AppColors.primaryLight : AppColors.background,
                    borderRadius: AppRadius.sm,
                    child: InkWell(
                      borderRadius: AppRadius.sm,
                      onTap: () => onToggle(c.id),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.sm,
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 15,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(c.name,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration:
          BoxDecoration(color: AppColors.background, borderRadius: AppRadius.sm),
      child: Text(text,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    );
  }
}
