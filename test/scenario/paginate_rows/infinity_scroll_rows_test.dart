import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trina_grid/trina_grid.dart';
import 'package:trina_grid/src/ui/ui.dart';

import '../../helper/column_helper.dart';
import '../../helper/row_helper.dart';
import '../../helper/test_helper_util.dart';

void main() {
  late List<TrinaColumn> columns;

  late List<TrinaRow> rows;

  late TrinaGridStateManager stateManager;

  setUp(() {
    columns = ColumnHelper.textColumn('column', count: 5);
    rows = [];
  });

  Future<void> buildGrid(
    WidgetTester tester, {
    bool initialFetch = true,
    bool fetchWithSorting = true,
    bool fetchWithFiltering = true,
    bool showColumnFilter = false,
    required TrinaInfinityScrollRowsFetch fetch,
  }) async {
    await TestHelperUtil.changeWidth(
      tester: tester,
      width: 1200,
      height: 800,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TrinaGrid(
            columns: columns,
            rows: rows,
            onLoaded: (TrinaGridOnLoadedEvent event) {
              stateManager = event.stateManager;
              if (showColumnFilter) {
                stateManager.setShowColumnFilter(true);
              }
            },
            createFooter: (s) => TrinaInfinityScrollRows(
              initialFetch: initialFetch,
              fetchWithSorting: fetchWithSorting,
              fetchWithFiltering: fetchWithFiltering,
              fetch: fetch,
              stateManager: s,
            ),
          ),
        ),
      ),
    );
  }

  TrinaInfinityScrollRowsFetch makeFetch({
    int pageSize = 20,
    int delayedMS = 20,
    required List<TrinaRow> dummyRows,
  }) {
    return (TrinaInfinityScrollRowsRequest request) async {
      List<TrinaRow> tempList = dummyRows;

      if (request.filterRows.isNotEmpty) {
        final filter = FilterHelper.convertRowsToFilter(
          request.filterRows,
          stateManager.refColumns,
        );

        tempList = dummyRows.where(filter!).toList();
      }

      if (request.sortColumn != null && !request.sortColumn!.sort.isNone) {
        tempList = [...tempList];

        tempList.sort((a, b) {
          final sortA = request.sortColumn!.sort.isAscending ? a : b;
          final sortB = request.sortColumn!.sort.isAscending ? b : a;

          return request.sortColumn!.type.compare(
            sortA.cells[request.sortColumn!.field]!.valueForSorting,
            sortB.cells[request.sortColumn!.field]!.valueForSorting,
          );
        });
      }

      Iterable<TrinaRow> fetchedRows = tempList.skipWhile(
        (row) => request.lastRow != null && row.key != request.lastRow!.key,
      );
      if (request.lastRow == null) {
        fetchedRows = fetchedRows.take(pageSize);
      } else {
        fetchedRows = fetchedRows.skip(1).take(pageSize);
      }

      await Future.delayed(Duration(milliseconds: delayedMS));

      final bool isLast =
          fetchedRows.isEmpty || tempList.last.key == fetchedRows.last.key;

      return Future.value(TrinaInfinityScrollRowsResponse(
        isLast: isLast,
        rows: fetchedRows.toList(),
      ));
    };
  }

  Finder findFilterTextField(String columnTitle) {
    return find.descendant(
      of: find.descendant(
          of: find.ancestor(
            of: find.text(columnTitle),
            matching: find.byType(TrinaBaseColumn),
          ),
          matching: find.byType(TrinaColumnFilter)),
      matching: find.byType(TextField),
    );
  }

  Future<void> tapAndEnterTextColumnFilter(
    WidgetTester tester,
    String columnTitle,
    String? enterText,
  ) async {
    final textField = findFilterTextField(columnTitle);

    // To receive focus, tap the text box twice.
    await tester.tap(textField);
    await tester.tap(textField);

    if (enterText != null) {
      await tester.enterText(textField, enterText);
    }
  }
}
