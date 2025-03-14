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

## Customizing Edit Cell Renderer

You can customize the appearance and behavior of cells in edit mode using the `editCellRenderer` property. This can be set at either the grid level or the column level.

### Column-Level Edit Cell Renderer

To customize the edit cell renderer for a specific column:

```dart
TrinaColumn(
  title: 'Name',
  field: 'name',
  type: TrinaColumnType.text(),
  enableEditingMode: true,
  editCellRenderer: (defaultEditCellWidget, cell, controller, focusNode) {
    // Return a custom widget that wraps the default edit cell widget
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: defaultEditCellWidget,
    );
  },
)
```

### Grid-Level Edit Cell Renderer

To apply a custom edit cell renderer to all editable columns:

```dart
TrinaGrid(
  columns: columns,
  rows: rows,
  editCellRenderer: (defaultEditCellWidget, cell, controller, focusNode) {
    // This will be used for all columns unless they have their own editCellRenderer
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: defaultEditCellWidget,
    );
  },
)
```

The `editCellRenderer` function provides:
- `defaultEditCellWidget`: The default edit cell widget (usually a TextField)
- `cell`: The current cell being edited
- `controller`: The TextEditingController for the edit field
- `focusNode`: The FocusNode for the edit field, allowing you to control focus

Column-level renderers take precedence over grid-level renderers.

### Handling Different Column Types

For different column types, you may need to implement custom widgets instead of using the default edit widget:

#### Select/Dropdown Columns

For select columns, you may need to use both `renderer` and `editCellRenderer` to fully customize the behavior:

```dart
TrinaColumn(
  title: 'Status',
  field: 'status',
  type: TrinaColumnType.select(['Active', 'Inactive', 'Pending']),
  enableEditingMode: true,
  // Custom renderer for display mode
  renderer: (rendererContext) {
    // Create a custom display for the cell
    return GestureDetector(
      onTap: () {
        // When tapped, enter edit mode
        rendererContext.stateManager.setCurrentCell(
          rendererContext.cell, 
          rendererContext.rowIdx
        );
        rendererContext.stateManager.setEditing(true);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Text(rendererContext.cell.value.toString()),
      ),
    );
  },
  // Custom renderer for edit mode
  editCellRenderer: (defaultEditCellWidget, cell, controller, focusNode) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: cell.value as String,
        focusNode: focusNode, // Use the provided focus node
        isExpanded: true,
        onChanged: (String? newValue) {
          if (newValue != null) {
            // Update the cell value directly through the state manager
            stateManager.changeCellValue(cell, newValue);
            
            // Exit editing mode after selection
            stateManager.setEditing(false);
          }
        },
        items: (cell.column.type as TrinaColumnTypeSelect)
            .items
            .map<DropdownMenuItem<String>>((dynamic value) {
          return DropdownMenuItem<String>(
            value: value as String,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  },
)
```

This approach gives you full control over both the display and editing experience for select columns. The `renderer` handles the normal display state and can trigger the edit mode, while the `editCellRenderer` handles the actual dropdown interface when in edit mode.

> **Note:** For popup-based columns (select, date, time), the `editCellRenderer` may not be called due to how these cells handle editing internally. In such cases, you can use a fully custom renderer that handles both display and edit modes:
>
> ```dart
> TrinaColumn(
>   title: 'Status',
>   field: 'status',
>   type: TrinaColumnType.select(['Active', 'Inactive', 'Pending']),
>   enableEditingMode: true,
>   renderer: (rendererContext) {
>     // Check if this cell is currently being edited
>     bool isEditing = rendererContext.stateManager.isEditing && 
>                     rendererContext.stateManager.currentCell == rendererContext.cell;
>
>     // If in edit mode, show dropdown
>     if (isEditing) {
>       return DropdownButtonHideUnderline(
>         child: DropdownButton<String>(
>           value: rendererContext.cell.value as String,
>           isExpanded: true,
>           onChanged: (String? newValue) {
>             if (newValue != null) {
>               // Update the cell value
>               rendererContext.stateManager.changeCellValue(rendererContext.cell, newValue);
>               // Exit editing mode
>               rendererContext.stateManager.setEditing(false);
>             }
>           },
>           items: (rendererContext.cell.column.type as TrinaColumnTypeSelect)
>               .items
>               .map<DropdownMenuItem<String>>((dynamic value) {
>             return DropdownMenuItem<String>(
>               value: value as String,
>               child: Text(value),
>             );
>           }).toList(),
>         ),
>       );
>     } 
>     // Otherwise show display mode
>     else {
>       return GestureDetector(
>         onTap: () {
>           // When tapped, enter edit mode
>           rendererContext.stateManager.setCurrentCell(
>             rendererContext.cell, 
>             rendererContext.rowIdx
>           );
>           rendererContext.stateManager.setEditing(true);
>         },
>         child: Text(rendererContext.cell.value.toString()),
>       );
>     }
>   },
> )
> ```

#### Date Columns

For date columns, you can implement a custom date picker:

```dart
TrinaColumn(
  title: 'Date',
  field: 'date',
  type: TrinaColumnType.date(),
  enableEditingMode: true,
  editCellRenderer: (defaultEditCellWidget, cell, controller, focusNode) {
    return Row(
      children: [
        Expanded(
          child: Text(
            cell.value != null
                ? '${(cell.value as DateTime).day}/${(cell.value as DateTime).month}/${(cell.value as DateTime).year}'
                : 'Select date',
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            // Request focus to maintain grid control
            focusNode.requestFocus();
            
            // Show date picker
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: cell.value ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            
            // Update cell value if a date was picked
            if (picked != null) {
              stateManager.changeCellValue(cell, picked);
            }
            
            // Request focus again after dialog is closed
            focusNode.requestFocus();
          },
        ),
      ],
    );
  },
)
```

> **Note:** As with select columns, for date columns you may need to use a fully custom renderer:
>
> ```dart
> TrinaColumn(
>   title: 'Date',
>   field: 'date',
>   type: TrinaColumnType.date(),
>   enableEditingMode: true,
>   renderer: (rendererContext) {
>     // Check if this cell is currently being edited
>     bool isEditing = rendererContext.stateManager.isEditing && 
>                     rendererContext.stateManager.currentCell == rendererContext.cell;
>
>     // Format the date for display
>     String displayText = rendererContext.cell.value != null
>         ? '${(rendererContext.cell.value as DateTime).day}/${(rendererContext.cell.value as DateTime).month}/${(rendererContext.cell.value as DateTime).year}'
>         : 'Select date';
>
>     // If in edit mode, show date picker interface
>     if (isEditing) {
>       return Row(
>         children: [
>           Expanded(
>             child: Text(displayText),
>           ),
>           IconButton(
>             icon: const Icon(Icons.calendar_today),
>             onPressed: () async {
>               // Show date picker
>               final DateTime? picked = await showDatePicker(
>                 context: context,
>                 initialDate: rendererContext.cell.value ?? DateTime.now(),
>                 firstDate: DateTime(2000),
>                 lastDate: DateTime(2100),
>               );
>               
>               // Update cell value if a date was picked
>               if (picked != null) {
>                 rendererContext.stateManager.changeCellValue(rendererContext.cell, picked);
>               }
>               
>               // Exit editing mode after selection
>               rendererContext.stateManager.setEditing(false);
>             },
>           ),
>         ],
>       );
>     } 
>     // Otherwise show display mode
>     else {
>       return GestureDetector(
>         onTap: () {
>           // When tapped, enter edit mode
>           rendererContext.stateManager.setCurrentCell(
>             rendererContext.cell, 
>             rendererContext.rowIdx
>           );
>           rendererContext.stateManager.setEditing(true);
>         },
>         child: Text(displayText),
>       );
>     }
>   },
> )
> ```

#### Number Columns

For number columns, you can create a custom number input with increment/decrement buttons:

```dart
TrinaColumn(
  title: 'Quantity',
  field: 'quantity',
  type: TrinaColumnType.number(),
  enableEditingMode: true,
  editCellRenderer: (defaultEditCellWidget, cell, controller, focusNode) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () {
            // Decrement the value
            final currentValue = (cell.value as num?) ?? 0;
            stateManager.changeCellValue(cell, currentValue - 1);
            
            // Update the controller text to reflect the new value
            controller.text = (currentValue - 1).toString();
            
            // Maintain focus
            focusNode.requestFocus();
          },
        ),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
            onChanged: (value) {
              // Update the cell value when the text changes
              if (value.isNotEmpty) {
                final numValue = int.tryParse(value) ?? 0;
                stateManager.changeCellValue(cell, numValue);
              }
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () {
            // Increment the value
            final currentValue = (cell.value as num?) ?? 0;
            stateManager.changeCellValue(cell, currentValue + 1);
            
            // Update the controller text to reflect the new value
            controller.text = (currentValue + 1).toString();
            
            // Maintain focus
            focusNode.requestFocus();
          },
        ),
      ],
    );
  },
)
```

### Important Notes

1. **Maintaining Focus**: Always use the provided `focusNode` to maintain grid focus control.
2. **Updating Values**: Use `stateManager.changeCellValue(cell, newValue)` to update cell values.
3. **Controller Synchronization**: For custom inputs, make sure to update the `controller.text` to reflect the new value.
4. **Type Casting**: Be careful with type casting when working with different column types.

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
