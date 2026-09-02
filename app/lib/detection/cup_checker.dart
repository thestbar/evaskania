import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

enum CupCheckResult { ok, notACup }

/// Seam over ML Kit's image labeler so tests can inject a fake — platform
/// channels (which the real labeler uses) don't work in `flutter test`'s
/// headless environment.
abstract class ImageLabelSource {
  Future<List<MapEntry<String, double>>> labelImage(String imagePath);
}

class MlKitImageLabelSource implements ImageLabelSource {
  MlKitImageLabelSource({double confidenceThreshold = 0.6})
      : _labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: confidenceThreshold));

  final ImageLabeler _labeler;

  @override
  Future<List<MapEntry<String, double>>> labelImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final labels = await _labeler.processImage(inputImage);
    return labels.map((l) => MapEntry(l.label, l.confidence)).toList();
  }

  void dispose() => _labeler.close();
}

/// Ο Καφές's cup check: pass if the on-device image classifier returns any
/// cup/mug-family label at or above [minConfidence]. This is deliberately
/// coarse (see the spec's "Known trade-offs") — it can't tell an empty cup
/// with visible grounds from a full one, only that a cup-shaped object is
/// in the photo.
class CupChecker {
  CupChecker({ImageLabelSource? labelSource, this.minConfidence = 0.6})
      : _labelSource = labelSource ?? MlKitImageLabelSource(confidenceThreshold: minConfidence);

  final ImageLabelSource _labelSource;
  final double minConfidence;

  static const Set<String> _cupLabels = {
    'cup',
    'coffee cup',
    'mug',
    'espresso',
    'teacup',
    'drinkware',
    'saucer',
    'tableware',
  };

  Future<CupCheckResult> check(String imagePath) async {
    final labels = await _labelSource.labelImage(imagePath);
    final hasCup = labels.any(
      (entry) => _cupLabels.contains(entry.key.toLowerCase()) && entry.value >= minConfidence,
    );
    return hasCup ? CupCheckResult.ok : CupCheckResult.notACup;
  }

  void dispose() {
    final source = _labelSource;
    if (source is MlKitImageLabelSource) source.dispose();
  }
}
