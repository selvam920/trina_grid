import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../dummy_data/development.dart';
import '../../widget/trina_example_button.dart';
import '../../widget/trina_example_screen.dart';

class RowColorScreen extends StatefulWidget {
  static const routeName = 'feature/row-color';

  const RowColorScreen({super.key});

  @override
  _RowColorScreenState createState() => _RowColorScreenState();
}

class _RowColorScreenState extends State<RowColorScreen> {
  final List<TrinaColumn> columns = [];

  final List<TrinaRow> rows = [];

  late TrinaGridStateManager stateManager;

  @override
  void initState() {
    super.initState();

    final dummyData = DummyData(10, 100);

    columns.addAll(dummyData.columns);

    rows.addAll(dummyData.rows);
  }

  @override
  Widget build(BuildContext context) {
    return TrinaExampleScreen(
      title: 'Row color',
      topTitle: 'Row color',
      topContents: const [
        Text(
            'You can dynamically change the row color of row by implementing rowColorCallback.'),
        Text(
            'If you change the value of the 5th column, the background color is dynamically changed according to the value.'),
      ],
      topButtons: [
        TrinaExampleButton(
          url:
              'https://github.com/doonfrs/trina_grid/blob/master/demo/lib/screen/feature/row_color_screen.dart',
        ),
      ],
      body: TrinaGrid(
        columns: columns,
        rows: rows,
        onChanged: (TrinaGridOnChangedEvent event) {
          print(event);
        },
        onLoaded: (TrinaGridOnLoadedEvent event) {
          event.stateManager.setSelectingMode(TrinaGridSelectingMode.row);

          stateManager = event.stateManager;
        },
        rowColorCallback: (rowColorContext) {
          if (rowColorContext.row.cells.entries.elementAt(4).value.value ==
              'One') {
            return Colors.blueAccent;
          } else if (rowColorContext.row.cells.entries
                  .elementAt(4)
                  .value
                  .value ==
              'Two') {
            return Colors.cyanAccent;
          }

          return Colors.deepOrange;
        },
      ),
    );
  }
}
