# Column Filtering

Column filtering is a powerful feature that allows users to display only the rows that match specific criteria. This feature enhances data analysis by enabling users to focus on relevant information and quickly find specific values within large datasets.

## Overview

TrinaGrid provides a comprehensive column filtering system that supports various filter types for different column data types. Users can filter data through a dedicated filter row that appears below the column headers, and developers can also programmatically apply filters using the state manager API.

## Enabling Column Filtering

To enable column filtering in your TrinaGrid, you need to set the `showColumnFilter` property to `true`:

```dart
TrinaGrid(
  columns: columns,
  rows: rows,
  onLoaded: (TrinaGridOnLoadedEvent event) {
    // Enable column filtering
    event.stateManager.setShowColumnFilter(true);
  },
)
```

When column filtering is enabled, a filter row appears below the column headers, allowing users to enter filter criteria for each column.

## Filter Types

TrinaGrid includes several built-in filter types that can be used to filter data in different ways:

### Text Filters

- **Contains** (`TrinaFilterTypeContains`): Matches rows where the cell value contains the search text
- **Equals** (`TrinaFilterTypeEquals`): Matches rows where the cell value exactly matches the search text
- **Starts With** (`TrinaFilterTypeStartsWith`): Matches rows where the cell value starts with the search text
- **Ends With** (`TrinaFilterTypeEndsWith`): Matches rows where the cell value ends with the search text

### Numeric Filters

- **Greater Than** (`TrinaFilterTypeGreaterThan`): Matches rows where the cell value is greater than the search value
- **Greater Than or Equal To** (`TrinaFilterTypeGreaterThanOrEqualTo`): Matches rows where the cell value is greater than or equal to the search value
- **Less Than** (`TrinaFilterTypeLessThan`): Matches rows where the cell value is less than the search value
- **Less Than or Equal To** (`TrinaFilterTypeLessThanOrEqualTo`): Matches rows where the cell value is less than or equal to the search value

## Filter UI

The filter UI consists of:

1. **Filter Row**: A row below the column headers where users can enter filter criteria
2. **Filter Type Selector**: A dropdown menu that allows users to select the type of filter to apply
3. **Filter Input Field**: A text field where users can enter the filter value

Users can click on the filter icon in a column to open the filter type selector and choose the appropriate filter type for that column.

## Filtering Behavior

### Column-Specific Filtering

By default, filters are applied to specific columns. When a user enters a filter value for a column, only that column's values are checked against the filter criteria.

### All-Column Filtering

TrinaGrid also supports filtering across all columns. This allows users to search for a value anywhere in the grid, regardless of which column it appears in.

### Multiple Filters

Users can apply multiple filters to different columns simultaneously. When multiple filters are applied, rows must match all filter criteria to be displayed (AND logic).

## Configuring Column Filtering

You can customize the column filtering behavior through the `columnFilter` configuration:

```dart
TrinaGrid(
  columns: columns,
  rows: rows,
  configuration: TrinaGridConfiguration(
    columnFilter: TrinaGridColumnFilterConfig(
      // Specify which filter types are available
      filters: const [
        ...FilterHelper.defaultFilters,
        // Add custom filters if needed
        CustomFilter(),
      ],
      // Set default filter types for specific columns
      resolveDefaultColumnFilter: (column, resolver) {
        if (column.field == 'text') {
          return resolver<TrinaFilterTypeContains>() as TrinaFilterType;
        } else if (column.field == 'number') {
          return resolver<TrinaFilterTypeGreaterThan>() as TrinaFilterType;
        } else if (column.field == 'date') {
          return resolver<TrinaFilterTypeLessThan>() as TrinaFilterType;
        }
        
        // Default filter type for other columns
        return resolver<TrinaFilterTypeContains>() as TrinaFilterType;
      },
    ),
  ),
)
```

### Disabling Filtering for Specific Columns

You can disable filtering for specific columns by setting the `enableFilterMenuItem` property to `false`:

```dart
TrinaColumn(
  title: 'Actions',
  field: 'actions',
  type: TrinaColumnType.text(),
  enableFilterMenuItem: false, // Disable filtering for this column
)
```

## Custom Filters

You can create custom filter types by implementing the `TrinaFilterType` interface:

```dart
class CustomFilter implements TrinaFilterType {
  @override
  String get title => 'Custom Filter';

  @override
  get compare => ({
        required String? base,
        required String? search,
        required TrinaColumn? column,
      }) {
        // Implement your custom filtering logic here
        // Return true if the row should be included, false otherwise
        return customFilterLogic(base, search);
      };

  const CustomFilter();
}
```

Then add your custom filter to the `filters` list in the `columnFilter` configuration.

## Programmatic Filtering

You can programmatically apply filters using the state manager:

```dart
// Create a filter row
TrinaRow filterRow = FilterHelper.createFilterRow(
  columnField: 'column_field',
  filterType: const TrinaFilterTypeContains(),
  filterValue: 'search_value',
);

// Apply the filter
stateManager.setFilterRows([filterRow]);
```

To filter across all columns:

```dart
TrinaRow filterRow = FilterHelper.createFilterRow(
  columnField: FilterHelper.filterFieldAllColumns,
  filterType: const TrinaFilterTypeContains(),
  filterValue: 'search_value',
);

stateManager.setFilterRows([filterRow]);
```

To clear all filters:

```dart
stateManager.setFilterRows([]);
```

## Events

When filters are applied, TrinaGrid updates its display and notifies listeners. You can listen to these changes through the `onChanged` callback:

```dart
TrinaGrid(
  columns: columns,
  rows: rows,
  onChanged: (TrinaGridOnChangedEvent event) {
    // Handle grid changes, including filtering
    if (event.type == TrinaGridChangeEventType.filterRows) {
      print('Filters changed');
    }
  },
)
```

## Example

Here's a complete example demonstrating column filtering:

```dart
import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

class ColumnFilteringExample extends StatefulWidget {
  @override
  _ColumnFilteringExampleState createState() => _ColumnFilteringExampleState();
}

class _ColumnFilteringExampleState extends State<ColumnFilteringExample> {
  final List<TrinaColumn> columns = [];
  final List<TrinaRow> rows = [];
  late TrinaGridStateManager stateManager;

  @override
  void initState() {
    super.initState();

    columns.addAll([
      TrinaColumn(
        title: 'ID',
        field: 'id',
        type: TrinaColumnType.number(),
      ),
      TrinaColumn(
        title: 'Name',
        field: 'name',
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
        title: 'Department',
        field: 'department',
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
        title: 'Salary',
        field: 'salary',
        type: TrinaColumnType.number(),
      ),
    ]);

    rows.addAll([
      TrinaRow(
        cells: {
          'id': TrinaCell(value: 1),
          'name': TrinaCell(value: 'John Smith'),
          'department': TrinaCell(value: 'Engineering'),
          'salary': TrinaCell(value: 85000),
        },
      ),
      TrinaRow(
        cells: {
          'id': TrinaCell(value: 2),
          'name': TrinaCell(value: 'Jane Doe'),
          'department': TrinaCell(value: 'Marketing'),
          'salary': TrinaCell(value: 75000),
        },
      ),
      TrinaRow(
        cells: {
          'id': TrinaCell(value: 3),
          'name': TrinaCell(value: 'Bob Johnson'),
          'department': TrinaCell(value: 'Engineering'),
          'salary': TrinaCell(value: 90000),
        },
      ),
      TrinaRow(
        cells: {
          'id': TrinaCell(value: 4),
          'name': TrinaCell(value: 'Alice Williams'),
          'department': TrinaCell(value: 'Sales'),
          'salary': TrinaCell(value: 80000),
        },
      ),
    ]);
  }

  void _filterEngineering() {
    // Create a filter for the Engineering department
    TrinaRow filterRow = FilterHelper.createFilterRow(
      columnField: 'department',
      filterType: const TrinaFilterTypeEquals(),
      filterValue: 'Engineering',
    );

    // Apply the filter
    stateManager.setFilterRows([filterRow]);
  }

  void _filterHighSalary() {
    // Create a filter for salaries > 80000
    TrinaRow filterRow = FilterHelper.createFilterRow(
      columnField: 'salary',
      filterType: const TrinaFilterTypeGreaterThan(),
      filterValue: '80000',
    );

    // Apply the filter
    stateManager.setFilterRows([filterRow]);
  }

  void _clearFilters() {
    // Clear all filters
    stateManager.setFilterRows([]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Column Filtering Example')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _filterEngineering,
                  child: Text('Filter Engineering'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _filterHighSalary,
                  child: Text('Filter Salary > 80000'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _clearFilters,
                  child: Text('Clear Filters'),
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
                // Enable column filtering
                stateManager.setShowColumnFilter(true);
              },
              onChanged: (TrinaGridOnChangedEvent event) {
                print('Grid changed: ${event.type}');
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## Best Practices

1. **Enable Filtering Selectively**: Only enable filtering for columns where it makes sense. For action columns or columns with complex widgets, filtering may not be relevant.

2. **Choose Appropriate Default Filters**: Set default filter types that make sense for each column's data type. For example, use "Contains" for text columns and "Greater Than" for numeric columns.

3. **Provide Clear UI Indicators**: Ensure that users can easily see which filters are currently applied. TrinaGrid automatically highlights filtered columns.

4. **Consider Performance**: For very large datasets, consider implementing server-side filtering to improve performance.

5. **Combine with Sorting**: Filtering works well in combination with sorting, allowing users to find and organize data more efficiently.

6. **Save User Preferences**: Consider saving the user's filter preferences to restore them when they return to the grid.

## Related Features

- [Column Types](column-types.md)
- [Column Sorting](column-sorting.md)
- [Column Resizing](column-resizing.md)
- [Column Moving](column-moving.md)
- [Column Hiding](column-hiding.md)
