import 'package:material_ui/material_ui.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../widget/trina_example_button.dart';
import '../../widget/trina_example_screen.dart';

class DropdownColumnScreen extends StatefulWidget {
  static const routeName = 'feature/dropdown-column';

  const DropdownColumnScreen({super.key});

  @override
  State<DropdownColumnScreen> createState() => _DropdownColumnScreenState();
}

class _DropdownColumnScreenState extends State<DropdownColumnScreen> {
  final List<TrinaColumn> columns = [
    TrinaColumn(
      title: 'Name',
      field: 'name',
      type: TrinaColumnType.text(),
    ),
    TrinaColumn(
      title: 'Status (Dropdown)',
      field: 'status',
      type: TrinaColumnType.dropdown(
        items: ['Active', 'Inactive', 'Pending', 'Archived'],
        autoOpen: true,
      ),
    ),
    TrinaColumn(
      title: 'Priority (Dropdown)',
      field: 'priority',
      type: TrinaColumnType.dropdown(
        items: ['High', 'Medium', 'Low'],
        autoOpen: true,
        itemBuilder: (context, item, selected) {
          Color color = Colors.grey;
          if (item == 'High') color = Colors.red;
          if (item == 'Medium') color = Colors.orange;
          if (item == 'Low') color = Colors.green;
          
          return Row(
            children: [
              Icon(Icons.flag, color: color, size: 16),
              const SizedBox(width: 8),
              Text(item, style: TextStyle(color: selected ? Colors.blue : null)),
            ],
          );
        },
      ),
    ),
    TrinaColumn(
      title: 'Action (Dynamic)',
      field: 'action',
      type: TrinaColumnType.dropdown(
        itemsProvider: (row, cell) {
          final status = row.cells['status']?.value;
          if (status == 'Active') {
            return ['Deactivate', 'Archive', 'Edit'];
          } else if (status == 'Pending') {
            return ['Approve', 'Reject'];
          } else if (status == 'Archived') {
            return ['Restore', 'Delete'];
          }
          return ['None'];
        },
        autoOpen: true,
      ),
    ),
    TrinaColumn(
      title: 'Empty Dropdown',
      field: 'empty',
      type: TrinaColumnType.dropdown(
        items: [],
        autoOpen: true,
      ),
    ),
  ];

  final List<TrinaRow> rows = [
    TrinaRow(cells: {
      'name': TrinaCell(value: 'Task 1'),
      'status': TrinaCell(value: 'Active'),
      'priority': TrinaCell(value: 'High'),
      'action': TrinaCell(value: 'Edit'),
      'empty': TrinaCell(value: ''),
    }),
    TrinaRow(cells: {
      'name': TrinaCell(value: 'Task 2'),
      'status': TrinaCell(value: 'Pending'),
      'priority': TrinaCell(value: 'Medium'),
      'action': TrinaCell(value: 'Approve'),
      'empty': TrinaCell(value: ''),
    }),
    TrinaRow(cells: {
      'name': TrinaCell(value: 'Task 3'),
      'status': TrinaCell(value: 'Archived'),
      'priority': TrinaCell(value: 'Low'),
      'action': TrinaCell(value: 'Restore'),
      'empty': TrinaCell(value: ''),
    }),
  ];

  late TrinaGridStateManager stateManager;

  @override
  Widget build(BuildContext context) {
    return TrinaExampleScreen(
      title: 'Dropdown Column',
      topTitle: 'Dropdown Column',
      topContents: const [
        Text(
          'The Dropdown column type is a non-editable selection list that opens an overlay when focused.',
        ),
      ],
      topButtons: [
        TrinaExampleButton(
          url:
              'https://github.com/doonfrs/trina_grid/blob/master/demo/lib/screen/feature/dropdown_column_screen.dart',
        ),
      ],
      body: TrinaGrid(
        columns: columns,
        rows: rows,
        onChanged: (event) {
          print(event);
        },
        onLoaded: (event) {
          stateManager = event.stateManager;
        },
      ),
    );
  }
}
