import 'dart:io';
import 'dart:typed_data';
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

  // Fraction of width/height added as a plain margin on every side before
  // handing the image to ML Kit. Confirmed by direct testing (real device
  // photos, both fast and accurate FaceDetectorMode): ML Kit's on-device
  // face detector misses faces cropped tight to the frame edges — the exact
  // same face pixels went from 0 detections to 1 once given a margin. A
  // close-up, edge-to-edge photo is a completely natural way to frame "a
  // face" (arguably what this app's own instructions encourage), so pad
  // defensively rather than relying on users to leave headroom.
  static const double _padFraction = 0.3;

  @override
  Future<List<Rect>> detectFaceBoxes(String imagePath) async {
    final original = await File(imagePath).readAsBytes();
    final padded = await _padWithMargin(original, _padFraction);
    final tempDir = await Directory.systemTemp.createTemp('face_pad');
    try {
      final tempFile = File('${tempDir.path}/padded.png');
      await tempFile.writeAsBytes(padded.bytes);
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final faces = await _detector.processImage(inputImage);
      // Boxes come back in the padded image's coordinate space; shift them
      // back so callers (FaceChecker's area-fraction check) see coordinates
      // relative to the original, unpadded image.
      return faces.map((f) => f.boundingBox.translate(-padded.padX, -padded.padY)).toList();
    } finally {
      await tempDir.delete(recursive: true);
    }
  }

  void dispose() => _detector.close();
}

class _PaddedImage {
  _PaddedImage(this.bytes, this.padX, this.padY);
  final Uint8List bytes;
  final double padX;
  final double padY;
}

Future<_PaddedImage> _padWithMargin(Uint8List bytes, double padFraction) async {
  final codec = await instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    final padX = image.width * padFraction;
    final padY = image.height * padFraction;
    final newWidth = (image.width + 2 * padX).round();
    final newHeight = (image.height + 2 * padY).round();

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
      Paint()..color = const Color(0xFF808080),
    );
    canvas.drawImage(image, Offset(padX, padY), Paint());
    final picture = recorder.endRecording();
    final paddedImage = await picture.toImage(newWidth, newHeight);
    try {
      final byteData = await paddedImage.toByteData(format: ImageByteFormat.png);
      return _PaddedImage(byteData!.buffer.asUint8List(), padX, padY);
    } finally {
      paddedImage.dispose();
    }
  } finally {
    image.dispose();
  }
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
