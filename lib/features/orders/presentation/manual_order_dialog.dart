import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../products/bloc/products_bloc.dart';
import '../../products/bloc/products_state.dart';
import '../../products/domain/product.dart';
import '../data/orders_repository.dart';

class ManualOrderResult {
  final String customerName;
  final String customerPhone;
  final String? customerAddress;
  final String? notes;
  final List<NewOrderLine> lines;

  const ManualOrderResult({
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.notes,
    required this.lines,
  });
}

class ManualOrderDialog extends StatefulWidget {
  final Future<String?> Function(ManualOrderResult result) onSubmit;

  const ManualOrderDialog({super.key, required this.onSubmit});

  @override
  State<ManualOrderDialog> createState() => _ManualOrderDialogState();
}

class _ManualOrderDialogState extends State<ManualOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  /// أسطر الطلب: معرّف المنتج → الكمية. نخزّن الكمية فقط ونقرأ باقي
  /// بيانات المنتج من ProductsBloc وقت الحفظ، عشان السعر يكون دايمًا
  /// السعر الحالي مش نسخة قديمة.
  final Map<String, int> _selectedQuantities = {};

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<Product> _activeProducts() {
    final state = context.read<ProductsBloc>().state;
    if (state is! ProductsLoaded) return const [];
    return state.products.where((p) => p.isActive).toList();
  }

  double _computeTotal(List<Product> products) {
    double total = 0;
    for (final entry in _selectedQuantities.entries) {
      for (final product in products) {
        if (product.id == entry.key) {
          total += product.sellingPrice * entry.value;
          break;
        }
      }
    }
    return total;
  }

  void _setQuantity(String productId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _selectedQuantities.remove(productId);
      } else {
        _selectedQuantities[productId] = quantity;
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedQuantities.isEmpty) {
      setState(() => _errorMessage = 'أضف منتجًا واحدًا على الأقل للطلب');
      return;
    }

    final products = _activeProducts();
    final lines = <NewOrderLine>[];

    for (final entry in _selectedQuantities.entries) {
      for (final product in products) {
        if (product.id == entry.key) {
          lines.add(NewOrderLine(
            productId: product.id,
            productName: product.name,
            quantity: entry.value,
            unitPrice: product.sellingPrice,
          ));
          break;
        }
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final error = await widget.onSubmit(ManualOrderResult(
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      customerAddress:
          _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      lines: lines,
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
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('إنشاء طلب يدوي',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionLabel('بيانات العميل'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(hintText: 'اسم العميل'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'اسم العميل مطلوب' : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _phoneController,
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(hintText: 'رقم الهاتف'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'رقم الهاتف مطلوب' : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(hintText: 'العنوان (اختياري)'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(hintText: 'ملاحظات (اختياري)'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _SectionLabel('منتجات الطلب'),
                      const SizedBox(height: 8),
                      _ProductPicker(
                        selectedQuantities: _selectedQuantities,
                        onQuantityChanged: _setQuantity,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: AppColors.dangerLight, borderRadius: AppRadius.sm),
                          child: Text(_errorMessage!,
                              style:
                                  const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: BlocBuilder<ProductsBloc, ProductsState>(
                builder: (context, state) {
                  final products = state is ProductsLoaded
                      ? state.products.where((p) => p.isActive).toList()
                      : <Product>[];
                  final total = _computeTotal(products);

                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('الإجمالي',
                                style:
                                    TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(total.toStringAsFixed(2),
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('إنشاء الطلب'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
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
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary));
  }
}

/// قائمة المنتجات مع أزرار +/- للكمية. المنتجات المختارة بتطلع فوق
/// عشان المستخدم يشوف طلبه بسرعة لما تكون القائمة طويلة.
class _ProductPicker extends StatelessWidget {
  final Map<String, int> selectedQuantities;
  final void Function(String productId, int quantity) onQuantityChanged;

  const _ProductPicker({
    required this.selectedQuantities,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, state) {
        if (state is ProductsLoading) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is! ProductsLoaded) {
          return const Text('تعذّر تحميل المنتجات',
              style: TextStyle(color: AppColors.danger, fontSize: 12.5));
        }

        final products = state.products.where((p) => p.isActive).toList();

        if (products.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration:
                BoxDecoration(color: AppColors.background, borderRadius: AppRadius.sm),
            child: const Text('لا يوجد منتجات نشطة — أضف منتجًا أولاً',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          );
        }

        final sorted = [...products]..sort((a, b) {
            final aSelected = selectedQuantities.containsKey(a.id) ? 0 : 1;
            final bSelected = selectedQuantities.containsKey(b.id) ? 0 : 1;
            return aSelected.compareTo(bSelected);
          });

        return Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.sm,
            border: Border.all(color: AppColors.border),
          ),
          constraints: const BoxConstraints(maxHeight: 260),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = sorted[index];
              final quantity = selectedQuantities[product.id] ?? 0;

              return _ProductPickerRow(
                product: product,
                quantity: quantity,
                onChanged: (q) => onQuantityChanged(product.id, q),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductPickerRow extends StatelessWidget {
  final Product product;
  final int quantity;
  final ValueChanged<int> onChanged;

  const _ProductPickerRow({
    required this.product,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = quantity > 0;

    return Container(
      color: isSelected ? AppColors.primaryLight.withOpacity(0.35) : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.sm,
            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                ? Image.network(product.imageUrl!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _TinyPlaceholder())
                : const _TinyPlaceholder(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(product.sellingPrice.toStringAsFixed(2),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          _QuantityStepper(quantity: quantity, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _TinyPlaceholder extends StatelessWidget {
  const _TinyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(Icons.image_outlined, size: 15, color: AppColors.textSecondary),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (quantity == 0) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => onChanged(1),
        child: const Text('إضافة', style: TextStyle(fontSize: 12)),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(icon: Icons.remove, onTap: () => onChanged(quantity - 1)),
        Container(
          width: 34,
          alignment: Alignment.center,
          child: Text('$quantity',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        ),
        _StepButton(icon: Icons.add, onTap: () => onChanged(quantity + 1)),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: AppRadius.sm,
      child: InkWell(
        borderRadius: AppRadius.sm,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: AppRadius.sm,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 15, color: AppColors.primary),
        ),
      ),
    );
  }
}
