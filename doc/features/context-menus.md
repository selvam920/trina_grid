# Context Menus

Context menus in TrinaGrid provide an intuitive way for users to access column-specific actions and settings. These menus enhance the user experience by offering quick access to common operations like column freezing, resizing, filtering, and visibility controls.

## Overview

TrinaGrid's context menu system allows users to interact with columns through a popup menu that appears when clicking on a context icon in the column header. The menu provides access to various column operations, and developers can customize both the appearance and functionality of these menus.

## Enabling Context Menus

Context menus can be enabled or disabled for each column individually:

```dart
TrinaColumn(
  title: 'Name',
  field: 'name',
  type: TrinaColumnType.text(),
  enableContextMenu: true, // Enable context menu for this column (default is true)
)
```

## Context Menu Features

When enabled, the context menu provides access to several column operations:

### Column Freezing

- **Freeze to Start**: Freezes the column to the left side of the grid
- **Freeze to End**: Freezes the column to the right side of the grid
- **Unfreeze**: Unfreezes a previously frozen column

### Column Sizing

- **Auto Fit**: Automatically adjusts the column width to fit its content

### Column Visibility

- **Hide Column**: Hides the column from view (requires `enableHideColumnMenuItem: true`)
- **Set Columns**: Opens a popup to manage the visibility of all columns (requires `enableSetColumnsMenuItem: true`)

### Column Filtering

- **Set Filter**: Opens the filter popup for the column (requires `enableFilterMenuItem: true`)
- **Reset Filter**: Clears all active filters (requires `enableFilterMenuItem: true`)

## Customizing Context Menu Items

You can control which menu items appear in the context menu by configuring the column properties:

```dart
TrinaColumn(
  title: 'Name',
  field: 'name',
  type: TrinaColumnType.text(),
  enableContextMenu: true,
  enableFilterMenuItem: true,      // Show filter-related menu items
  enableHideColumnMenuItem: true,  // Show hide column menu item
  enableSetColumnsMenuItem: true,  // Show set columns menu item
)
```

## Context Menu Icon and Resizing

The context menu icon appears on the right side of the column header when `enableContextMenu` is set to `true`. This icon serves two purposes:

1. **Menu Access**: Clicking the icon opens the context menu
2. **Column Resizing**: If `enableDropToResize` is also enabled, dragging the icon allows users to resize the column

```dart
TrinaColumn(
  title: 'Name',
  field: 'name',
  type: TrinaColumnType.text(),
  enableContextMenu: true,
  enableDropToResize: true, // Allow resizing by dragging the context menu icon
)
```

## Customizing the Context Menu

TrinaGrid allows you to fully customize the context menu by implementing your own `TrinaColumnMenuDelegate`:

```dart
class CustomColumnMenu implements TrinaColumnMenuDelegate<String> {
  @override
  List<PopupMenuEntry<String>> buildMenuItems({
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
  }) {
    // Return custom menu items
    return [
      PopupMenuItem<String>(
        value: 'custom_action',
        child: Text('Custom Action'),
      ),
      // Add more menu items as needed
    ];
  }

  @override
  void onSelected({
    required BuildContext context,
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
    required bool mounted,
    required String? selected,
  }) {
    // Handle menu item selection
    if (selected == 'custom_action') {
      // Perform custom action
    }
  }
}

// Use the custom menu delegate
TrinaGrid(
  columns: columns,
  rows: rows,
  columnMenuDelegate: CustomColumnMenu(),
)
```

## Styling the Context Menu

You can customize the appearance of the context menu icon and the menu itself through the `TrinaGridStyleConfig`:

```dart
TrinaGrid(
  columns: columns,
  rows: rows,
  configuration: TrinaGridConfiguration(
    style: TrinaGridStyleConfig(
      // Customize the context menu icon
      columnContextIcon: Icons.more_vert,
      
      // Customize menu colors
      menuBackgroundColor: Colors.white,
      iconColor: Colors.blue,
    ),
  ),
)
```

## Example

Here's a complete example demonstrating context menus:

```dart
import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

class ContextMenuExample extends StatefulWidget {
  @override
  _ContextMenuExampleState createState() => _ContextMenuExampleState();
}

class _ContextMenuExampleState extends State<ContextMenuExample> {
  final List<TrinaColumn> columns = [];
  final List<TrinaRow> rows = [];

  @override
  void initState() {
    super.initState();

    columns.addAll([
      TrinaColumn(
        title: 'ID',
        field: 'id',
        type: TrinaColumnType.number(),
        enableContextMenu: true,
        enableFilterMenuItem: true,
        enableHideColumnMenuItem: true,
        enableSetColumnsMenuItem: true,
      ),
      TrinaColumn(
        title: 'Name',
        field: 'name',
        type: TrinaColumnType.text(),
        enableContextMenu: true,
        enableDropToResize: true,
      ),
      TrinaColumn(
        title: 'Role',
        field: 'role',
        type: TrinaColumnType.text(),
        enableContextMenu: false, // Disable context menu for this column
      ),
    ]);

    rows.addAll([
      TrinaRow(
        cells: {
          'id': TrinaCell(value: 1),
          'name': TrinaCell(value: 'John Doe'),
          'role': TrinaCell(value: 'Developer'),
        },
      ),
      TrinaRow(
        cells: {
          'id': TrinaCell(value: 2),
          'name': TrinaCell(value: 'Jane Smith'),
          'role': TrinaCell(value: 'Designer'),
        },
      ),
      TrinaRow(
        cells: {
          'id': TrinaCell(value: 3),
          'name': TrinaCell(value: 'Bob Johnson'),
          'role': TrinaCell(value: 'Manager'),
        },
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Context Menu Example')),
      body: TrinaGrid(
        columns: columns,
        rows: rows,
      ),
    );
  }
}
```

## Interaction with Other Features

Context menus work seamlessly with other TrinaGrid features:

- **Column Freezing**: The context menu provides options to freeze and unfreeze columns
- **Column Resizing**: When both `enableContextMenu` and `enableDropToResize` are enabled, the context menu icon can be dragged to resize the column
- **Column Filtering**: The context menu provides access to filtering options when `enableFilterMenuItem` is true
- **Column Visibility**: The context menu provides options to hide columns and manage column visibility

## Best Practices

- Enable context menus for columns that users might need to configure frequently
- Consider enabling all menu item types (`enableFilterMenuItem`, `enableHideColumnMenuItem`, and `enableSetColumnsMenuItem`) for a consistent user experience
- If you need custom menu items, implement a custom `TrinaColumnMenuDelegate`
- If you want to allow column resizing, enable both `enableContextMenu` and `enableDropToResize`
