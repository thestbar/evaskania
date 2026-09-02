import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_tokens.dart';

typedef ImagePickFn = Future<String?> Function(ImageSource source);

Future<String?> defaultPickImage(ImageSource source) async {
  final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
  return file?.path;
}

class ImageSlot extends StatelessWidget {
  const ImageSlot({
    super.key,
    required this.placeholder,
    required this.imagePath,
    required this.onImagePicked,
    this.height = 220,
    this.pickImage = defaultPickImage,
  });

  final String placeholder;
  final String? imagePath;
  final ValueChanged<String> onImagePicked;
  final double height;
  final ImagePickFn pickImage;

  Future<void> _handleTap(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Κάμερα'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Βιβλιοθήκη φωτογραφιών'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final path = await pickImage(source);
    if (path != null) onImagePicked(path);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTokens.colorSurface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: AppTokens.colorDivider),
        ),
        child: imagePath == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined,
                      size: 40, color: AppTokens.colorText.withValues(alpha: 0.45)),
                  const SizedBox(height: AppTokens.space2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
                    child: Text(
                      placeholder,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTokens.colorText.withValues(alpha: 0.7)),
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                child: Image.file(
                  File(imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: height,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: AppTokens.colorText.withValues(alpha: 0.45)),
                  ),
                ),
              ),
      ),
    );
  }
}
