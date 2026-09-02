import 'dart:io';
import 'dart:ui';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum FaceCheckResult { ok, noFace, multipleFaces }

/// Seam over ML Kit's face detector so tests can inject a fake — platform
/// channels (which the real detector uses) don't work in `flutter test`'s
/// headless environment.
abstract class FaceDetectionSource {
  Future<List<Rect>> detectFaceBoxes(String imagePath);
}

class MlKitFaceDetectionSource implements FaceDetectionSource {
  final FaceDetector _detector = FaceDetector(options: FaceDetectorOptions());

  @override
  Future<List<Rect>> detectFaceBoxes(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await _detector.processImage(inputImage);
    return faces.map((f) => f.boundingBox).toList();
  }

  void dispose() => _detector.close();
}

/// Seam over reading an image file's pixel dimensions, for the same
/// testability reason as [FaceDetectionSource].
abstract class ImageSizeReader {
  Future<Size> readSize(String imagePath);
}

class UiImageSizeReader implements ImageSizeReader {
  @override
  Future<Size> readSize(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final buffer = await ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ImageDescriptor.encoded(buffer);
    final size = Size(descriptor.width.toDouble(), descriptor.height.toDouble());
    descriptor.dispose();
    buffer.dispose();
    return size;
  }
}

/// Ξεμάτιασμα's face check: pass only if exactly one face fills at least
/// [minAreaFraction] of the photo — filters out a stray face in the
/// background (a poster, someone walking by) without requiring the photo
/// be a tight headshot.
class FaceChecker {
  FaceChecker({
    FaceDetectionSource? detectionSource,
    ImageSizeReader? sizeReader,
    this.minAreaFraction = 0.05,
  })  : _detectionSource = detectionSource ?? MlKitFaceDetectionSource(),
        _sizeReader = sizeReader ?? UiImageSizeReader();

  final FaceDetectionSource _detectionSource;
  final ImageSizeReader _sizeReader;
  final double minAreaFraction;

  Future<FaceCheckResult> check(String imagePath) async {
    final boxes = await _detectionSource.detectFaceBoxes(imagePath);
    if (boxes.isEmpty) return FaceCheckResult.noFace;

    final imageSize = await _sizeReader.readSize(imagePath);
    final imageArea = imageSize.width * imageSize.height;

    final significant = boxes.where((box) {
      if (imageArea <= 0) return true;
      final boxArea = box.width * box.height;
      return (boxArea / imageArea) >= minAreaFraction;
    }).toList();

    if (significant.isEmpty) return FaceCheckResult.noFace;
    if (significant.length > 1) return FaceCheckResult.multipleFaces;
    return FaceCheckResult.ok;
  }

  void dispose() {
    final source = _detectionSource;
    if (source is MlKitFaceDetectionSource) source.dispose();
  }
}
