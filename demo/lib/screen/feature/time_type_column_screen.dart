import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../widget/trina_example_button.dart';
import '../../widget/trina_example_screen.dart';

class TimeTypeColumnScreen extends StatefulWidget {
  static const routeName = 'feature/time-type-column';

  const TimeTypeColumnScreen({super.key});

  @override
  _TimeTypeColumnScreenState createState() => _TimeTypeColumnScreenState();
}

class _TimeTypeColumnScreenState extends State<TimeTypeColumnScreen> {
  final List<TrinaColumn> columns = [];

  final List<TrinaRow> rows = [];

  @override
  void initState() {
    super.initState();

    columns.addAll([
      TrinaColumn(
        title: 'Time',
        field: 'time',
        type: TrinaColumnType.time(),
      ),
    ]);

    rows.addAll([
      TrinaRow(
        cells: {
          'time': TrinaCell(value: '00:00'),
        },
      ),
      TrinaRow(
        cells: {
          'time': TrinaCell(value: '23:59'),
        },
      ),
      TrinaRow(
        cells: {
          'time': TrinaCell(value: '12:30'),
        },
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return TrinaExampleScreen(
      title: 'Time type column',
      topTitle: 'Time type column',
      topContents: const [
        Text('A column to enter a time value.'),
        Text('Move the hour and minute with the left and right arrow keys.'),
      ],
      topButtons: [
        TrinaExampleButton(
          url:
              'https://github.com/doonfrs/trina_grid/blob/master/demo/lib/screen/feature/time_type_column_screen.dart',
        ),
      ],
      body: TrinaGrid(
        columns: columns,
        rows: rows,
        onChanged: (TrinaGridOnChangedEvent event) {
          print(event);
        },
      ),
    );
  }
}
