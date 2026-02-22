import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:photo_feed/widgets/date_scrollbar.dart';

Widget _buildTestApp({
  required ScrollController controller,
  required List<String> yearMonths,
  required Map<String, int> photoCounts,
  required Widget child,
}) {
  return MaterialApp(
    home: Scaffold(
      body: DateScrollbar(
        controller: controller,
        yearMonths: yearMonths,
        photoCounts: photoCounts,
        child: child,
      ),
    ),
  );
}

void main() {
  group('DateScrollbar', () {
    late ScrollController controller;

    setUp(() {
      controller = ScrollController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders child and scrollbar', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        controller: controller,
        yearMonths: const ['2024-06'],
        photoCounts: const {'2024-06': 10},
        child: CustomScrollView(
          controller: controller,
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => SizedBox(height: 100, child: Text('Item $i')),
                childCount: 50,
              ),
            ),
          ],
        ),
      ));

      // Child content is rendered
      expect(find.text('Item 0'), findsOneWidget);
      // Scrollbar is present
      expect(find.byType(Scrollbar), findsOneWidget);
    });

    testWidgets('shows date label on scroll and hides after delay',
        (tester) async {
      final yearMonths = ['2024-01', '2024-06', '2024-12'];
      final photoCounts = {'2024-01': 20, '2024-06': 30, '2024-12': 50};

      await tester.pumpWidget(_buildTestApp(
        controller: controller,
        yearMonths: yearMonths,
        photoCounts: photoCounts,
        child: CustomScrollView(
          controller: controller,
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => SizedBox(height: 100, child: Text('Item $i')),
                childCount: 100,
              ),
            ),
          ],
        ),
      ));

      // Initially no date label visible
      expect(find.byType(AnimatedOpacity), findsNothing);

      // Scroll to trigger label
      controller.jumpTo(200);
      await tester.pump();

      // Date label should now be visible
      expect(find.byType(AnimatedOpacity), findsOneWidget);

      // Wait for hide timer (800ms) + animation
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 200));

      // Label should be hidden
      expect(find.byType(AnimatedOpacity), findsNothing);
    });

    testWidgets('displays correct date for scroll position', (tester) async {
      final yearMonths = ['2024-01', '2024-06'];
      final photoCounts = {'2024-01': 50, '2024-06': 50};

      await tester.pumpWidget(_buildTestApp(
        controller: controller,
        yearMonths: yearMonths,
        photoCounts: photoCounts,
        child: CustomScrollView(
          controller: controller,
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => SizedBox(height: 100, child: Text('Item $i')),
                childCount: 100,
              ),
            ),
          ],
        ),
      ));

      // Scroll a small amount near the top - should show first month
      controller.jumpTo(10);
      await tester.pump();

      // Label should display Jan 2024
      expect(find.textContaining('Jan'), findsOneWidget);
    });

    testWidgets('handles empty yearMonths gracefully', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        controller: controller,
        yearMonths: const [],
        photoCounts: const {},
        child: CustomScrollView(
          controller: controller,
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => SizedBox(height: 100, child: Text('Item $i')),
                childCount: 10,
              ),
            ),
          ],
        ),
      ));

      // Scroll - should not crash
      controller.jumpTo(100);
      await tester.pump();

      // No date label when yearMonths is empty
      expect(find.byType(AnimatedOpacity), findsNothing);
    });

    testWidgets('scroll to end shows last year-month', (tester) async {
      final yearMonths = ['2024-01', '2024-12'];
      final photoCounts = {'2024-01': 10, '2024-12': 90};

      await tester.pumpWidget(_buildTestApp(
        controller: controller,
        yearMonths: yearMonths,
        photoCounts: photoCounts,
        child: CustomScrollView(
          controller: controller,
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => SizedBox(height: 100, child: Text('Item $i')),
                childCount: 100,
              ),
            ),
          ],
        ),
      ));

      // Scroll to the very end
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();

      // Should show Dec 2024
      expect(find.textContaining('Dec'), findsOneWidget);
    });
  });
}
