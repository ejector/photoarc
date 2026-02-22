import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:photo_feed/app.dart';

void main() {
  testWidgets('App builds and renders with Material 3 theme', (WidgetTester tester) async {
    await tester.pumpWidget(const PhotoFeedApp());

    // Verify the app renders with the correct title
    expect(find.text('Select Folders'), findsOneWidget);

    // Verify the folder selection placeholder text is shown
    expect(find.text('Folder selection will be implemented here.'), findsOneWidget);
  });

  testWidgets('Navigation routes are configured', (WidgetTester tester) async {
    await tester.pumpWidget(const PhotoFeedApp());

    // Navigate to scanning screen
    Navigator.of(tester.element(find.byType(Scaffold))).pushNamed('/scanning');
    await tester.pumpAndSettle();
    expect(find.text('Scanning'), findsOneWidget);

    // Navigate to feed screen
    Navigator.of(tester.element(find.byType(Scaffold))).pushNamed('/feed');
    await tester.pumpAndSettle();
    expect(find.text('PhotoFeed'), findsOneWidget);
  });

  testWidgets('App uses Material 3', (WidgetTester tester) async {
    await tester.pumpWidget(const PhotoFeedApp());

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.useMaterial3, isTrue);
  });
}
