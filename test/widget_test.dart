import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_music/app.dart';

void main() {
  testWidgets('App launches and shows black screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ScrollMusicApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
