import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../verticals/bloc/verticals_bloc.dart';
import '../../verticals/bloc/verticals_state.dart';
import '../../verticals/domain/vertical.dart';
import '../domain/store.dart';
import '../bloc/stores_bloc.dart';
import '../bloc/stores_event.dart';
import '../bloc/stores_state.dart';
import 'store_form_dialog.dart';
import 'company_edit_dialog.dart';
import 'change_plan_dialog.dart';

class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key});

  void _openCreateDialog(BuildContext context) {
    final bloc = context.read<StoresBloc>();
    showDialog(
      context: context,
      builder: (_) => StoreFormDialog(
        onSubmit: (result) {
          final completer = Completer<String?>();
          bloc.add(StoreCreated(
            storeName: result.storeName,
            verticalId: result.verticalId,
            ownerUsername: result.ownerUsername,
            ownerFullName: result.ownerFullName,
            ownerPhone: result.ownerPhone,
            ownerPassword: result.ownerPassword,
            onComplete: completer.complete,
          ));
          return completer.future;
        },
      ),
    );
  }

  void _openEditDialog(BuildContext context, Store store) {
    final bloc = context.read<StoresBloc>();
    showDialog(
      context: context,
      builder: (_) => CompanyEditDialog(
        store: store,
        onSubmit: (name, logoUrl, country) {
          final completer = Completer<String?>();
          bloc.add(StoreDetailsUpdated(
            storeId: store.id,
            name: name,
            logoUrl: logoUrl,
            country: country,
            onComplete: completer.complete,
          ));
          return completer.future;
        },
      ),
    );
  }

  void _openChangePlanDialog(BuildContext context, Store store) {
    final bloc = context.read<StoresBloc>();
    showDialog(
      context: context,
      builder: (_) => ChangePlanDialog(
        store: store,
        onSubmit: (plan, cycle) {
          final completer = Completer<String?>();
          bloc.add(StorePlanChanged(
            storeId: store.id,
            plan: plan,
            cycle: cycle,
            onComplete: completer.complete,
          ));
          return completer.future;
        },
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, Store store) async {
    final bloc = context.read<StoresBloc>();
    final completer = Completer<String?>();
    bloc.add(StoreActiveToggled(store.id, !store.isActive, completer.complete));
    final error = await completer.future;

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Store store) async {
    final bloc = context.read<StoresBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        title: const Text('تأكيد حذف الشركة'),
        content: Text(
          'هل أنت متأكد من حذف "${store.name}"؟\n'
          'إذا كان للشركة طلبات سابقة، ننصح بإيقافها بدل حذفها.',
        ),
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
    bloc.add(StoreDeleted(store.id, completer.complete));
    final error = await completer.future;

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _supportLogin(BuildContext context, Store store) async {
    final bloc = context.read<StoresBloc>();
    final completer = Completer<(String?, String?)>();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري إنشاء رابط الدخول...'), duration: Duration(seconds: 2)),
    );

    bloc.add(SupportLoginRequested(store.ownerId, (link, error) {
      completer.complete((link, error));
    }));

    final (link, error) = await completer.future;
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (link != null) {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _openCompanyDetail(BuildContext context, Store store) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('لوحة تفاصيل "${store.name}" — ميزة قادمة')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/stores',
      pageTitle: 'الشركات',
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: const Text('شركة جديدة'),
          onPressed: () => _openCreateDialog(context),
        ),
      ],
      child: Column(
        children: [
          const _VerticalFilterBar(),
          Expanded(
            child: BlocBuilder<StoresBloc, StoresState>(
              builder: (context, state) {
                if (state is StoresLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is StoresError) {
                  return Center(child: Text(state.message));
                }

                final stores = (state as StoresLoaded).stores;

                if (stores.isEmpty) {
                  return EmptyState(
                    icon: Icons.apartment_outlined,
                    title: 'لا يوجد شركات بعد',
                    subtitle: 'أضف أول شركة داخل أحد القطاعات للبدء.',
                    actionLabel: 'إضافة شركة',
                    onAction: () => _openCreateDialog(context),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisExtent: 340,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    final store = stores[index];
                    return _CompanyCard(
                      store: store,
                      onOpenDashboard: () => _openCompanyDetail(context, store),
                      onEdit: () => _openEditDialog(context, store),
                      onToggleActive: () => _toggleActive(context, store),
                      onDelete: () => _confirmDelete(context, store),
                      onChangePlan: () => _openChangePlanDialog(context, store),
                      onSupportLogin: () => _supportLogin(context, store),
                    );
                  },
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

          return BlocBuilder<StoresBloc, StoresState>(
            builder: (context, sState) {
              final currentFilter = sState is StoresLoaded ? sState.activeFilterVerticalId : null;

              return Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'الكل',
                    selected: currentFilter == null,
                    onTap: () =>
                        context.read<StoresBloc>().add(const StoresVerticalFilterChanged(null)),
                  ),
                  ...verticals.map((v) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: _FilterChip(
                          label: v.name,
                          selected: currentFilter == v.id,
                          onTap: () =>
                              context.read<StoresBloc>().add(StoresVerticalFilterChanged(v.id)),
                        ),
                      )),
                ],
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
              border: Border.all(color: selected ? AppColors.primary.withOpacity(0.3) : AppColors.border),
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

class _CompanyCard extends StatelessWidget {
  final Store store;
  final VoidCallback onOpenDashboard;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback onChangePlan;
  final VoidCallback onSupportLogin;

  const _CompanyCard({
    required this.store,
    required this.onOpenDashboard,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
    required this.onChangePlan,
    required this.onSupportLogin,
  });

  Color get _planColor {
    switch (store.subscriptionPlan) {
      case SubscriptionPlan.starter:
        return AppColors.textSecondary;
      case SubscriptionPlan.business:
        return AppColors.primary;
      case SubscriptionPlan.enterprise:
        return AppColors.secondary;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return 'قبل ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'قبل ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'قبل ${diff.inMinutes} دقيقة';
    return 'الآن';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.md,
        child: InkWell(
          borderRadius: AppRadius.md,
          onTap: onOpenDashboard,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CompanyLogo(logoUrl: store.logoUrl, name: store.name),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(store.name,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(store.verticalName,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
                      onSelected: (value) {
                        switch (value) {
                          case 'open':
                            onOpenDashboard();
                            break;
                          case 'edit':
                            onEdit();
                            break;
                          case 'toggle':
                            onToggleActive();
                            break;
                          case 'plan':
                            onChangePlan();
                            break;
                          case 'support':
                            onSupportLogin();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'open', child: Text('فتح لوحة الشركة')),
                        const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                        const PopupMenuItem(value: 'plan', child: Text('تغيير الباقة')),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(store.isActive ? 'إيقاف' : 'تفعيل'),
                        ),
                        const PopupMenuItem(value: 'support', child: Text('تسجيل الدخول كمشرف')),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('حذف', style: TextStyle(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    StatusBadge(isActive: store.isActive, inactiveLabel: 'موقوفة'),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _planColor.withOpacity(0.1),
                        borderRadius: AppRadius.sm,
                      ),
                      child: Text(
                        '${store.subscriptionPlan.label} • ${store.billingCycle.label}',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _planColor),
                      ),
                    ),
                  ],
                ),
                if (store.country != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(store.country!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
                const Spacer(),
                const Divider(),
                Row(
                  children: [
                    _StatItem(label: 'عملاء', value: '${store.customersCount ?? 0}'),
                    _StatItem(label: 'منتجات', value: '${store.productsCount ?? 0}'),
                    _StatItem(label: 'طلبات', value: '${store.ordersCount ?? 0}'),
                  ],
                ),
                const SizedBox(height: 6),
                Text('آخر نشاط: ${_timeAgo(store.lastActivity)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  final String? logoUrl;
  final String name;

  const _CompanyLogo({required this.logoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    if (logoUrl == null || logoUrl!.isEmpty) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.sm),
        alignment: Alignment.center,
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
      );
    }

    return ClipRRect(
      borderRadius: AppRadius.sm,
      child: Image.network(
        logoUrl!,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 42,
          height: 42,
          color: AppColors.primaryLight,
          alignment: Alignment.center,
          child: const Icon(Icons.apartment_outlined, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
