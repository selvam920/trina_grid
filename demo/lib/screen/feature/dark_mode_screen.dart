import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../dummy_data/development.dart';
import '../../widget/trina_example_button.dart';
import '../../widget/trina_example_screen.dart';

class DarkModeScreen extends StatefulWidget {
  static const routeName = 'feature/dark-mode';

  const DarkModeScreen({super.key});

  @override
  _DarkModeScreenState createState() => _DarkModeScreenState();
}

class _DarkModeScreenState extends State<DarkModeScreen> {
  final List<TrinaColumn> columns = [];

  final List<TrinaRow> rows = [];

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
      title: 'Dark mode',
      topTitle: 'Dark mode',
      topContents: const [
        Text('Change the entire theme of the grid to Dark.'),
      ],
      topButtons: [
        TrinaExampleButton(
          url:
              'https://github.com/doonfrs/trina_grid/blob/master/demo/lib/screen/feature/dark_mode_screen.dart',
        ),
      ],
      body: Theme(
        data: ThemeData.dark(),
        child: TrinaGrid(
          columns: columns,
          rows: rows,
          onChanged: (TrinaGridOnChangedEvent event) {
            print(event);
          },
          configuration: const TrinaGridConfiguration.dark(),
        ),
      ),
    );
  }
}
