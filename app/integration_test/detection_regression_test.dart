// Exercises the REAL (non-mocked) ML Kit detectors on a connected device or
// emulator — unlike test/detection/*_test.dart, which inject a fake
// FaceDetectionSource/ImageLabelSource and never touch a platform channel.
//
// Added after a real-device bug report ("every photo gets rejected, no
// matter what I pick"), which turned out to be TWO separate bugs:
//
// 1. ML Kit's on-device face detector reliably misses faces cropped tight
//    to the frame edges — a close-up, edge-to-edge photo is a completely
//    natural way to frame "a face," and this app's own instructions
//    encourage getting close. face_edge_to_edge.jpg is that exact failing
//    case; MlKitFaceDetectionSource now pads the image before detecting to
//    work around it (see face_checker.dart).
//
// 2. On a real, current-Google-Play-Services device, the RELEASE (R8
//    minified) build crashed with a NullPointerException deep inside
//    com.google.android.gms.internal.mlkit_vision_common — the
//    face-detection AAR's own bundled consumer ProGuard rules don't cover
//    it. This never reproduced in a debug build, or on an emulator with an
//    older bundled Play Services version, which is why it slipped through
//    the first round of testing. Fixed in
//    android/app/proguard-rules.pro. Because of this, running this suite
//    ONLY in debug mode is not enough to catch a regression here — run it
//    both ways:
//
//   flutter test integration_test/detection_regression_test.dart -d <device>          # debug
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/detection_regression_test.dart -d <device> --profile  # minified, like release
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:evaskania/detection/cup_checker.dart';
import 'package:evaskania/detection/face_checker.dart';

Future<String> _assetToTempFile(String assetName) async {
  final bytes = await rootBundle.load('assets/diag/$assetName');
  final dir = await Directory.systemTemp.createTemp('detection_regression');
  final file = File('${dir.path}/$assetName');
  await file.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
  return file.path;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FaceChecker', () {
    testWidgets('accepts a face photographed edge-to-edge with no margin', (tester) async {
      final path = await _assetToTempFile('face_edge_to_edge.jpg');
      final result = await FaceChecker().check(path);
      expect(result, FaceCheckResult.ok);
    });

    testWidgets('accepts a normally framed face photo', (tester) async {
      final path = await _assetToTempFile('face_normal.jpg');
      final result = await FaceChecker().check(path);
      expect(result, FaceCheckResult.ok);
    });
  });

  group('CupChecker', () {
    testWidgets('accepts a normal photo of a mug', (tester) async {
      final path = await _assetToTempFile('cup_normal.jpg');
      final result = await CupChecker().check(path);
      expect(result, CupCheckResult.ok);
    });

    testWidgets('accepts a top-down photo of coffee grounds in a cup', (tester) async {
      final path = await _assetToTempFile('cup_grounds.jpg');
      final result = await CupChecker().check(path);
      expect(result, CupCheckResult.ok);
    });
  });
}
