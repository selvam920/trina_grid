import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trina_grid/trina_grid.dart';
import 'package:trina_grid/src/ui/ui.dart';

/// [TrinaGridStyleConfig.columnBackgroundColor] colours the header band on
/// its own, without colouring the space under the last row
/// ([TrinaGridStyleConfig.gridBackgroundColor]).
void main() {
  const band = Color(0xFFB2DFDB);

  List<TrinaColumn> columns({bool frozen = false}) => [
    TrinaColumn(
      title: 'a',
      field: 'a',
      type: TrinaColumnType.text(),
      frozen: frozen ? TrinaColumnFrozen.start : TrinaColumnFrozen.none,
    ),
    TrinaColumn(title: 'b', field: 'b', type: TrinaColumnType.text()),
  ];

  List<TrinaRow> rows() => [
    TrinaRow(
      cells: {
        'a': TrinaCell(value: '1'),
        'b': TrinaCell(value: '2'),
      },
    ),
  ];

  Future<void> pump(
    WidgetTester tester,
    TrinaGridStyleConfig style, {
    bool frozen = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SizedBox(
            width: 800,
            height: 300,
            child: TrinaGrid(
              columns: columns(frozen: frozen),
              rows: rows(),
              configuration: TrinaGridConfiguration(style: style),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Iterable<ColoredBox> bands(WidgetTester tester) => tester
      .widgetList<ColoredBox>(find.byType(ColoredBox))
      .where((b) => b.color == band);

  testWidgets('paints the header band when set', (tester) async {
    await pump(tester, const TrinaGridStyleConfig(columnBackgroundColor: band));

    expect(bands(tester), hasLength(1));
    expect(
      find.ancestor(
        of: find.byType(TrinaBodyColumns),
        matching: find.byWidget(bands(tester).first),
      ),
      findsOneWidget,
    );
  });

  testWidgets('paints the frozen header too', (tester) async {
    await pump(
      tester,
      const TrinaGridStyleConfig(columnBackgroundColor: band),
      frozen: true,
    );

    expect(bands(tester), hasLength(2));
  });

  testWidgets('paints nothing when unset', (tester) async {
    await pump(tester, const TrinaGridStyleConfig());

    expect(bands(tester), isEmpty);
  });

  group('copyWith', () {
    test('sets and clears the colour', () {
      const style = TrinaGridStyleConfig();

      final set = style.copyWith(
        columnBackgroundColor: const TrinaOptional<Color?>(band),
      );
      expect(set.columnBackgroundColor, band);

      final kept = set.copyWith(rowHeight: 30);
      expect(kept.columnBackgroundColor, band);

      final cleared = set.copyWith(
        columnBackgroundColor: const TrinaOptional<Color?>(null),
      );
      expect(cleared.columnBackgroundColor, isNull);
    });
  });

  group('equality', () {
    test('a different header colour is a different style', () {
      expect(
        const TrinaGridStyleConfig(columnBackgroundColor: band),
        isNot(const TrinaGridStyleConfig()),
      );
    });

    // These were hashed but never compared, so two styles differing only in
    // one of them compared equal.
    test('fields that were missing from == are compared', () {
      const base = TrinaGridStyleConfig();
      expect(base.copyWith(rowHoveredColor: Colors.red), isNot(base));
      expect(base.copyWith(rowCheckedColor: Colors.red), isNot(base));
      expect(base.copyWith(activatedTextColor: Colors.red), isNot(base));
      expect(base.copyWith(enableRowHoverColor: true), isNot(base));
      expect(base.copyWith(enableColumnBorderHorizontal: false), isNot(base));
      expect(base.copyWith(unfocusedSelectionColor: Colors.red), isNot(base));
    });
  });
}
