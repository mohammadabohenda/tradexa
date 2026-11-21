import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/shop.dart';

class ShopFormDialog extends StatefulWidget {
  final Future<String?> Function(NewShopRequest request) onSubmit;

  const ShopFormDialog({super.key, required this.onSubmit});

  @override
  State<ShopFormDialog> createState() => _ShopFormDialogState();
}

class _ShopFormDialogState extends State<ShopFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _shopName = TextEditingController();
  final _slug = TextEditingController();
  final _color = TextEditingController(text: '#E8720C');
  final _currency = TextEditingController(text: 'ل.س');
  final _whatsapp = TextEditingController();
  final _maxQty = TextEditingController(text: '99');
  final _logo = TextEditingController();

  final _ownerName = TextEditingController();
  final _ownerUsername = TextEditingController();
  final _ownerPassword = TextEditingController();
  final _ownerPhone = TextEditingController();

  String _direction = 'rtl';
  bool _obscure = true;
  bool _slugTouched = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // نقترح الرابط من الاسم ما دام المستخدم ما عدّله بنفسه
    _shopName.addListener(() {
      if (_slugTouched) return;
      final suggestion = suggestSlug(_shopName.text);
      if (suggestion.isNotEmpty && suggestion != _slug.text) {
        _slug.text = suggestion;
      }
    });
  }

  @override
  void dispose() {
    for (final c in [
      _shopName, _slug, _color, _currency, _whatsapp, _maxQty, _logo,
      _ownerName, _ownerUsername, _ownerPassword, _ownerPhone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final wa = _whatsapp.text.replaceAll(RegExp(r'[^0-9]'), '');

    final error = await widget.onSubmit(NewShopRequest(
      shopName: _shopName.text.trim(),
      slug: _slug.text.trim().toLowerCase(),
      primaryColor: _color.text.trim(),
      currencySymbol: _currency.text.trim(),
      textDirection: _direction,
      whatsappNumber: wa.isEmpty ? null : wa,
      maxQtyPerItem: int.tryParse(_maxQty.text) ?? 99,
      logoUrl: _logo.text.trim().isEmpty ? null : _logo.text.trim(),
      ownerFullName: _ownerName.text.trim(),
      ownerUsername: _ownerUsername.text.trim(),
      ownerPassword: _ownerPassword.text,
      ownerPhone: _ownerPhone.text.trim().isEmpty ? null : _ownerPhone.text.trim(),
    ));

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _submitting = false;
        _error = error;
      });
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('محل جديد',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text(
                          'رح ينخلق المحل وحساب صاحبه ويتربطوا تلقائيًا',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed:
                        _submitting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    const _Section('بيانات المحل'),
                    const SizedBox(height: AppSpacing.sm),
                    const _Label('اسم المحل'),
                    TextFormField(
                      controller: _shopName,
                      decoration:
                          const InputDecoration(hintText: 'مثال: صالون الريان'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'اسم المحل مطلوب'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _Label('رابط المحل'),
                    TextFormField(
                      controller: _slug,
                      textDirection: TextDirection.ltr,
                      onChanged: (_) => _slugTouched = true,
                      decoration: const InputDecoration(
                        hintText: 'salon-alrayan',
                        prefixText: '/s/',
                      ),
                      validator: (v) {
                        final value = v?.trim().toLowerCase() ?? '';
                        if (value.isEmpty) return 'الرابط مطلوب';
                        if (!RegExp(r'^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$')
                            .hasMatch(value)) {
                          return 'حروف إنجليزية صغيرة وأرقام وشرطات، 3-40 خانة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'هاد الرابط اللي بتعطيه للزبائن — ما بينتغيّر بسهولة بعدين.',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _Label('اللون الأساسي'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _color,
                            textDirection: TextDirection.ltr,
                            onChanged: (_) => setState(() {}),
                            decoration:
                                const InputDecoration(hintText: '#E8720C'),
                            validator: (v) =>
                                RegExp(r'^#[0-9A-Fa-f]{6}$')
                                        .hasMatch(v?.trim() ?? '')
                                    ? null
                                    : 'الصيغة: #RRGGBB',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _parseColor(_color.text),
                            borderRadius: AppRadius.sm,
                            border: Border.all(color: AppColors.border),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Label('رمز العملة'),
                              TextFormField(
                                controller: _currency,
                                decoration:
                                    const InputDecoration(hintText: 'ل.س'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'مطلوب'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Label('حد الكمية بالصنف'),
                              TextFormField(
                                controller: _maxQty,
                                textDirection: TextDirection.ltr,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  final n = int.tryParse(v ?? '');
                                  return (n == null || n < 1)
                                      ? 'رقم أكبر من صفر'
                                      : null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _Label('اتجاه المتجر'),
                    Row(
                      children: [
                        Expanded(child: _dirOption('rtl', 'عربي (RTL)')),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: _dirOption('ltr', 'English (LTR)')),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _Label('رقم الواتساب (اختياري)'),
                    TextFormField(
                      controller: _whatsapp,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(hintText: '963912345678'),
                      validator: (v) {
                        final digits =
                            (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                        if (digits.isEmpty) return null;
                        return (digits.length < 8 || digits.length > 15)
                            ? 'رقم غير صحيح'
                            : null;
                      },
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'صيغة دولية بدون + ولا صفر بادئ.',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _Label('رابط اللوغو (اختياري)'),
                    TextFormField(
                      controller: _logo,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(hintText: 'https://…'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _Section('حساب صاحب المحل'),
                    const SizedBox(height: AppSpacing.sm),
                    const _Label('الاسم الكامل'),
                    TextFormField(
                      controller: _ownerName,
                      decoration:
                          const InputDecoration(hintText: 'مثال: محمد الأحمد'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'الاسم مطلوب'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _Label('اسم المستخدم'),
                    TextFormField(
                      controller: _ownerUsername,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(hintText: 'mohammad'),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'اسم المستخدم مطلوب';
                        if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(value)) {
                          return 'حروف إنجليزية وأرقام و_ فقط، 3-20 خانة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _Label('كلمة السر'),
                    TextFormField(
                      controller: _ownerPassword,
                      obscureText: _obscure,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: '6 خانات على الأقل',
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'كلمة السر مطلوبة';
                        if (v.length < 6) return '6 خانات على الأقل';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _Label('رقم الهاتف (اختياري)'),
                    TextFormField(
                      controller: _ownerPhone,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.phone,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppColors.dangerLight,
                            borderRadius: AppRadius.sm),
                        child: Text(_error!,
                            style: const TextStyle(
                                color: AppColors.danger, fontSize: 12.5)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('إنشاء المحل'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dirOption(String value, String label) {
    final selected = _direction == value;
    return Material(
      color: selected ? AppColors.primaryLight : AppColors.background,
      borderRadius: AppRadius.sm,
      child: InkWell(
        borderRadius: AppRadius.sm,
        onTap: () => setState(() => _direction = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.sm,
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary)),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: AppColors.primary));
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );
}
