import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../helper/trina_widget_test_helper.dart';

/// Test for calling a popup grid with a keyboard and selecting a date
void main() {
  TrinaGridStateManager? stateManager;

  buildGrid({
    int numberOfRows = 10,
    int numberOfColumns = 10,
    TrinaGridConfiguration configuration = const TrinaGridConfiguration(),
  }) {
    // given
    final columns = [
      TrinaColumn(
        title: 'date',
        field: 'date',
        type: TrinaColumnType.date(
          startDate: DateTime.parse('2020-01-01'),
          endDate: DateTime.parse('2020-01-31'),
        ),
      )
    ];

    final rows = [
      TrinaRow(cells: {'date': TrinaCell(value: '2020-01-01')}),
      TrinaRow(cells: {'date': TrinaCell(value: '2020-01-02')}),
      TrinaRow(cells: {'date': TrinaCell(value: '2020-01-03')}),
      TrinaRow(cells: {'date': TrinaCell(value: '2020-01-04')}),
      TrinaRow(cells: {'date': TrinaCell(value: '2020-01-05')}),
    ];

    return TrinaWidgetTestHelper(
      'build with selecting cells.',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: TrinaGrid(
                columns: columns,
                rows: rows,
                onLoaded: (TrinaGridOnLoadedEvent event) {
                  stateManager = event.stateManager;
                },
                configuration: configuration,
              ),
            ),
          ),
        );
      },
    );
  }

  buildGrid(
    configuration: const TrinaGridConfiguration(
      enableMoveDownAfterSelecting: true,
    ),
  ).test(
    'When the first cell is selected, '
    'the first cell should be focused.',
    (tester) async {
      // Select the 0th row, which is January 1st, 2020
      await tester.tap(find.text('2020-01-01'));

      // After selecting the date below 2020-01-01, select 2020-01-08 and press enter to move to the next row.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      expect(stateManager!.isEditing, isTrue);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // The cell value should be changed to 2020-01-08.
      expect(stateManager!.rows[0].cells['date']!.value, '2020-01-08');

      // The current cell position should be changed to the next row.
      expect(stateManager!.currentCellPosition!.rowIdx, 1);

      // The editing state should be maintained.
      expect(stateManager!.isEditing, isTrue);

      // Enter the string to call the popup again and select 2020-01-09,
      // which is below 2020-01-02, and press enter to move to the next row.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);

      // The cell value should be changed to 2020-01-09.
      expect(stateManager!.rows[1].cells['date']!.value, '2020-01-09');

      // The current cell position should be changed to the next row.
      expect(stateManager!.currentCellPosition!.rowIdx, 2);

      // The editing state should be maintained.
      expect(stateManager!.isEditing, isTrue);
    },
  );
}
