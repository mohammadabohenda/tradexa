import 'package:flutter_test/flutter_test.dart';
import 'package:tradexa_admin/features/verticals/domain/vertical.dart';

void main() {
  group('generateSlug', () {
    test('يحوّل اسم عربي بمسافات إلى slug صالح بدون مسافات', () {
      final slug = generateSlug('أدوات حلاقة');
      expect(slug.contains(' '), isFalse);
      expect(slug, contains('-'));
    });

    test('يحوّل اسم إنجليزي لحروف صغيرة', () {
      final slug = generateSlug('Barber Tools');
      expect(slug.startsWith('barber-tools'), isTrue);
    });

    test('لا يرمي استثناء مع اسم فارغ ويولّد قيمة احتياطية', () {
      final slug = generateSlug('   ');
      expect(slug.startsWith('vertical-'), isTrue);
    });
  });
}
