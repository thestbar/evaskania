import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:evaskania/widgets/image_slot.dart';

void main() {
  testWidgets('shows placeholder text when no image is picked', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ImageSlot(
          placeholder: 'Ρίξε τη φωτογραφία εδώ',
          imagePath: null,
          onImagePicked: (_) {},
          pickImage: (source) async => null,
        ),
      ),
    ));
    expect(find.text('Ρίξε τη φωτογραφία εδώ'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('shows an Image once imagePath is set', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ImageSlot(
          placeholder: 'Ρίξε τη φωτογραφία εδώ',
          imagePath: '/tmp/does-not-exist.jpg',
          onImagePicked: (_) {},
          pickImage: (source) async => null,
        ),
      ),
    ));
    expect(find.text('Ρίξε τη φωτογραφία εδώ'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('tapping opens a source sheet and reports the picked path', (tester) async {
    String? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ImageSlot(
          placeholder: 'Ρίξε τη φωτογραφία εδώ',
          imagePath: null,
          onImagePicked: (path) => picked = path,
          pickImage: (source) async {
            expect(source, ImageSource.gallery);
            return '/tmp/fake-photo.jpg';
          },
        ),
      ),
    ));

    await tester.tap(find.text('Ρίξε τη φωτογραφία εδώ'));
    await tester.pumpAndSettle(); // bottom sheet animates open

    await tester.tap(find.text('Βιβλιοθήκη φωτογραφιών'));
    await tester.pumpAndSettle(); // sheet closes, async pick resolves

    expect(picked, '/tmp/fake-photo.jpg');
  });
}
