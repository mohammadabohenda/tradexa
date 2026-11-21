import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../data/product_image_storage.dart';

enum ImageSourceMode { upload, url }

/// حقل صورة المنتج: يسمح إما برفع ملف من الجهاز (يُرفع مباشرة إلى
/// Supabase Storage وتُعاد الرابط)، أو بلصق رابط جاهز من الإنترنت.
/// بالحالتين النتيجة النهائية رابط نصّي يُخزَّن بعمود image_url.
class ProductImageField extends StatefulWidget {
  final String? initialUrl;
  final ProductImageStorage storage;
  final ValueChanged<String?> onChanged;

  const ProductImageField({
    super.key,
    required this.initialUrl,
    required this.storage,
    required this.onChanged,
  });

  @override
  State<ProductImageField> createState() => _ProductImageFieldState();
}

class _ProductImageFieldState extends State<ProductImageField> {
  late ImageSourceMode _mode;
  late TextEditingController _urlController;

  String? _resolvedUrl;
  Uint8List? _previewBytes;
  String? _pickedFileName;
  bool _isUploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolvedUrl = widget.initialUrl;
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
    _mode = ImageSourceMode.upload;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    setState(() => _error = null);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ProductImageStorage.allowedExtensions,
      withData: true, // ضروري على الويب للحصول على bytes مباشرة
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;

    if (bytes == null) {
      setState(() => _error = 'تعذّر قراءة الملف، حاول مرة أخرى');
      return;
    }

    setState(() {
      _isUploading = true;
      _previewBytes = bytes;
      _pickedFileName = file.name;
    });

    try {
      final url = await widget.storage.upload(bytes: bytes, fileName: file.name);
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _resolvedUrl = url;
      });
      widget.onChanged(url);
    } on ImageUploadException catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _previewBytes = null;
        _pickedFileName = null;
        _error = e.message;
      });
    }
  }

  void _clearImage() {
    setState(() {
      _resolvedUrl = null;
      _previewBytes = null;
      _pickedFileName = null;
      _urlController.clear();
      _error = null;
    });
    widget.onChanged(null);
  }

  void _switchMode(ImageSourceMode mode) {
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('صورة المنتج (اختياري)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ModeTab(
                icon: Icons.upload_file_outlined,
                label: 'من الجهاز',
                selected: _mode == ImageSourceMode.upload,
                onTap: () => _switchMode(ImageSourceMode.upload),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ModeTab(
                icon: Icons.link_outlined,
                label: 'رابط من النت',
                selected: _mode == ImageSourceMode.url,
                onTap: () => _switchMode(ImageSourceMode.url),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_mode == ImageSourceMode.upload)
          _UploadArea(
            isUploading: _isUploading,
            previewBytes: _previewBytes,
            resolvedUrl: _resolvedUrl,
            fileName: _pickedFileName,
            onPick: _pickAndUpload,
            onClear: _clearImage,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _urlController,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(hintText: 'https://example.com/image.jpg'),
                onChanged: (value) {
                  final trimmed = value.trim();
                  setState(() => _resolvedUrl = trimmed.isEmpty ? null : trimmed);
                  widget.onChanged(trimmed.isEmpty ? null : trimmed);
                },
              ),
              if (_resolvedUrl != null && _resolvedUrl!.startsWith('http')) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: AppRadius.sm,
                  child: Image.network(
                    _resolvedUrl!,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: AppColors.background,
                      alignment: Alignment.center,
                      child: const Text('تعذّر تحميل الصورة من هذا الرابط',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
        ],
      ],
    );
  }
}

class _ModeTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return Material(
      color: selected ? AppColors.primaryLight : AppColors.background,
      borderRadius: AppRadius.sm,
      child: InkWell(
        borderRadius: AppRadius.sm,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: AppRadius.sm,
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadArea extends StatelessWidget {
  final bool isUploading;
  final Uint8List? previewBytes;
  final String? resolvedUrl;
  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _UploadArea({
    required this.isUploading,
    required this.previewBytes,
    required this.resolvedUrl,
    required this.fileName,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = previewBytes != null || (resolvedUrl != null && resolvedUrl!.isNotEmpty);

    if (!hasImage) {
      return InkWell(
        borderRadius: AppRadius.sm,
        onTap: isUploading ? null : onPick,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadius.sm,
            border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppColors.textSecondary),
              SizedBox(height: 6),
              Text('اضغط لاختيار صورة من جهازك',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              SizedBox(height: 2),
              Text('JPG أو PNG أو WEBP — حتى 5 ميجابايت',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: AppRadius.sm,
          child: previewBytes != null
              ? Image.memory(previewBytes!, height: 120, width: double.infinity, fit: BoxFit.cover)
              : Image.network(resolvedUrl!, height: 120, width: double.infinity, fit: BoxFit.cover),
        ),
        if (isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: AppRadius.sm,
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text('جاري الرفع...',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          )
        else
          Positioned(
            top: 6,
            left: 6,
            child: Material(
              color: Colors.black.withOpacity(0.55),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
