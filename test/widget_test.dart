import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meraki/src/ui/widgets/cover_art_image.dart';

void main() {
  testWidgets('shows a fallback when cover art is absent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CoverArtImage(coverArtUrlOrPath: null)),
      ),
    );

    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
  });
}
