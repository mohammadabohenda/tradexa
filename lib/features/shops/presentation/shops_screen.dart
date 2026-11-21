import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../bloc/shops_bloc.dart';
import '../bloc/shops_event.dart';
import '../bloc/shops_state.dart';
import '../domain/shop.dart';
import 'shop_form_dialog.dart';

class ShopsScreen extends StatelessWidget {
  const ShopsScreen({super.key});

  void _openCreateDialog(BuildContext context) {
    final bloc = context.read<ShopsBloc>();
    showDialog(
      context: context,
      builder: (_) => ShopFormDialog(
        onSubmit: (request) {
          final completer = Completer<String?>();
          bloc.add(ShopCreated(request, (slug, error) {
            if (error == null && slug != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم إنشاء المحل — رابطه /s/$slug'),
                  duration: const Duration(seconds: 5),
                ),
              );
            }
            completer.complete(error);
          }));
          return completer.future;
        },
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, Shop shop) async {
    final bloc = context.read<ShopsBloc>();

    if (shop.isActive) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
          title: const Text('إيقاف المحل'),
          content: Text(
            'إيقاف "${shop.name}" رح يخلي رابطه يعرض «المتجر غير متاح» '
            'للزبائن، وصاحبه ما رح يقدر يستقبل طلبات جديدة.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('تراجع')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('إيقاف'),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
    }

    final completer = Completer<String?>();
    bloc.add(ShopActiveToggled(shop.id, !shop.isActive, completer.complete));
    final error = await completer.future;

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Shop shop) async {
    final bloc = context.read<ShopsBloc>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        title: const Text('حذف المحل'),
        content: Text(
          'حذف "${shop.name}" بيحذف منتجاته وأصنافه وطلباته نهائيًا.\n'
          'الأفضل توقفه بدل ما تحذفه.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف نهائيًا'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    final completer = Completer<String?>();
    bloc.add(ShopDeleted(shop.id, completer.complete));
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
      currentRoute: '/shops',
      pageTitle: 'المتاجر',
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add_business_outlined, size: 18),
          label: const Text('محل جديد'),
          onPressed: () => _openCreateDialog(context),
        ),
      ],
      child: BlocBuilder<ShopsBloc, ShopsState>(
        builder: (context, state) {
          if (state is ShopsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ShopsError) {
            return Center(child: Text(state.message));
          }

          final shops = (state as ShopsLoaded).shops;

          if (shops.isEmpty) {
            return EmptyState(
              icon: Icons.storefront_outlined,
              title: 'ما في متاجر بعد',
              subtitle: 'أنشئ أول محل — رح ينخلق معه حساب صاحبه تلقائيًا.',
              actionLabel: 'محل جديد',
              onAction: () => _openCreateDialog(context),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.xl),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 250,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            itemCount: shops.length,
            itemBuilder: (context, i) => _ShopCard(
              shop: shops[i],
              onToggleActive: () => _toggleActive(context, shops[i]),
              onDelete: () => _confirmDelete(context, shops[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  final Shop shop;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _ShopCard({
    required this.shop,
    required this.onToggleActive,
    required this.onDelete,
  });

  Color get _color {
    try {
      return Color(
          int.parse('FF${shop.primaryColor.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.12),
                  borderRadius: AppRadius.sm,
                ),
                alignment: Alignment.center,
                child: shop.logoUrl != null && shop.logoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: AppRadius.sm,
                        child: Image.network(shop.logoUrl!,
                            width: 42,
                            height: 42,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.storefront, color: _color, size: 20)),
                      )
                    : Icon(Icons.storefront, color: _color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shop.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    StatusBadge(
                        isActive: shop.isActive, inactiveLabel: 'موقوف'),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
                onSelected: (v) => v == 'toggle' ? onToggleActive() : onDelete(),
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'toggle',
                      child: Text(shop.isActive ? 'إيقاف' : 'تفعيل')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('حذف',
                          style: TextStyle(color: AppColors.danger))),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _LinkRow(slug: shop.slug),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  shop.hasOwner
                      ? '${shop.ownerFullName} (@${shop.ownerUsername})'
                      : 'ما في صاحب مرتبط',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: shop.hasOwner
                        ? AppColors.textSecondary
                        : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          const Divider(),
          Row(
            children: [
              _Stat(label: 'منتجات', value: '${shop.productsCount}'),
              _Stat(label: 'طلبات', value: '${shop.ordersCount}'),
              _Stat(label: 'العملة', value: shop.currencySymbol),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String slug;

  const _LinkRow({required this.slug});

  @override
  Widget build(BuildContext context) {
    final link = '/s/$slug';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(link,
                  style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppColors.primary)),
            ),
          ),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ الرابط')),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.copy, size: 15, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
