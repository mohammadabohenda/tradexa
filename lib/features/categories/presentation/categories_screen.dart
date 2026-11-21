import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../verticals/bloc/verticals_bloc.dart';
import '../../verticals/bloc/verticals_state.dart';
import '../../verticals/domain/vertical.dart';
import '../bloc/categories_bloc.dart';
import '../bloc/categories_event.dart';
import '../bloc/categories_state.dart';
import '../domain/category.dart';
import 'category_form_dialog.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  void _openCreateDialog(BuildContext context) {
    final bloc = context.read<CategoriesBloc>();
    showDialog(
      context: context,
      builder: (_) => CategoryFormDialog(
        onSubmit: (result) {
          final completer = Completer<String?>();
          bloc.add(CategoryCreated(
            verticalId: result.verticalId,
            name: result.name,
            sortOrder: result.sortOrder,
            onComplete: completer.complete,
          ));
          return completer.future;
        },
      ),
    );
  }

  void _openEditDialog(BuildContext context, Category category) {
    final bloc = context.read<CategoriesBloc>();
    showDialog(
      context: context,
      builder: (_) => CategoryFormDialog(
        category: category,
        onSubmit: (result) {
          final completer = Completer<String?>();
          bloc.add(CategoryUpdated(
            categoryId: category.id,
            name: result.name,
            sortOrder: result.sortOrder,
            onComplete: completer.complete,
          ));
          return completer.future;
        },
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, Category category) async {
    final bloc = context.read<CategoriesBloc>();
    final completer = Completer<String?>();
    bloc.add(CategoryActiveToggled(
        category.id, !category.isActive, completer.complete));
    final error = await completer.future;

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Category category) async {
    final bloc = context.read<CategoriesBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        title: const Text('تأكيد حذف الصنف'),
        content: Text(
          category.productsCount > 0
              ? 'الصنف "${category.name}" مربوط بـ ${category.productsCount} منتج. '
                  'الحذف بيشيل الصنف من هالمنتجات بس ما بيحذفها.'
              : 'حذف الصنف "${category.name}"؟',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء')),
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
    bloc.add(CategoryDeleted(category.id, completer.complete));
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
      currentRoute: '/categories',
      pageTitle: 'الأصناف',
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: const Text('صنف جديد'),
          onPressed: () => _openCreateDialog(context),
        ),
      ],
      child: Column(
        children: [
          const _VerticalFilterBar(),
          Expanded(
            child: BlocBuilder<CategoriesBloc, CategoriesState>(
              builder: (context, state) {
                if (state is CategoriesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CategoriesError) {
                  return Center(child: Text(state.message));
                }

                final loaded = state as CategoriesLoaded;
                final filter = loaded.activeFilterVerticalId;
                final categories = filter == null
                    ? loaded.categories
                    : loaded.forVertical(filter);

                if (categories.isEmpty) {
                  return EmptyState(
                    icon: Icons.sell_outlined,
                    title: 'لا يوجد أصناف',
                    subtitle:
                        'الأصناف بتساعد الزبون يفلتر المنتجات داخل قطاعه.',
                    actionLabel: 'صنف جديد',
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
                        const _TableHeader(),
                        ...List.generate(categories.length, (i) {
                          return _CategoryRow(
                            category: categories[i],
                            isLast: i == categories.length - 1,
                            onEdit: () => _openEditDialog(context, categories[i]),
                            onToggleActive: () =>
                                _toggleActive(context, categories[i]),
                            onDelete: () =>
                                _confirmDelete(context, categories[i]),
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: BlocBuilder<VerticalsBloc, VerticalsState>(
        builder: (context, vState) {
          final verticals =
              vState is VerticalsLoaded ? vState.verticals : <Vertical>[];

          return BlocBuilder<CategoriesBloc, CategoriesState>(
            builder: (context, cState) {
              final current = cState is CategoriesLoaded
                  ? cState.activeFilterVerticalId
                  : null;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_outlined,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: 'الكل',
                      selected: current == null,
                      onTap: () => context
                          .read<CategoriesBloc>()
                          .add(const CategoriesVerticalFilterChanged(null)),
                    ),
                    ...verticals.map((v) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: _FilterChip(
                            label: v.name,
                            selected: current == v.id,
                            onTap: () => context
                                .read<CategoriesBloc>()
                                .add(CategoriesVerticalFilterChanged(v.id)),
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

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: selected ? AppColors.primaryLight : AppColors.background,
        borderRadius: AppRadius.sm,
        child: InkWell(
          borderRadius: AppRadius.sm,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: AppRadius.sm,
              border: Border.all(
                  color: selected
                      ? AppColors.primary.withOpacity(0.3)
                      : AppColors.border),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary)),
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 50, child: Text('ترتيب', style: style)),
          Expanded(flex: 2, child: Text('الصنف', style: style)),
          Expanded(flex: 1, child: Text('القطاع', style: style)),
          Expanded(flex: 1, child: Text('عدد المنتجات', style: style)),
          Expanded(flex: 1, child: Text('الحالة', style: style)),
          SizedBox(width: 60, child: Text('', style: style)),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final Category category;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _CategoryRow({
    required this.category,
    required this.isLast,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      decoration: BoxDecoration(
        border:
            isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text('${category.sortOrder}',
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 2,
            child: Text(category.name,
                style:
                    const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 1,
            child: Text(category.verticalName,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 1,
            child: Text('${category.productsCount}',
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 1,
            child: StatusBadge(isActive: category.isActive, inactiveLabel: 'مخفي'),
          ),
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
                  child: Text(category.isActive ? 'إخفاء' : 'إظهار'),
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
