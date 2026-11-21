import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/app_user.dart';

/// بطاقة الدخول: تعرض رمز QR الخاص بالمستخدم بحجم قابل للطباعة.
/// المستخدم بيمسحها بكاميرا موبايله فبيفوت مباشرة بدون كتابة أي شي.
class UserBarcodeDialog extends StatelessWidget {
  final AppUser user;
  final Future<String?> Function() onRegenerate;

  const UserBarcodeDialog({
    super.key,
    required this.user,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final token = user.accessToken;

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('بطاقة الدخول',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (token == null || token.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text('لا يوجد رمز لهذا المستخدم — ولّد رمزًا جديدًا',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              else
                _PrintableCard(user: user, token: token),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: AppRadius.sm,
                ),
                child: const Text(
                  'هذا الرمز يعادل كلمة السر — أي حدا بيصوّره بيقدر يدخل بالحساب. '
                  'لو تسرّب، ولّد رمزًا جديدًا فورًا.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.danger, height: 1.5),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('نسخ الرمز'),
                      onPressed: (token == null || token.isEmpty)
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: token));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم نسخ الرمز')),
                              );
                            },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                      icon: const Icon(Icons.autorenew, size: 16),
                      label: const Text('رمز جديد'),
                      onPressed: () => _confirmRegenerate(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'للطباعة: اضغط Ctrl+P',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRegenerate(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        title: const Text('توليد رمز جديد'),
        content: const Text(
          'الرمز الحالي رح يصير غير صالح فورًا، وأي بطاقة مطبوعة منه '
          'ما رح تشتغل. لازم تعطي المستخدم البطاقة الجديدة.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('تراجع')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('توليد جديد'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final error = await onRegenerate();
    if (!context.mounted) return;

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'تم توليد رمز جديد — افتح البطاقة لعرضه'),
        backgroundColor: error != null ? AppColors.danger : null,
      ),
    );
  }
}

/// الجزء المخصص للطباعة — خلفية بيضاء وحواف واضحة عشان يطلع
/// نظيف على الورق.
class _PrintableCard extends StatelessWidget {
  final AppUser user;
  final String token;

  const _PrintableCard({required this.user, required this.token});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          const Text('TRADEXA',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          QrImageView(
            data: token,
            version: QrVersions.auto,
            size: 190,
            backgroundColor: Colors.white,
            // مستوى تصحيح خطأ عالٍ: البطاقة رح تنطبع وتتحمل خدوش
            // وانثناءات، وهاد بيخليها تنقرأ حتى لو تضررت جزئيًا.
            errorCorrectionLevel: QrErrorCorrectLevel.H,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(user.fullName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('@${user.username}',
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: 4),
          SelectableText(
            token,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 10.5,
                fontFamily: 'monospace',
                color: AppColors.textSecondary,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
