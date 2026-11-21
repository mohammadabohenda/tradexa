import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../bloc/users_bloc.dart';
import '../bloc/users_event.dart';
import '../bloc/users_state.dart';
import '../domain/app_user.dart';
import 'user_barcode_dialog.dart';
import 'user_form_dialog.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  void _openCreateDialog(BuildContext context) {
    final bloc = context.read<UsersBloc>();
    showDialog(
      context: context,
      builder: (_) => UserFormDialog(
        onSubmit: (result) {
          final completer = Completer<String?>();
          bloc.add(UserCreated(
            username: result.username,
            fullName: result.fullName,
            password: result.password,
            phone: result.phone,
            role: result.role,
            onComplete: completer.complete,
          ));
          return completer.future;
        },
      ),
    );
  }

  void _openBarcode(BuildContext context, AppUser user) {
    final bloc = context.read<UsersBloc>();
    showDialog(
      context: context,
      builder: (_) => UserBarcodeDialog(
        user: user,
        onRegenerate: () {
          final completer = Completer<String?>();
          bloc.add(UserTokenRegenerated(user.id, (token, error) {
            completer.complete(error);
          }));
          return completer.future;
        },
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, AppUser user) async {
    final bloc = context.read<UsersBloc>();

    if (user.isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
          title: const Text('إيقاف المستخدم'),
          content: Text(
              'إيقاف "${user.fullName}" رح يمنعه من الدخول — الباركود تبعه ما رح يشتغل.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('تراجع')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('إيقاف'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    final completer = Completer<String?>();
    bloc.add(UserActiveToggled(user.id, !user.isActive, completer.complete));
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
      currentRoute: '/users',
      pageTitle: 'المستخدمون',
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.person_add_alt, size: 18),
          label: const Text('مستخدم جديد'),
          onPressed: () => _openCreateDialog(context),
        ),
      ],
      child: Column(
        children: [
          const _FilterBar(),
          Expanded(
            child: BlocBuilder<UsersBloc, UsersState>(
              builder: (context, state) {
                if (state is UsersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is UsersError) {
                  return Center(child: Text(state.message));
                }

                final users = (state as UsersLoaded).users;

                if (users.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_outline,
                    title: 'لا يوجد مستخدمون',
                    subtitle: 'أضف أول مستخدم — رح ينولّدله باركود دخول تلقائيًا.',
                    actionLabel: 'مستخدم جديد',
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
                        ...List.generate(users.length, (i) {
                          return _UserRow(
                            user: users[i],
                            isLast: i == users.length - 1,
                            onShowBarcode: () => _openBarcode(context, users[i]),
                            onToggleActive: () => _toggleActive(context, users[i]),
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

class _FilterBar extends StatefulWidget {
  const _FilterBar();

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// نأخّر البحث نصف ثانية بعد آخر ضغطة — بدون هيك كل حرف بيطلق
  /// استعلامًا لقاعدة البيانات.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) context.read<UsersBloc>().add(UsersSearchChanged(value));
    });
  }

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
      child: BlocBuilder<UsersBloc, UsersState>(
        builder: (context, state) {
          final current = state is UsersLoaded ? state.activeRoleFilter : null;

          return Row(
            children: [
              SizedBox(
                width: 260,
                height: 38,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'بحث بالاسم أو اسم المستخدم أو الهاتف',
                    prefixIcon: Icon(Icons.search, size: 18),
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              _FilterChip(
                label: 'الكل',
                selected: current == null,
                onTap: () =>
                    context.read<UsersBloc>().add(const UsersRoleFilterChanged(null)),
              ),
              ...UserRole.values.map((role) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _FilterChip(
                      label: role.label,
                      selected: current == role,
                      onTap: () =>
                          context.read<UsersBloc>().add(UsersRoleFilterChanged(role)),
                    ),
                  )),
            ],
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

class _TableHeader extends StatelessWidget {
  const _TableHeader();

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
          Expanded(flex: 2, child: Text('الاسم', style: style)),
          Expanded(flex: 1, child: Text('اسم المستخدم', style: style)),
          Expanded(flex: 1, child: Text('الهاتف', style: style)),
          Expanded(flex: 1, child: Text('الدور', style: style)),
          Expanded(flex: 1, child: Text('الحالة', style: style)),
          SizedBox(width: 150, child: Text('', style: style)),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final AppUser user;
  final bool isLast;
  final VoidCallback onShowBarcode;
  final VoidCallback onToggleActive;

  const _UserRow({
    required this.user,
    required this.isLast,
    required this.onShowBarcode,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor =
        user.role == UserRole.platformAdmin ? AppColors.primary : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(user.initial,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13, color: roleColor)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text('@${user.username}',
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 1,
            child: Text(user.phone ?? '—',
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 12.5)),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: AppRadius.sm,
              ),
              child: Text(user.role.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: roleColor)),
            ),
          ),
          Expanded(
            flex: 1,
            child: StatusBadge(isActive: user.isActive, inactiveLabel: 'موقوف'),
          ),
          SizedBox(
            width: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.qr_code_2, size: 15),
                  label: const Text('الباركود', style: TextStyle(fontSize: 11.5)),
                  onPressed: onShowBarcode,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz,
                      color: AppColors.textSecondary, size: 20),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
                  onSelected: (_) => onToggleActive(),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(user.isActive ? 'إيقاف' : 'تفعيل'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
