# Cell Merging

Cell merging is a powerful feature in TrinaGrid that allows you to combine adjacent cells into a single cell that spans multiple rows, columns, or both. This feature is particularly useful for creating headers, grouping related data, or improving the visual presentation of your grid.

> **Note:** Cell merging is available in TrinaGrid version 1.6.10 and later.

![Cell Merging Demo](https://raw.githubusercontent.com/doonfrs/trina_grid/master/doc/assets/cell-merging.gif)

## Overview

The cell merging feature enables you to:

- Merge cells horizontally (spanning multiple columns)
- Merge cells vertically (spanning multiple rows)
- Merge cells in both directions (spanning both rows and columns)
- Control merge behavior through column configuration
- Programmatically merge and unmerge cells
- Handle merged cells in selection and navigation

Cell merging works seamlessly with other TrinaGrid features such as cell selection, keyboard navigation, and data editing.

## Enabling Cell Merging

Cell merging is enabled by default for all columns. To disable merging for specific columns, set the `enableCellMerge` property to `false`:

```dart
TrinaColumn(
  title: 'ID',
  field: 'id',
  type: TrinaColumnType.text(),
  enableCellMerge: false, // Disable merging for this column
)
```

## Basic Usage

### Programmatic Merging

You can merge cells programmatically using the state manager:

```dart
// Get the state manager
final stateManager = // your state manager instance

// Merge cells in a specific range
final range = TrinaCellMergeRange(
  startRowIdx: 0,
  endRowIdx: 2,    // Merge 3 rows vertically
  startColIdx: 1,
  endColIdx: 1,    // Single column
);

bool success = stateManager.mergeCells(range);
```

### Merging Selected Cells

You can merge the currently selected cells:

```dart
// Merge the current selection
bool success = stateManager.mergeSelectedCells();
```

### Unmerging Cells

To unmerge cells, you have several options:

```dart
// Unmerge a specific range
stateManager.unmergeCells(range: range);

// Unmerge a specific cell
stateManager.unmergeCells(cell: cell);

// Unmerge the current cell
stateManager.unmergeCurrentCell();

// Unmerge all cells in the grid
stateManager.unmergeAllCells();
```

## Merge Range Definition

The `TrinaCellMergeRange` class defines the area to be merged:

```dart
TrinaCellMergeRange(
  startRowIdx: 0,     // Starting row index
  endRowIdx: 1,       // Ending row index (inclusive)
  startColIdx: 0,     // Starting column index
  endColIdx: 2,       // Ending column index (inclusive)
)
```

You can also create a range from two cell positions:

```dart
final range = TrinaCellMergeRange.fromPositions(
  startPosition,
  endPosition,
);
```

## Merge Types

### Horizontal Merging

Merge cells across multiple columns:

```dart
final horizontalRange = TrinaCellMergeRange(
  startRowIdx: 0,
  endRowIdx: 0,       // Same row
  startColIdx: 0,
  endColIdx: 2,       // Span 3 columns
);

stateManager.mergeCells(horizontalRange);
```

### Vertical Merging

Merge cells across multiple rows:

```dart
final verticalRange = TrinaCellMergeRange(
  startRowIdx: 0,
  endRowIdx: 2,       // Span 3 rows
  startColIdx: 1,
  endColIdx: 1,       // Same column
);

stateManager.mergeCells(verticalRange);
```

### Both Directions

Merge cells in both rows and columns:

```dart
final bothRange = TrinaCellMergeRange(
  startRowIdx: 0,
  endRowIdx: 1,       // Span 2 rows
  startColIdx: 0,
  endColIdx: 1,       // Span 2 columns
);

stateManager.mergeCells(bothRange);
```

## Content Alignment

Merged cells support proper content alignment. The content will be centered within the entire merged area:

```dart
TrinaColumn(
  title: 'Department',
  field: 'department',
  type: TrinaColumnType.text(),
  textAlign: TrinaColumnTextAlign.center, // Center align merged content
)
```

## Working with Merged Cells

### Checking Merge Status

You can check if a cell is merged:

```dart
bool isMerged = stateManager.isCellMerged(cell);
```

### Getting Merge Information

Retrieve merge range information for a cell:

```dart
TrinaCellMergeRange? range = stateManager.getMergeRange(cell, rowIdx, colIdx);
```

### Getting All Merged Ranges

Get all merged ranges in the grid:

```dart
List<TrinaCellMergeRange> allRanges = stateManager.getAllMergedRanges();
```

## Complete Example

Here's a complete example demonstrating cell merging:

```dart
import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

class CellMergingExample extends StatefulWidget {
  @override
  _CellMergingExampleState createState() => _CellMergingExampleState();
}

class _CellMergingExampleState extends State<CellMergingExample> {
  late TrinaGridStateManager stateManager;
  
  List<TrinaColumn> columns = [
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
      width: 120,
      textAlign: TrinaColumnTextAlign.center,
    ),
    TrinaColumn(
      title: 'Position',
      field: 'position',
      type: TrinaColumnType.text(),
      width: 150,
    ),
    TrinaColumn(
      title: 'Status',
      field: 'status',
      type: TrinaColumnType.text(),
      width: 100,
      textAlign: TrinaColumnTextAlign.center,
    ),
  ];

  List<TrinaRow> rows = [
    TrinaRow(cells: {
      'name': TrinaCell(value: 'John Doe'),
      'department': TrinaCell(value: 'Engineering'),
      'position': TrinaCell(value: 'Senior Developer'),
      'status': TrinaCell(value: 'Active'),
    }),
    TrinaRow(cells: {
      'name': TrinaCell(value: 'Jane Smith'),
      'department': TrinaCell(value: 'Engineering'),
      'position': TrinaCell(value: 'Team Lead'),
      'status': TrinaCell(value: 'Active'),
    }),
    TrinaRow(cells: {
      'name': TrinaCell(value: 'Bob Johnson'),
      'department': TrinaCell(value: 'Marketing'),
      'position': TrinaCell(value: 'Marketing Manager'),
      'status': TrinaCell(value: 'On Leave'),
    }),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cell Merging Example'),
        actions: [
          IconButton(
            icon: Icon(Icons.merge),
            onPressed: _mergeSelectedCells,
            tooltip: 'Merge Selected Cells',
          ),
          IconButton(
            icon: Icon(Icons.call_split),
            onPressed: _unmergeCurrentCell,
            tooltip: 'Unmerge Current Cell',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _mergeDepartmentCells,
                  child: Text('Merge Department'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _mergeStatusCells,
                  child: Text('Merge Status'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _unmergeAllCells,
                  child: Text('Unmerge All'),
                ),
              ],
            ),
          ),
          Expanded(
            child: TrinaGrid(
              columns: columns,
              rows: rows,
              onLoaded: (TrinaGridOnLoadedEvent event) {
                stateManager = event.stateManager;
              },
              configuration: TrinaGridConfiguration(
                style: TrinaGridStyleConfig(
                  enableCellBorderVertical: true,
                  enableCellBorderHorizontal: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mergeSelectedCells() {
    if (stateManager.mergeSelectedCells()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cells merged successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to merge cells')),
      );
    }
  }

  void _unmergeCurrentCell() {
    if (stateManager.unmergeCurrentCell()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cell unmerged successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No merged cell to unmerge')),
      );
    }
  }

  void _mergeDepartmentCells() {
    // Merge Engineering department cells (rows 0-1, column 1)
    final range = TrinaCellMergeRange(
      startRowIdx: 0,
      endRowIdx: 1,
      startColIdx: 1,
      endColIdx: 1,
    );
    
    if (stateManager.mergeCells(range)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Department cells merged')),
      );
    }
  }

  void _mergeStatusCells() {
    // Merge Active status cells (rows 0-1, column 3)
    final range = TrinaCellMergeRange(
      startRowIdx: 0,
      endRowIdx: 1,
      startColIdx: 3,
      endColIdx: 3,
    );
    
    if (stateManager.mergeCells(range)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status cells merged')),
      );
    }
  }

  void _unmergeAllCells() {
    stateManager.unmergeAllCells();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All cells unmerged')),
    );
  }
}
```

## Validation and Constraints

### Merge Validation

The system validates merge operations to ensure they are valid:

- Cells must be adjacent and form a rectangular area
- Columns must have `enableCellMerge` set to `true`
- Cells cannot already be part of another merge
- Range must span at least 2 cells (either rows or columns)

### Merge Constraints

- Only rectangular areas can be merged
- Merged cells cannot overlap with other merged cells
- The main cell (top-left) retains the original value
- Spanned cells are hidden from rendering but maintain their data

## Best Practices

1. **Use for Headers**: Merge cells to create section headers or group labels
2. **Consistent Alignment**: Use appropriate text alignment for merged content
3. **Visual Clarity**: Enable borders to clearly show merged cell boundaries
4. **Performance**: Avoid excessive merging in large grids for better performance
5. **User Experience**: Provide clear UI controls for merge/unmerge operations

## Troubleshooting

### Common Issues

**Merge fails silently**: Check that all columns in the range have `enableCellMerge: true`

**Content not centered**: Ensure proper `textAlign` configuration on the column

**Borders not displaying correctly**: Enable both horizontal and vertical borders in the grid configuration

**Selection issues**: Merged cells are treated as a single unit for selection purposes

## API Reference

### State Manager Methods

- `mergeCells(TrinaCellMergeRange range)`: Merge cells in the specified range
- `mergeSelectedCells()`: Merge currently selected cells
- `unmergeCells({range, cell})`: Unmerge cells by range or specific cell
- `unmergeCurrentCell()`: Unmerge the current cell
- `unmergeAllCells()`: Unmerge all cells in the grid
- `getMergeRange(cell, rowIdx, colIdx)`: Get merge range for a cell
- `getAllMergedRanges()`: Get all merged ranges in the grid
- `isCellMerged(cell)`: Check if a cell is merged

### Classes

- `TrinaCellMergeRange`: Defines the area to be merged
- `TrinaCellMerge`: Contains merge information for a cell
- `TrinaCellMergeManager`: Manages merge operations internally
