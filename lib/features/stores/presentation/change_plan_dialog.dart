import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/store.dart';

class ChangePlanDialog extends StatefulWidget {
  final Store store;
  final Future<String?> Function(SubscriptionPlan plan, BillingCycle cycle) onSubmit;

  const ChangePlanDialog({super.key, required this.store, required this.onSubmit});

  @override
  State<ChangePlanDialog> createState() => _ChangePlanDialogState();
}

class _ChangePlanDialogState extends State<ChangePlanDialog> {
  late SubscriptionPlan _selectedPlan = widget.store.subscriptionPlan;
  late BillingCycle _selectedCycle = widget.store.billingCycle;
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _handleSubmit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final error = await widget.onSubmit(_selectedPlan, _selectedCycle);
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
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('تغيير باقة "${widget.store.name}"',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.lg),
              const Text('الباقة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...SubscriptionPlan.values.map((plan) => _PlanTile(
                    plan: plan,
                    selected: _selectedPlan == plan,
                    onTap: () => setState(() => _selectedPlan = plan),
                  )),
              const SizedBox(height: AppSpacing.md),
              const Text('دورة الفوترة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: BillingCycle.values
                    .map((cycle) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _CycleChip(
                              cycle: cycle,
                              selected: _selectedCycle == cycle,
                              onTap: () => setState(() => _selectedCycle = cycle),
                            ),
                          ),
                        ))
                    .toList(),
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
                          : const Text('تأكيد التغيير'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  const _PlanTile({required this.plan, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.primaryLight : AppColors.background,
        borderRadius: AppRadius.sm,
        child: InkWell(
          borderRadius: AppRadius.sm,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: AppRadius.sm,
              border: Border.all(color: selected ? AppColors.primary : AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 18,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(plan.label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.primary : AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CycleChip extends StatelessWidget {
  final BillingCycle cycle;
  final bool selected;
  final VoidCallback onTap;

  const _CycleChip({required this.cycle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : AppColors.background,
      borderRadius: AppRadius.sm,
      child: InkWell(
        borderRadius: AppRadius.sm,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: AppRadius.sm,
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(cycle.label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textSecondary)),
        ),
      ),
    );
  }
}
