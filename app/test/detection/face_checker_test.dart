import 'package:flutter/material.dart' show Rect, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/detection/face_checker.dart';

class _FakeDetectionSource implements FaceDetectionSource {
  _FakeDetectionSource(this.boxes);
  final List<Rect> boxes;
  @override
  Future<List<Rect>> detectFaceBoxes(String imagePath) async => boxes;
}

class _FakeSizeReader implements ImageSizeReader {
  _FakeSizeReader(this.size);
  final Size size;
  @override
  Future<Size> readSize(String imagePath) async => size;
}

void main() {
  const imageSize = Size(1000, 1000); // 1,000,000 px^2 area

  test('no faces -> noFace', () async {
    final checker = FaceChecker(
      detectionSource: _FakeDetectionSource(const []),
      sizeReader: _FakeSizeReader(imageSize),
    );
    expect(await checker.check('/tmp/a.jpg'), FaceCheckResult.noFace);
  });

  test('exactly one significant face -> ok', () async {
    final checker = FaceChecker(
      detectionSource: _FakeDetectionSource([const Rect.fromLTWH(0, 0, 400, 400)]), // 16% of area
      sizeReader: _FakeSizeReader(imageSize),
    );
    expect(await checker.check('/tmp/a.jpg'), FaceCheckResult.ok);
  });

  test('two significant faces -> multipleFaces', () async {
    final checker = FaceChecker(
      detectionSource: _FakeDetectionSource([
        const Rect.fromLTWH(0, 0, 400, 400),
        const Rect.fromLTWH(500, 500, 400, 400),
      ]),
      sizeReader: _FakeSizeReader(imageSize),
    );
    expect(await checker.check('/tmp/a.jpg'), FaceCheckResult.multipleFaces);
  });

  test('a tiny background face below the area threshold is ignored', () async {
    final checker = FaceChecker(
      detectionSource: _FakeDetectionSource([
        const Rect.fromLTWH(0, 0, 400, 400), // 16% — the real subject
        const Rect.fromLTWH(900, 900, 50, 50), // 0.25% — a stray poster face
      ]),
      sizeReader: _FakeSizeReader(imageSize),
    );
    expect(await checker.check('/tmp/a.jpg'), FaceCheckResult.ok);
  });
}
