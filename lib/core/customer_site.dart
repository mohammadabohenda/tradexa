/// رابط موقع الزبائن — يُحقن جوّا باركود بطاقة الدخول.
///
/// غيّر القيمة الافتراضية هون لما ترفع الموقع، أو مرّرها وقت
/// التشغيل بـ --dart-define=CUSTOMER_SITE_URL=https://...
class CustomerSite {
  static const baseUrl = 'https://e87ea18f.tredexa.pages.dev';

  /// الرابط اللي بينحط جوّا الـ QR. كاميرا الجوال بتفتحه مباشرة
  /// والموقع بيقرأ الرمز من ?t= ويسجّل الدخول تلقائيًا.
  static String loginUrl(String accessToken) =>
      '$baseUrl/login?t=$accessToken';
}