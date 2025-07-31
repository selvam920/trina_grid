import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../widget/trina_example_button.dart';
import '../../widget/trina_example_screen.dart';

class SelectionTypeColumnScreen extends StatefulWidget {
  static const routeName = 'feature/selection-type-column';

  const SelectionTypeColumnScreen({super.key});

  @override
  _SelectionTypeColumnScreenState createState() =>
      _SelectionTypeColumnScreenState();
}

class _SelectionTypeColumnScreenState extends State<SelectionTypeColumnScreen> {
  final List<TrinaColumn> columns = [];

  final List<TrinaRow> rows = [];

  @override
  void initState() {
    super.initState();

    columns.addAll([
      TrinaColumn(
        title: 'Select A',
        field: 'select_a',
        type: TrinaColumnType.select(
          <String>[
            'One',
            'Two',
            'Three',
          ],
          enableColumnFilter: true,
        ),
      ),
      TrinaColumn(
        title: 'Select B',
        field: 'select_b',
        type: TrinaColumnType.selectWithSearch(
          <String>[
            'Mercury',
            'Venus',
            'Earth',
            'Mars',
            'Jupiter',
            'Saturn',
            'Uranus',
            'Neptune',
            'Trina',
          ],
          itemToString: (item) => item,
          enableColumnFilter: true,
        ),
      ),
      TrinaColumn(
        title: 'Select C',
        field: 'select_c',
        type: TrinaColumnType.select(
          <String>[
            '9.01',
            '30.02',
            '100.001',
          ],
          enableColumnFilter: true,
        ),
      ),
      TrinaColumn(
        title: 'Select D',
        field: 'select_d',
        type: TrinaColumnType.select(
          <String>['Arabic', 'English', 'Chinese', 'French', 'German'],
          menuItemBuilder: (item) => Row(
            children: [
              const Icon(Icons.language, size: 20),
              const SizedBox(width: 4),
              Text(item),
            ],
          ),
        ),
      ),
      // A select column that provides a custom widget to display when
      // filtering yields no results.
      TrinaColumn(
        title: 'With custom empty filter result builder',
        field: 'select_e',
        type: TrinaColumnType.selectWithFilters(
          <String>['America', 'Africa', 'Australia', 'Asia', 'Antarctic'],
          menuFilters: [TrinaSelectMenuFilter.startsWith],
          menuEmptyFilterResultBuilder: (context) => SizedBox(
            height: 45,
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, size: 20),
                const SizedBox(width: 4),
                Flexible(child: Text('No countries match the filter')),
              ],
            ),
          ),
          enableColumnFilter: true,
        ),
      ),
    ]);

    rows.addAll([
      TrinaRow(
        cells: {
          'select_a': TrinaCell(value: 'One'),
          'select_b': TrinaCell(value: 'Saturn'),
          'select_c': TrinaCell(value: '100.001'),
          'select_d': TrinaCell(value: '五'),
        },
      ),
      TrinaRow(
        cells: {
          'select_a': TrinaCell(value: 'Two'),
          'select_b': TrinaCell(value: 'Trina'),
          'select_c': TrinaCell(value: '9.01'),
          'select_d': TrinaCell(value: '八'),
        },
      ),
      TrinaRow(
        cells: {
          'select_a': TrinaCell(value: 'Three'),
          'select_b': TrinaCell(value: 'Mars'),
          'select_c': TrinaCell(value: '30.02'),
          'select_d': TrinaCell(value: '三'),
        },
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return TrinaExampleScreen(
      title: 'Selection type column',
      topTitle: 'Selection type column',
      topContents: const [
        Text('A column to enter a selection value.'),
        Text(
            'The sorting of the Selection column is based on the order of the Select items.'),
      ],
      topButtons: [
        TrinaExampleButton(
          url:
              'https://github.com/doonfrs/trina_grid/blob/master/demo/lib/screen/feature/selection_type_column_screen.dart',
        ),
      ],
      body: TrinaGrid(
        columns: columns,
        rows: rows,
        onChanged: (TrinaGridOnChangedEvent event) {
          print(event);
        },
        configuration: const TrinaGridConfiguration(
            // If you don't want to move to the next line after selecting the pop-up item, uncomment it.
            // enableMoveDownAfterSelecting: false,
            ),
      ),
    );
  }
}
