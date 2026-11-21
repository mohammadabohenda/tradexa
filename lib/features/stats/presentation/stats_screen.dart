import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/empty_state.dart';
import '../bloc/stats_bloc.dart';
import '../bloc/stats_event.dart';
import '../bloc/stats_state.dart';
import '../data/stats_repository.dart';
import '../domain/stats.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/stats',
      pageTitle: 'الأرباح والمبيعات',
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('تحديث'),
          onPressed: () => context.read<StatsBloc>().add(const StatsRequested()),
        ),
      ],
      child: BlocBuilder<StatsBloc, StatsState>(
        builder: (context, state) {
          if (state is StatsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is StatsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<StatsBloc>().add(const StatsRequested()),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final loaded = state as StatsLoaded;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryCards(summary: loaded.summary),
                const SizedBox(height: AppSpacing.xl),
                _TopProductsSection(
                  products: loaded.topProducts,
                  sortBy: loaded.sortBy,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final ProfitSummary summary;

  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('محقّق فعليًا', subtitle: 'من الطلبات المسلَّمة'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'صافي الربح',
                value: summary.realizedProfit,
                icon: Icons.trending_up,
                color: AppColors.success,
                emphasized: true,
                footnote: 'هامش ${summary.realizedMarginPercent.toStringAsFixed(1)}%',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                label: 'إجمالي المبيعات',
                value: summary.realizedRevenue,
                icon: Icons.payments_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _CountCard(
                label: 'طلبات مسلَّمة',
                count: summary.ordersDelivered,
                icon: Icons.check_circle_outline,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SectionTitle('قيد التنفيذ',
            subtitle: 'طلبات لسا ما تسلّمت — أرباح متوقّعة مش مؤكّدة'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'ربح معلّق',
                value: summary.pendingProfit,
                icon: Icons.hourglass_empty,
                color: const Color(0xFFB8860B),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _CountCard(
                label: 'طلبات قيد التنفيذ',
                count: summary.ordersPending,
                icon: Icons.local_shipping_outlined,
                color: const Color(0xFF2E6FA8),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _CountCard(
                label: 'إجمالي القطع المباعة',
                count: summary.unitsSold,
                icon: Icons.inventory_2_outlined,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionTitle(this.title, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        if (subtitle != null)
          Text(subtitle!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final bool emphasized;
  final String? footnote;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.emphasized = false,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: emphasized ? color.withOpacity(0.06) : AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(
            color: emphasized ? color.withOpacity(0.3) : AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value.toStringAsFixed(2),
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: emphasized ? 26 : 22,
              fontWeight: FontWeight.w700,
              color: value < 0 ? AppColors.danger : color,
            ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: 2),
            Text(footnote!,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _CountCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

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
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('$count',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _TopProductsSection extends StatelessWidget {
  final List<ProductStat> products;
  final StatsSortBy sortBy;

  const _TopProductsSection({required this.products, required this.sortBy});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle('أفضل المنتجات')),
            ...StatsSortBy.values.map((s) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _SortChip(
                    label: s.label,
                    selected: sortBy == s,
                    onTap: () => context.read<StatsBloc>().add(StatsSortChanged(s)),
                  ),
                )),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: EmptyState(
              icon: Icons.bar_chart_outlined,
              title: 'ما في مبيعات بعد',
              subtitle: 'الإحصائيات رح تظهر بعد أول طلب مؤكّد.',
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.md,
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                const _TableHeader(),
                ...List.generate(products.length, (i) {
                  return _ProductStatRow(
                    stat: products[i],
                    rank: i + 1,
                    isLast: i == products.length - 1,
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({required this.label, required this.selected, required this.onTap});

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
          SizedBox(width: 36, child: Text('#', style: style)),
          SizedBox(width: 52, child: Text('', style: style)),
          Expanded(flex: 2, child: Text('المنتج', style: style)),
          Expanded(flex: 1, child: Text('قطع مباعة', style: style)),
          Expanded(flex: 1, child: Text('عدد الطلبات', style: style)),
          Expanded(flex: 1, child: Text('المبيعات', style: style)),
          Expanded(flex: 1, child: Text('الربح', style: style)),
        ],
      ),
    );
  }
}

class _ProductStatRow extends StatelessWidget {
  final ProductStat stat;
  final int rank;
  final bool isLast;

  const _ProductStatRow({
    required this.stat,
    required this.rank,
    required this.isLast,
  });

  /// الثلاثة الأوائل بيتميزوا بلون — بيخلي القائمة تُقرأ بلمحة.
  Color? get _rankColor {
    if (rank == 1) return const Color(0xFFD4AF37);
    if (rank == 2) return const Color(0xFF9CA3AF);
    if (rank == 3) return const Color(0xFFB87333);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColor;
    final profitColor = stat.profit >= 0 ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: rankColor != null
                ? Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                        color: rankColor.withOpacity(0.15), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('$rank',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: rankColor)),
                  )
                : Text('$rank',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          SizedBox(
            width: 52,
            child: _Thumbnail(imageUrl: stat.imageUrl),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                Text('ربح القطعة ${stat.unitProfit.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text('${stat.unitsSold}',
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            flex: 1,
            child: Text('${stat.ordersCount}',
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 1,
            child: Text(stat.revenue.toStringAsFixed(2),
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 12.5)),
          ),
          Expanded(
            flex: 1,
            child: Text(stat.profit.toStringAsFixed(2),
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: profitColor)),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? imageUrl;

  const _Thumbnail({required this.imageUrl});

  Widget _placeholder() => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.sm,
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.image_outlined, size: 16, color: AppColors.textSecondary),
      );

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) return _placeholder();

    return ClipRRect(
      borderRadius: AppRadius.sm,
      child: Image.network(
        imageUrl!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }
}
