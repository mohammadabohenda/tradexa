import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../verticals/bloc/verticals_bloc.dart';
import '../../verticals/bloc/verticals_state.dart';
import '../../verticals/domain/vertical.dart';
import '../domain/product.dart';
import '../../categories/data/categories_repository.dart';
import '../bloc/products_bloc.dart';
import '../bloc/products_event.dart';
import '../bloc/products_state.dart';
import 'product_form_dialog.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  void _openCreateDialog(BuildContext context) {
    final bloc = context.read<ProductsBloc>();
    showDialog(
      context: context,
      builder: (_) => ProductFormDialog(
        title: 'إضافة منتج جديد',
        onSubmit: (result) {
          final completer = Completer<String?>();
          bloc.add(ProductCreated(
            verticalId: result.verticalId,
            name: result.name,
            originalPrice: result.originalPrice,
            sellingPrice: result.sellingPrice,
            description: result.description,
            imageUrl: result.imageUrl,
            categoryIds: result.categoryIds,
            onComplete: completer.complete,
          ));
          return completer.future;
        },
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context, Product product) async {
    final bloc = context.read<ProductsBloc>();

    // نجيب أصناف المنتج الحالية قبل ما نفتح النافذة عشان تظهر
    // مختارة مسبقًا بدل ما يعيد المستخدم اختيارها كل مرة.
    final repo = CategoriesRepository(SupabaseConfig.client);
    List<String> current = const [];
    try {
      current = await repo.fetchProductCategoryIds(product.id);
    } catch (_) {
      // فشل جلب الأصناف ما بيمنع التعديل — بتفتح فاضية
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => ProductFormDialog(
        title: 'تعديل: ${product.name}',
        product: product,
        initialCategoryIds: current,
        onSubmit: (result) {
          final completer = Completer<String?>();
          bloc.add(ProductUpdated(
            productId: product.id,
            name: result.name,
            originalPrice: result.originalPrice,
            sellingPrice: result.sellingPrice,
            description: result.description,
            imageUrl: result.imageUrl,
            categoryIds: result.categoryIds,
            onComplete: completer.complete,
          ));
          return completer.future;
        },
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, Product product) async {
    final bloc = context.read<ProductsBloc>();
    final completer = Completer<String?>();
    bloc.add(ProductActiveToggled(product.id, !product.isActive, completer.complete));
    final error = await completer.future;

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final bloc = context.read<ProductsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        title: const Text('تأكيد حذف المنتج'),
        content: Text('هل أنت متأكد من حذف "${product.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final completer = Completer<String?>();
    bloc.add(ProductDeleted(product.id, completer.complete));
    final error = await completer.future;

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/products',
      pageTitle: 'المنتجات',
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: const Text('منتج جديد'),
          onPressed: () => _openCreateDialog(context),
        ),
      ],
      child: Column(
        children: [
          const _VerticalFilterBar(),
          Expanded(
            child: BlocBuilder<ProductsBloc, ProductsState>(
              builder: (context, state) {
                if (state is ProductsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ProductsError) {
                  return Center(child: Text(state.message));
                }

                final products = (state as ProductsLoaded).products;

                if (products.isEmpty) {
                  return EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'لا يوجد منتجات بعد',
                    subtitle: 'أضف أول منتج للبدء ببناء الكتالوج الخاص بك.',
                    actionLabel: 'إضافة منتج',
                    onAction: () => _openCreateDialog(context),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.md,
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      children: [
                        const _ProductsTableHeader(),
                        ...List.generate(products.length, (i) {
                          return _ProductRow(
                            product: products[i],
                            isLast: i == products.length - 1,
                            onEdit: () => _openEditDialog(context, products[i]),
                            onToggleActive: () => _toggleActive(context, products[i]),
                            onDelete: () => _confirmDelete(context, products[i]),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalFilterBar extends StatelessWidget {
  const _VerticalFilterBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: BlocBuilder<VerticalsBloc, VerticalsState>(
        builder: (context, vState) {
          final verticals = vState is VerticalsLoaded ? vState.verticals : <Vertical>[];

          return BlocBuilder<ProductsBloc, ProductsState>(
            builder: (context, pState) {
              final currentFilter = pState is ProductsLoaded ? pState.activeFilterVerticalId : null;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: 'الكل',
                      selected: currentFilter == null,
                      onTap: () =>
                          context.read<ProductsBloc>().add(const ProductsVerticalFilterChanged(null)),
                    ),
                    ...verticals.map((v) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: _FilterChip(
                            label: v.name,
                            selected: currentFilter == v.id,
                            onTap: () =>
                                context.read<ProductsBloc>().add(ProductsVerticalFilterChanged(v.id)),
                          ),
                        )),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : AppColors.background,
      borderRadius: AppRadius.sm,
      child: InkWell(
        borderRadius: AppRadius.sm,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: AppRadius.sm,
            border: Border.all(color: selected ? AppColors.primary.withOpacity(0.3) : AppColors.border),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textSecondary)),
        ),
      ),
    );
  }
}

class _ProductsTableHeader extends StatelessWidget {
  const _ProductsTableHeader();

  @override
  Widget build(BuildContext context) {
    const style =
        TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 56, child: Text('', style: style)),
          Expanded(flex: 2, child: Text('المنتج', style: style)),
          Expanded(flex: 1, child: Text('القطاع', style: style)),
          Expanded(flex: 1, child: Text('السعر الأصلي', style: style)),
          Expanded(flex: 1, child: Text('سعر البيع', style: style)),
          Expanded(flex: 1, child: Text('الهامش', style: style)),
          Expanded(flex: 1, child: Text('الحالة', style: style)),
          SizedBox(width: 60, child: Text('', style: style)),
        ],
      ),
    );
  }
}

/// صورة مصغّرة للمنتج — تتعامل مع ثلاث حالات: صورة موجودة، رابط
/// مكسور، ولا صورة إطلاقًا. بالحالتين الأخيرتين نعرض أيقونة بدل
/// مربع فاضي عشان الصف يضل مقروء.
class _ProductThumbnail extends StatelessWidget {
  final String? imageUrl;

  const _ProductThumbnail({required this.imageUrl});

  Widget _placeholder() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.sm,
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.image_outlined, size: 18, color: AppColors.textSecondary),
      );

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) return _placeholder();

    return ClipRRect(
      borderRadius: AppRadius.sm,
      child: Image.network(
        imageUrl!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 44,
            height: 44,
            color: AppColors.background,
            child: const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _ProductRow({
    required this.product,
    required this.isLast,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final margin = product.margin;
    final marginColor = margin >= 0 ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: _ProductThumbnail(imageUrl: product.imageUrl),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                if (product.description != null && product.description!.isNotEmpty)
                  Text(product.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(product.verticalName,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 1,
            child: Text('${product.originalPrice.toStringAsFixed(2)}',
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 12.5)),
          ),
          Expanded(
            flex: 1,
            child: Text('${product.sellingPrice.toStringAsFixed(2)}',
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 1,
            child: Text('${margin.toStringAsFixed(2)} (${product.marginPercent.toStringAsFixed(1)}%)',
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 12, color: marginColor, fontWeight: FontWeight.w600)),
          ),
          Expanded(flex: 1, child: StatusBadge(isActive: product.isActive)),
          SizedBox(
            width: 60,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
              onSelected: (value) => value == 'edit'
                  ? onEdit()
                  : value == 'toggle'
                      ? onToggleActive()
                      : onDelete(),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(product.isActive ? 'تعطيل' : 'تفعيل'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('حذف', style: TextStyle(color: AppColors.danger)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
