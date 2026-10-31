import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:trina_grid/trina_grid.dart';
import 'package:trina_grid/src/ui/cells/trina_auto_complete_cell.dart';

import '../../../mock/shared_mocks.mocks.dart';

/// A hardware barcode scanner types a code into the focused cell like a fast
/// keyboard and ends it with Enter or Tab. With `onScan` the cell hands that
/// code over instead of searching for it; typing by hand still searches.
void main() {
  late TrinaGridStateManager stateManager;
  late List<String> fetched;
  late List<String> scanned;

  setUp(() {
    stateManager = MockTrinaGridStateManager();
    when(stateManager.configuration).thenReturn(const TrinaGridConfiguration());
    when(stateManager.localeText).thenReturn(const TrinaGridLocaleText());
    when(stateManager.keepFocus).thenReturn(true);
    when(stateManager.hasFocus).thenReturn(true);
    when(stateManager.isEditing).thenReturn(true);
    when(stateManager.refRows).thenReturn(FilteredList<TrinaRow>());
    fetched = [];
    scanned = [];
  });

  Future<void> pumpCell(
    WidgetTester tester, {
    bool withScan = true,
    bool endsOnPause = false,
  }) async {
    final column = TrinaColumn(
      title: 'Product',
      field: 'product',
      type: TrinaColumnType.text(),
    );
    final cell = TrinaCell(value: '');
    final row = TrinaRow(cells: {'product': cell});
    when(stateManager.currentColumn).thenReturn(column);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          // Cell-sized, at the top: the list opens below it.
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              height: 40,
              child: TrinaAutoCompleteCell<String>(
                stateManager: stateManager,
                cell: cell,
                column: column,
                row: row,
                fetchItems: (query) async {
                  fetched.add(query);
                  return ['Soap', 'Sugar'];
                },
                width: 300,
                initialValue: null,
                onItemSelected: (_) {},
                itemBuilder: (context, item, selected) => Text(item),
                maxHeight: 200,
                onScan: withScan ? scanned.add : null,
                scanEndsOnPause: () => endsOnPause,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
  }

  /// Types [text] a character at a time; [gap] of real time between them
  /// (the cell times keys by the wall clock).
  Future<void> type(WidgetTester tester, String text, {Duration? gap}) async {
    for (var i = 1; i <= text.length; i++) {
      if (gap != null && i > 1) {
        await tester.runAsync(() => Future<void>.delayed(gap));
      }
      await tester.enterText(find.byType(TextField), text.substring(0, i));
    }
  }

  testWidgets('A scan ended by Enter goes to onScan, with no search or list', (
    tester,
  ) async {
    await pumpCell(tester);

    await type(tester, '726684515226');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 500));

    expect(scanned, ['726684515226']);
    expect(fetched, isEmpty);
    expect(find.text('Soap'), findsNothing);
    // The cell goes back to what it held; the code went to onScan.
    expect(find.text('726684515226'), findsNothing);
  });

  testWidgets('A scan ended by Tab goes to onScan too', (tester) async {
    await pumpCell(tester);

    await type(tester, '8901234567890');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 500));

    expect(scanned, ['8901234567890']);
    expect(fetched, isEmpty);
  });

  testWidgets('A code put in all at once, then Enter, is a scan', (
    tester,
  ) async {
    await pumpCell(tester);

    await tester.enterText(find.byType(TextField), '8901234567890');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 500));

    expect(scanned, ['8901234567890']);
    expect(fetched, isEmpty);
  });

  testWidgets('A scanner with no end key: the scan ends with the pause', (
    tester,
  ) async {
    await pumpCell(tester, endsOnPause: true);

    await type(tester, '8901234567890');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(scanned, ['8901234567890']);
    expect(fetched, isEmpty);
  });

  testWidgets('Without that setting, a scan with no end key is searched', (
    tester,
  ) async {
    await pumpCell(tester);

    await type(tester, '8901234567890');
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();

    expect(scanned, isEmpty);
    expect(fetched, ['8901234567890']);
  });

  testWidgets('Typing by hand searches once it pauses', (tester) async {
    await pumpCell(tester);

    await type(tester, 'soa', gap: const Duration(milliseconds: 80));
    expect(fetched, isEmpty);

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();

    expect(fetched, ['soa']);
    expect(find.text('Soap'), findsOneWidget);
    expect(scanned, isEmpty);
  });

  testWidgets('Without onScan, a fast burst still searches', (tester) async {
    await pumpCell(tester, withScan: false);

    await type(tester, '8901234567890');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    expect(fetched, ['8901234567890']);
    expect(scanned, isEmpty);
  });

  testWidgets('Enter while the list is still loading waits for it', (
    tester,
  ) async {
    await pumpCell(tester, withScan: false);

    await tester.enterText(find.byType(TextField), 'abc');
    // The list is open with its spinner; no item to select yet.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    expect(tester.takeException(), isNull);
    // The list stays and fills in, for the next Enter to pick from.
    expect(fetched, ['abc']);
    expect(find.text('Soap'), findsOneWidget);
  });
}
