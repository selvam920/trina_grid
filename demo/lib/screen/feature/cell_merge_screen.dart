import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../widget/trina_example_button.dart';
import '../../widget/trina_example_screen.dart';

class CellMergeScreen extends StatefulWidget {
  static const routeName = 'feature/cell-merge';

  const CellMergeScreen({super.key});

  @override
  _CellMergeScreenState createState() => _CellMergeScreenState();
}

class _CellMergeScreenState extends State<CellMergeScreen> {
  final List<TrinaColumn> columns = [];
  final List<TrinaRow> rows = [];
  late TrinaGridStateManager stateManager;

  @override
  void initState() {
    super.initState();

    // Create columns
    columns.addAll([
      TrinaColumn(
        title: 'Name',
        field: 'name',
        type: TrinaColumnType.text(),
        width: 150,
      ),
      TrinaColumn(
        title: 'Department',
        field: 'department',
        type: TrinaColumnType.text(),
        width: 150,
      ),
      TrinaColumn(
        title: 'Position',
        field: 'position',
        type: TrinaColumnType.text(),
        width: 150,
      ),
      TrinaColumn(
        title: 'Salary',
        field: 'salary',
        type: TrinaColumnType.currency(),
        width: 120,
      ),
      TrinaColumn(
        title: 'Start Date',
        field: 'startDate',
        type: TrinaColumnType.date(),
        width: 120,
      ),
      TrinaColumn(
        title: 'Status',
        field: 'status',
        type: TrinaColumnType.select(['Active', 'Inactive', 'On Leave']),
        width: 120,
      ),
    ]);

    // Create rows with some pre-merged cells
    rows.addAll([
      TrinaRow(cells: {
        'name': TrinaCell(value: 'John Doe'),
        'department': TrinaCell(value: 'Engineering'),
        'position': TrinaCell(value: 'Senior Developer'),
        'salary': TrinaCell(value: 75000),
        'startDate': TrinaCell(value: '2020-01-15'),
        'status': TrinaCell(value: 'Active'),
      }),
      TrinaRow(cells: {
        'name': TrinaCell(value: 'Jane Smith'),
        'department': TrinaCell(value: 'Engineering'),
        'position': TrinaCell(value: 'Team Lead'),
        'salary': TrinaCell(value: 85000),
        'startDate': TrinaCell(value: '2019-03-01'),
        'status': TrinaCell(value: 'Active'),
      }),
      TrinaRow(cells: {
        'name': TrinaCell(value: 'Bob Johnson'),
        'department': TrinaCell(value: 'Marketing'),
        'position': TrinaCell(value: 'Marketing Manager'),
        'salary': TrinaCell(value: 70000),
        'startDate': TrinaCell(value: '2021-06-10'),
        'status': TrinaCell(value: 'Active'),
      }),
      TrinaRow(cells: {
        'name': TrinaCell(value: 'Alice Brown'),
        'department': TrinaCell(value: 'Marketing'),
        'position': TrinaCell(value: 'Content Creator'),
        'salary': TrinaCell(value: 55000),
        'startDate': TrinaCell(value: '2022-02-20'),
        'status': TrinaCell(value: 'Active'),
      }),
      TrinaRow(cells: {
        'name': TrinaCell(value: 'Charlie Wilson'),
        'department': TrinaCell(value: 'HR'),
        'position': TrinaCell(value: 'HR Manager'),
        'salary': TrinaCell(value: 65000),
        'startDate': TrinaCell(value: '2020-08-05'),
        'status': TrinaCell(value: 'On Leave'),
      }),
      TrinaRow(cells: {
        'name': TrinaCell(value: 'Diana Davis'),
        'department': TrinaCell(value: 'HR'),
        'position': TrinaCell(value: 'Recruiter'),
        'salary': TrinaCell(value: 50000),
        'startDate': TrinaCell(value: '2023-01-12'),
        'status': TrinaCell(value: 'Active'),
      }),
    ]);
  }

  void _mergeSelectedCells() {
    if (stateManager.mergeSelectedCells()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cells merged successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Cannot merge cells - invalid selection or already merged')),
      );
    }
  }

  void _unmergeCurrentCell() {
    if (stateManager.unmergeCurrentCell()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cell unmerged successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No merged cell to unmerge')),
      );
    }
  }

  void _unmergeAllCells() {
    stateManager.unmergeAllCells();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All cells unmerged!')),
    );
  }

  void _mergeDepartmentCells() {
    // Example: Merge Engineering department cells (rows 0-1, column 1)
    final range = TrinaCellMergeRange(
      startRowIdx: 0,
      endRowIdx: 1,
      startColIdx: 1,
      endColIdx: 1,
    );

    if (stateManager.mergeCells(range)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Engineering department cells merged!')),
      );
    }
  }

  void _mergeMarketingCells() {
    // Example: Merge Marketing department cells (rows 2-3, column 1)
    final range = TrinaCellMergeRange(
      startRowIdx: 2,
      endRowIdx: 3,
      startColIdx: 1,
      endColIdx: 1,
    );

    if (stateManager.mergeCells(range)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marketing department cells merged!')),
      );
    }
  }

  void _mergeHRCells() {
    // Example: Merge HR department cells (rows 4-5, column 1)
    final range = TrinaCellMergeRange(
      startRowIdx: 4,
      endRowIdx: 5,
      startColIdx: 1,
      endColIdx: 1,
    );

    if (stateManager.mergeCells(range)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('HR department cells merged!')),
      );
    }
  }

  void _mergeHeaderCells() {
    // Example: Merge header cells (row 0, columns 0-2) to create a "Employee Info" header
    final range = TrinaCellMergeRange(
      startRowIdx: 0,
      endRowIdx: 0,
      startColIdx: 0,
      endColIdx: 2,
    );

    if (stateManager.mergeCells(range)) {
      // Update the merged cell value
      stateManager.changeCellValue(
        stateManager.refRows[0].cells['name']!,
        'Employee Information',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Header cells merged!')),
      );
    }
  }

  void _changeColumnAlignment(String field, TrinaColumnTextAlign alignment) {
    final columnIndex = columns.indexWhere((col) => col.field == field);
    if (columnIndex != -1) {
      setState(() {
        columns[columnIndex].textAlign = alignment;
        stateManager.notifyListeners();
      });

      String alignmentName = alignment.toString().split('.').last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('$field column alignment changed to $alignmentName')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TrinaExampleScreen(
      title: 'Cell Merge',
      topTitle: 'Cell Merge',
      topContents: const [
        Text('Demonstrates cell merging functionality.'),
        Text(
            'Select cells and merge them, or use the predefined merge examples.'),
      ],
      topButtons: [
        TrinaExampleButton(
          url:
              'https://github.com/doonfrs/trina_grid/blob/main/demo/lib/screen/feature/cell_merge_screen.dart',
        ),
      ],
      body: Column(
        children: [
          // Control buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Merge controls
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    ElevatedButton(
                      onPressed: _mergeSelectedCells,
                      child: const Text('Merge Selected'),
                    ),
                    ElevatedButton(
                      onPressed: _unmergeCurrentCell,
                      child: const Text('Unmerge Current'),
                    ),
                    ElevatedButton(
                      onPressed: _unmergeAllCells,
                      child: const Text('Unmerge All'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _mergeDepartmentCells,
                      child: const Text('Merge Engineering'),
                    ),
                    ElevatedButton(
                      onPressed: _mergeMarketingCells,
                      child: const Text('Merge Marketing'),
                    ),
                    ElevatedButton(
                      onPressed: _mergeHRCells,
                      child: const Text('Merge HR'),
                    ),
                    ElevatedButton(
                      onPressed: _mergeHeaderCells,
                      child: const Text('Merge Header'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Alignment controls
                const Text(
                  'Department Column Alignment (test with merged cells):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    OutlinedButton(
                      onPressed: () => _changeColumnAlignment(
                          'department', TrinaColumnTextAlign.left),
                      child: const Text('Left'),
                    ),
                    OutlinedButton(
                      onPressed: () => _changeColumnAlignment(
                          'department', TrinaColumnTextAlign.center),
                      child: const Text('Center'),
                    ),
                    OutlinedButton(
                      onPressed: () => _changeColumnAlignment(
                          'department', TrinaColumnTextAlign.right),
                      child: const Text('Right'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Name Column Alignment (test with merged header):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    OutlinedButton(
                      onPressed: () => _changeColumnAlignment(
                          'name', TrinaColumnTextAlign.left),
                      child: const Text('Left'),
                    ),
                    OutlinedButton(
                      onPressed: () => _changeColumnAlignment(
                          'name', TrinaColumnTextAlign.center),
                      child: const Text('Center'),
                    ),
                    OutlinedButton(
                      onPressed: () => _changeColumnAlignment(
                          'name', TrinaColumnTextAlign.right),
                      child: const Text('Right'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Status Column Alignment (test with vertical merging):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    OutlinedButton(
                      onPressed: () => _changeColumnAlignment(
                          'status', TrinaColumnTextAlign.left),
                      child: const Text('Left'),
                    ),
                    OutlinedButton(
                      onPressed: () => _changeColumnAlignment(
                          'status', TrinaColumnTextAlign.center),
                      child: const Text('Center'),
                    ),
                    OutlinedButton(
                      onPressed: () => _changeColumnAlignment(
                          'status', TrinaColumnTextAlign.right),
                      child: const Text('Right'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TrinaGrid(
                columns: columns,
                rows: rows,
                onLoaded: (TrinaGridOnLoadedEvent event) {
                  stateManager = event.stateManager;
                },
                configuration: TrinaGridConfiguration(
                  selectingMode: TrinaGridSelectingMode.cell,
                  style: TrinaGridStyleConfig(
                    enableCellBorderHorizontal: true,
                    enableCellBorderVertical: true,
                    cellHorizontalBorderWidth: 1.0,
                    cellVerticalBorderWidth: 1.0,
                    borderColor: Colors.grey,
                    activatedBorderColor: Colors.blue,
                    activatedColor: Colors.blue.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
