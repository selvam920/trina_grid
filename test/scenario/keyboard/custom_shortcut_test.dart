import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../helper/column_helper.dart';
import '../../helper/row_helper.dart';
import '../../helper/test_helper_util.dart';
import '../../mock/mock_methods.dart';

void main() {
  late List<TrinaColumn> columns;

  late List<TrinaRow> rows;

  late TrinaGridStateManager stateManager;

  final MockMethods mock = MockMethods();

  setUp(() {
    columns = ColumnHelper.textColumn('column', count: 5);

    rows = RowHelper.count(30, columns);

    reset(mock);
  });

  Future<void> buildGrid(
    WidgetTester tester, {
    required TrinaGridShortcut shortcut,
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
            },
            configuration: TrinaGridConfiguration(shortcut: shortcut),
          ),
        ),
      ),
    );

    stateManager.gridFocusNode.requestFocus();

    await tester.pump();
  }

  group('Custom Shortcut Test', () {
    testWidgets(
      'When a custom shortcut is defined, it should be triggered on the specified key combination',
      (tester) async {
        final testAction = _TestAction(mock.noParamReturnVoid);

        final shortcut = TrinaGridShortcut(actions: {
          LogicalKeySet(LogicalKeyboardKey.enter): testAction,
        });

        await buildGrid(tester, shortcut: shortcut);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);

        verify(mock.noParamReturnVoid()).called(1);
      },
    );

    testWidgets(
      'When a cell is focused and Control + C is pressed, the default action should be executed',
      (tester) async {
        String? copied;

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform, (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copied = (await methodCall.arguments['text']).toString();
          }
          return null;
        });

        const shortcut = TrinaGridShortcut();

        await buildGrid(tester, shortcut: shortcut);

        await tester.tap(find.text('column0 value 0'));
        await tester.pump();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pump();

        expect(copied, 'column0 value 0');
      },
    );

    testWidgets(
      'When a cell is focused and Control + C action is redefined, the default action should not be executed',
      (tester) async {
        String? copied;

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform, (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copied = (await methodCall.arguments['text']).toString();
          }
          return null;
        });

        final testAction = _TestAction(mock.noParamReturnVoid);

        final shortcut = TrinaGridShortcut(
          actions: {
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC):
                testAction,
          },
        );

        await buildGrid(tester, shortcut: shortcut);

        await tester.tap(find.text('column0 value 0'));
        await tester.pump();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pump();

        expect(copied, null);
        verify(mock.noParamReturnVoid()).called(1);
      },
    );
  });
}

class _TestAction extends TrinaGridShortcutAction {
  const _TestAction(this.callback);

  final void Function() callback;

  @override
  void execute({
    required TrinaKeyManagerEvent keyEvent,
    required TrinaGridStateManager stateManager,
  }) {
    callback();
  }
}
