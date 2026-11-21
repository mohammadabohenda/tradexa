import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadException implements Exception {
  final String message;
  ImageUploadException(this.message);
}

/// يرفع صور المنتجات إلى Supabase Storage ويعيد رابطها العام.
class ProductImageStorage {
  final SupabaseClient _client;

  /// اسم الحاوية (Bucket) بـ Supabase Storage — لازم تكون منشأة
  /// ومعلّمة Public عشان الروابط تشتغل بدون مصادقة.
  static const bucket = 'product-images';

  ProductImageStorage(this._client);

  /// الحد الأقصى لحجم الصورة: 5 ميجابايت. نفحصه قبل الرفع عشان
  /// نعطي المستخدم رسالة واضحة بدل ما ينتظر رفع طويل ثم يفشل.
  static const maxSizeBytes = 5 * 1024 * 1024;

  static const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.lengthInBytes > maxSizeBytes) {
      throw ImageUploadException('حجم الصورة كبير — الحد الأقصى 5 ميجابايت');
    }

    final extension = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      throw ImageUploadException('صيغة غير مدعومة — استخدم JPG أو PNG أو WEBP');
    }

    // اسم فريد يمنع تصادم الملفات لو رفع مستخدمان صورة بنفس الاسم.
    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}.$extension';

    try {
      await _client.storage.from(bucket).uploadBinary(
            uniqueName,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$extension'),
          );

      return _client.storage.from(bucket).getPublicUrl(uniqueName);
    } on StorageException catch (e) {
      if (e.statusCode == '404') {
        throw ImageUploadException(
          'حاوية التخزين "$bucket" غير موجودة — أنشئها من Supabase Storage',
        );
      }
      throw ImageUploadException('تعذّر رفع الصورة، حاول مرة أخرى');
    } catch (_) {
      throw ImageUploadException('تعذّر رفع الصورة، تحقق من الاتصال');
    }
  }
}
