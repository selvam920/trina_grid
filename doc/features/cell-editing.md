# Cell Editing

Cell editing is a fundamental feature in TrinaGrid that allows users to modify cell values directly within the grid. This feature provides a spreadsheet-like experience, enabling efficient data entry and manipulation.

## Overview

The cell editing feature enables you to:

- Edit cell values directly in the grid
- Configure which columns are editable
- Customize the editing experience for different data types
- Validate input data before committing changes
- Handle cell value changes through events
- Integrate with keyboard navigation for efficient editing

Cell editing works seamlessly with other TrinaGrid features such as cell selection, keyboard navigation, and data validation.

## Enabling Cell Editing

To enable cell editing for specific columns, set the `enableEditingMode` property to `true` in your column definition:

```dart
TrinaColumn(
  title: 'Name',
  field: 'name',
  type: TrinaColumnType.text(),
  enableEditingMode: true, // Enable editing for this column
)
```

You can also make a column read-only by setting the `readOnly` property:

```dart
TrinaColumn(
  title: 'ID',
  field: 'id',
  type: TrinaColumnType.text(),
  readOnly: true, // This column cannot be edited
)
```

## Editing Modes

### Manual Editing

By default, cells enter edit mode when:

1. The user selects a cell and presses Enter
2. The user double-clicks on a cell

### Auto Editing

You can configure columns to automatically enter edit mode when selected:

```dart
TrinaColumn(
  title: 'Name',
  field: 'name',
  type: TrinaColumnType.text(),
  enableEditingMode: true,
  enableAutoEditing: true, // Automatically enter edit mode when cell is selected
)
```

Alternatively, you can set auto editing mode for the entire grid:

```dart
stateManager.setAutoEditing(true);
```

## Keyboard Navigation

TrinaGrid supports keyboard navigation during editing:

- **Enter**: Completes editing and moves to the cell below (configurable)
- **Tab**: Completes editing and moves to the next cell
- **Escape**: Cancels editing and reverts to the original value
- **Arrow keys**: Navigate between cells when not in edit mode

You can configure the Enter key behavior through the grid configuration:

```dart
TrinaGrid(
  columns: columns,
  rows: rows,
  configuration: TrinaGridConfiguration(
    enterKeyAction: TrinaGridEnterKeyAction.editingAndMoveDown, // Default
    // Other options: editingAndMoveRight, toggleEditing, none
  ),
)
```

## Data Validation

TrinaGrid provides built-in validation for cell values based on column types. You can also implement custom validation:

```dart
TrinaColumn(
  title: 'Age',
  field: 'age',
  type: TrinaColumnType.number(),
  enableEditingMode: true,
  validator: (dynamic value, TrinaValidationContext context) {
    if (value != null && (value < 0 || value > 120)) {
      return 'Age must be between 0 and 120';
    }
    return null; // Return null if validation passes
  },
)
```

When validation fails, the `onValidationFailed` callback is triggered:

```dart
TrinaGrid(
  columns: columns,
  rows: rows,
  onValidationFailed: (TrinaGridValidationEvent event) {
    // Handle validation failure
    print('Validation failed: ${event.errorMessage}');
  },
)
```

## Event Handling

TrinaGrid provides several callbacks for handling cell editing events:

### Cell Value Changed

```dart
TrinaGrid(
  columns: columns,
  rows: rows,
  onChanged: (TrinaGridOnChangedEvent event) {
    // Handle cell value change
    print('Cell value changed: ${event.value}');
  },
)
```

You can also set an `onChanged` callback for individual cells:

```dart
TrinaCell(
  value: 'Initial value',
  onChanged: (TrinaGridOnChangedEvent event) {
    // Handle cell value change
    print('Cell value changed: ${event.value}');
  },
)
```

## Programmatic Control

You can programmatically control cell editing through the state manager:

```dart
// Check if a cell is currently in edit mode
bool isEditing = stateManager.isEditing;

// Set a cell to edit mode
stateManager.setEditing(true);

// Toggle edit mode
stateManager.toggleEditing();

// Change a cell value programmatically
stateManager.changeCellValue(cell, newValue);
```

## Copy and Paste

TrinaGrid supports copy and paste functionality for cell values:

```dart
// Paste values from clipboard
stateManager.pasteCellValue(textList);
```

The paste operation respects the current selection:

- If a single cell is selected, pasting starts from that cell
- If a range is selected, pasting is constrained to that range
- If rows are selected, pasting applies to the selected rows

## Custom Cell Editors

You can customize the cell editing experience by implementing custom cell renderers:

```dart
TrinaColumn(
  title: 'Status',
  field: 'status',
  type: TrinaColumnType.select([
    'Active',
    'Inactive',
    'Pending',
  ]),
  enableEditingMode: true,
)
```

## Complete Example

Here's a complete example demonstrating cell editing functionality:

```dart
import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

class CellEditingExample extends StatefulWidget {
  @override
  _CellEditingExampleState createState() => _CellEditingExampleState();
}

class _CellEditingExampleState extends State<CellEditingExample> {
  late List<TrinaColumn> columns;
  late List<TrinaRow> rows;
  late TrinaGridStateManager stateManager;

  @override
  void initState() {
    super.initState();
    
    columns = [
      TrinaColumn(
        title: 'ID',
        field: 'id',
        type: TrinaColumnType.text(),
        readOnly: true, // This column cannot be edited
      ),
      TrinaColumn(
        title: 'Name',
        field: 'name',
        type: TrinaColumnType.text(),
        enableEditingMode: true, // Enable editing for this column
      ),
      TrinaColumn(
        title: 'Age',
        field: 'age',
        type: TrinaColumnType.number(),
        enableEditingMode: true,
        validator: (dynamic value, TrinaValidationContext context) {
          if (value != null && (value < 0 || value > 120)) {
            return 'Age must be between 0 and 120';
          }
          return null; // Return null if validation passes
        },
      ),
      TrinaColumn(
        title: 'Status',
        field: 'status',
        type: TrinaColumnType.select([
          'Active',
          'Inactive',
          'Pending',
        ]),
        enableEditingMode: true,
      ),
    ];
    
    rows = [
      TrinaRow(cells: {
        'id': TrinaCell(value: '1'),
        'name': TrinaCell(value: 'John Doe'),
        'age': TrinaCell(value: 30),
        'status': TrinaCell(value: 'Active'),
      }),
      TrinaRow(cells: {
        'id': TrinaCell(value: '2'),
        'name': TrinaCell(value: 'Jane Smith'),
        'age': TrinaCell(value: 25),
        'status': TrinaCell(value: 'Inactive'),
      }),
      TrinaRow(cells: {
        'id': TrinaCell(value: '3'),
        'name': TrinaCell(value: 'Bob Johnson'),
        'age': TrinaCell(value: 45),
        'status': TrinaCell(value: 'Pending'),
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cell Editing Example'),
      ),
      body: TrinaGrid(
        columns: columns,
        rows: rows,
        onLoaded: (TrinaGridOnLoadedEvent event) {
          stateManager = event.stateManager;
        },
        onChanged: (TrinaGridOnChangedEvent event) {
          print('Cell value changed: ${event.value}');
        },
        onValidationFailed: (TrinaGridValidationEvent event) {
          print('Validation failed: ${event.errorMessage}');
        },
        configuration: TrinaGridConfiguration(
          enterKeyAction: TrinaGridEnterKeyAction.editingAndMoveDown,
          enableMoveHorizontalInEditing: true,
        ),
        mode: TrinaGridMode.normal,
      ),
    );
  }
}

## Best Practices

- **Enable editing only for columns that need it**: Keep read-only columns for data that shouldn't be modified
- **Implement validation**: Always validate user input to maintain data integrity
- **Handle validation failures**: Provide clear feedback when validation fails
- **Use appropriate column types**: Choose column types that match your data (text, number, select, etc.)
- **Consider keyboard navigation**: Configure keyboard shortcuts for efficient editing
- **Test with different input methods**: Ensure your editing experience works well with keyboard, mouse, and touch input
