import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../domain/vertical.dart';
import '../bloc/verticals_bloc.dart';
import '../bloc/verticals_event.dart';
import '../bloc/verticals_state.dart';
import 'vertical_form_dialog.dart';

class VerticalsScreen extends StatelessWidget {
  const VerticalsScreen({super.key});

  void _openCreateDialog(BuildContext context) {
    final bloc = context.read<VerticalsBloc>();
    showDialog(
      context: context,
      builder: (_) => VerticalFormDialog(
        title: 'إضافة قطاع جديد',
        onSubmit: (name) {
          final completer = Completer<String?>();
          bloc.add(VerticalCreated(name, completer.complete));
          return completer.future;
        },
      ),
    );
  }

  void _openEditDialog(BuildContext context, Vertical v) {
    final bloc = context.read<VerticalsBloc>();
    showDialog(
      context: context,
      builder: (_) => VerticalFormDialog(
        title: 'تعديل اسم القطاع',
        initialName: v.name,
        onSubmit: (name) {
          final completer = Completer<String?>();
          bloc.add(VerticalNameUpdated(v.id, name, completer.complete));
          return completer.future;
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Vertical v) async {
    final bloc = context.read<VerticalsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف قطاع "${v.name}"؟ لا يمكن التراجع عن هذا الإجراء.'),
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
    bloc.add(VerticalDeleted(v.id, completer.complete));
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
      currentRoute: '/verticals',
      pageTitle: 'القطاعات',
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: const Text('قطاع جديد'),
          onPressed: () => _openCreateDialog(context),
        ),
      ],
      child: BlocBuilder<VerticalsBloc, VerticalsState>(
        builder: (context, state) {
          if (state is VerticalsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is VerticalsError) {
            return Center(child: Text(state.message));
          }

          final verticals = (state as VerticalsLoaded).verticals;

          if (verticals.isEmpty) {
            return EmptyState(
              icon: Icons.category_outlined,
              title: 'لا يوجد قطاعات بعد',
              subtitle: 'أضف أول قطاع (مثلاً "أدوات حلاقة") للبدء بإنشاء متاجر.',
              actionLabel: 'إضافة قطاع',
              onAction: () => _openCreateDialog(context),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.xl),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 200,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            itemCount: verticals.length,
            itemBuilder: (context, index) {
              final v = verticals[index];
              return _VerticalCard(
                vertical: v,
                onEdit: () => _openEditDialog(context, v),
                onDelete: () => _confirmDelete(context, v),
              );
            },
          );
        },
      ),
    );
  }
}

class _VerticalCard extends StatelessWidget {
  final Vertical vertical;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VerticalCard({
    required this.vertical,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.sm,
                ),
                child: const Icon(Icons.category_outlined,
                    color: AppColors.primary, size: 18),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('تعديل الاسم'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                      SizedBox(width: 8),
                      Text('حذف', style: TextStyle(color: AppColors.danger)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(vertical.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(vertical.slug,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const Spacer(),
          StatusBadge(isActive: vertical.isActive),
        ],
      ),
    );
  }
}
