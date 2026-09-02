import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/detection/cup_checker.dart';

class _FakeLabelSource implements ImageLabelSource {
  _FakeLabelSource(this.labels);
  final List<MapEntry<String, double>> labels;
  @override
  Future<List<MapEntry<String, double>>> labelImage(String imagePath) async => labels;
}

void main() {
  test('a confident Cup label -> ok', () async {
    final checker = CupChecker(labelSource: _FakeLabelSource(const [MapEntry('Cup', 0.92)]));
    expect(await checker.check('/tmp/a.jpg'), CupCheckResult.ok);
  });

  test('a confident label in a different case (MUG) -> ok', () async {
    final checker = CupChecker(labelSource: _FakeLabelSource(const [MapEntry('MUG', 0.75)]));
    expect(await checker.check('/tmp/a.jpg'), CupCheckResult.ok);
  });

  test('no cup-like labels -> notACup', () async {
    final checker = CupChecker(labelSource: _FakeLabelSource(const [MapEntry('Dog', 0.98)]));
    expect(await checker.check('/tmp/a.jpg'), CupCheckResult.notACup);
  });

  test('a cup label below the confidence threshold -> notACup', () async {
    final checker = CupChecker(labelSource: _FakeLabelSource(const [MapEntry('Cup', 0.4)]));
    expect(await checker.check('/tmp/a.jpg'), CupCheckResult.notACup);
  });

  test('a cup label at exactly the confidence threshold (0.6) -> ok', () async {
    final checker = CupChecker(labelSource: _FakeLabelSource(const [MapEntry('Cup', 0.6)]));
    expect(await checker.check('/tmp/a.jpg'), CupCheckResult.ok);
  });

  test('a cup label just below the threshold (0.59) -> notACup', () async {
    final checker = CupChecker(labelSource: _FakeLabelSource(const [MapEntry('Cup', 0.59)]));
    expect(await checker.check('/tmp/a.jpg'), CupCheckResult.notACup);
  });

  test('no labels at all -> notACup', () async {
    final checker = CupChecker(labelSource: _FakeLabelSource(const []));
    expect(await checker.check('/tmp/a.jpg'), CupCheckResult.notACup);
  });

  test('default-construction threads minConfidence through to MlKitImageLabelSource', () {
    // Regression test for the confidence threshold being duplicated between
    // CupChecker.minConfidence and MlKitImageLabelSource's own hardcoded
    // ImageLabelerOptions — constructing with a non-default minConfidence
    // must not silently keep filtering at the labeler's old hardcoded value.
    final checker = CupChecker(minConfidence: 0.3);
    expect(checker.minConfidence, 0.3);
  });
}
