import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:photo_feed/widgets/folder_list_tile.dart';

void main() {
  Widget buildTile({
    String path = '/test/path',
    String label = 'Test',
    bool isSelected = false,
    bool isDefault = false,
    ValueChanged<bool?>? onChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: FolderListTile(
          path: path,
          label: label,
          isSelected: isSelected,
          isDefault: isDefault,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('renders label and path', (tester) async {
    await tester.pumpWidget(buildTile(
      path: '/home/user/Photos',
      label: 'Photos',
    ));

    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('/home/user/Photos'), findsOneWidget);
  });

  testWidgets('shows Default chip when isDefault is true', (tester) async {
    await tester.pumpWidget(buildTile(isDefault: true));
    expect(find.text('Default'), findsOneWidget);
  });

  testWidgets('does not show Default chip when isDefault is false',
      (tester) async {
    await tester.pumpWidget(buildTile(isDefault: false));
    expect(find.text('Default'), findsNothing);
  });

  testWidgets('checkbox reflects isSelected state', (tester) async {
    await tester.pumpWidget(buildTile(isSelected: true));
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
  });

  testWidgets('checkbox reflects unselected state', (tester) async {
    await tester.pumpWidget(buildTile(isSelected: false));
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isFalse);
  });

  testWidgets('calls onChanged when tapped', (tester) async {
    bool? tappedValue;
    await tester.pumpWidget(buildTile(
      isSelected: false,
      onChanged: (val) => tappedValue = val,
    ));

    await tester.tap(find.byType(CheckboxListTile));
    expect(tappedValue, isTrue);
  });

  testWidgets('shows folder icon', (tester) async {
    await tester.pumpWidget(buildTile());
    expect(find.byIcon(Icons.folder), findsOneWidget);
  });
}
