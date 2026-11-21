import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/empty_state.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_event.dart';
import '../bloc/orders_state.dart';
import '../domain/order.dart';
import 'manual_order_dialog.dart';
import 'order_status_badge.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  void _openCreateDialog(BuildContext context) {
    final bloc = context.read<OrdersBloc>();
    showDialog(
      context: context,
      builder: (_) => ManualOrderDialog(
        onSubmit: (result) {
          final completer = Completer<String?>();
          bloc.add(ManualOrderCreated(
            customerName: result.customerName,
            customerPhone: result.customerPhone,
            customerAddress: result.customerAddress,
            notes: result.notes,
            lines: result.lines,
            onComplete: completer.complete,
          ));
          return completer.future;
        },
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    Order order,
    OrderStatus status,
  ) async {
    final bloc = context.read<OrdersBloc>();

    if (status == OrderStatus.cancelled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
          title: const Text('تأكيد إلغاء الطلب'),
          content: const Text('إلغاء الطلب نهائي — ما رح تقدر ترجّعه لحالة سابقة.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('تراجع')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('إلغاء الطلب'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    final completer = Completer<String?>();
    bloc.add(OrderStatusChanged(order.id, status, completer.complete));
    final error = await completer.future;

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Order order) async {
    final bloc = context.read<OrdersBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        title: const Text('تأكيد حذف الطلب'),
        content: Text('حذف طلب "${order.customerName}" نهائيًا؟'),
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
    bloc.add(OrderDeleted(order.id, completer.complete));
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
      currentRoute: '/orders',
      pageTitle: 'الطلبات',
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: const Text('طلب يدوي'),
          onPressed: () => _openCreateDialog(context),
        ),
      ],
      child: Column(
        children: [
          const _StatusFilterBar(),
          Expanded(
            child: BlocBuilder<OrdersBloc, OrdersState>(
              builder: (context, state) {
                if (state is OrdersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is OrdersError) {
                  return Center(child: Text(state.message));
                }

                final loaded = state as OrdersLoaded;

                if (loaded.orders.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'لا يوجد طلبات',
                    subtitle: 'أنشئ طلبًا يدويًا لعميل اتصل فيك مباشرة.',
                    actionLabel: 'طلب يدوي',
                    onAction: () => _openCreateDialog(context),
                  );
                }

                return Column(
                  children: [
                    _TotalBar(total: loaded.displayedTotal, count: loaded.orders.length),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        itemCount: loaded.orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final order = loaded.orders[index];
                          return _OrderCard(
                            order: order,
                            onStatusChange: (status) => _changeStatus(context, order, status),
                            onDelete: () => _confirmDelete(context, order),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalBar extends StatelessWidget {
  final double total;
  final int count;

  const _TotalBar({required this.total, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 10),
      color: AppColors.background,
      child: Row(
        children: [
          Text('$count طلب',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          const Spacer(),
          const Text('إجمالي (بدون الملغي): ',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          Text(total.toStringAsFixed(2),
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          final current = state is OrdersLoaded ? state.activeFilter : null;

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
                  onTap: () =>
                      context.read<OrdersBloc>().add(const OrdersStatusFilterChanged(null)),
                ),
                ...OrderStatus.values.map((status) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _FilterChip(
                        label: status.label,
                        selected: current == status,
                        onTap: () => context
                            .read<OrdersBloc>()
                            .add(OrdersStatusFilterChanged(status)),
                      ),
                    )),
              ],
            ),
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
                  color:
                      selected ? AppColors.primary.withOpacity(0.3) : AppColors.border),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.primary : AppColors.textSecondary)),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final ValueChanged<OrderStatus> onStatusChange;
  final VoidCallback onDelete;

  const _OrderCard({
    required this.order,
    required this.onStatusChange,
    required this.onDelete,
  });

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}'
      ' — ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final nextStatuses = order.status.allowedNext;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.customerName,
                        style:
                            const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${order.customerPhone} • ${order.itemsCount} صنف • ${_formatDate(order.createdAt)}',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              OrderStatusBadge(status: order.status),
              const SizedBox(width: AppSpacing.md),
              Text(order.total.toStringAsFixed(2),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  } else {
                    onStatusChange(OrderStatus.fromValue(value));
                  }
                },
                itemBuilder: (_) => [
                  ...nextStatuses.map((s) => PopupMenuItem(
                        value: s.value,
                        child: Text('تغيير إلى: ${s.label}'),
                      )),
                  if (nextStatuses.isNotEmpty) const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('حذف الطلب', style: TextStyle(color: AppColors.danger)),
                  ),
                ],
              ),
            ],
          ),
          children: [
            if (order.customerAddress != null && order.customerAddress!.isNotEmpty) ...[
              _DetailLine(icon: Icons.place_outlined, text: order.customerAddress!),
              const SizedBox(height: 6),
            ],
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              _DetailLine(icon: Icons.sticky_note_2_outlined, text: order.notes!),
              const SizedBox(height: 6),
            ],
            const Divider(),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.sm,
                        child: item.productImageUrl != null &&
                                item.productImageUrl!.isNotEmpty
                            ? Image.network(item.productImageUrl!,
                                width: 34,
                                height: 34,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const _ItemPlaceholder())
                            : const _ItemPlaceholder(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child:
                            Text(item.productName, style: const TextStyle(fontSize: 13)),
                      ),
                      Text('${item.quantity} × ${item.unitPrice.toStringAsFixed(2)}',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: AppSpacing.md),
                      SizedBox(
                        width: 70,
                        child: Text(item.lineTotal.toStringAsFixed(2),
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ItemPlaceholder extends StatelessWidget {
  const _ItemPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(Icons.image_outlined, size: 14, color: AppColors.textSecondary),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}
