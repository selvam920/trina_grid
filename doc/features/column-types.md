# Column Types

TrinaGrid supports various column types to handle different kinds of data efficiently. Each column type provides specialized rendering, editing, filtering, and sorting capabilities tailored to specific data types.

## Overview

When creating columns for your TrinaGrid, you can specify the column type using the `type` property of `TrinaColumn`. The column type determines:

- How cell values are displayed
- The editor widget used for editing cells
- How values are sorted
- Available filtering options

## Available Column Types

TrinaGrid provides the following built-in column types:

### Text Column

The default column type for displaying and editing text values.

```dart
TrinaColumn(
  title: 'Name',
  field: 'name',
  type: TrinaColumnType.text(),
)
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `textAlign` | `TextAlign` | Alignment of text within cells |
| `maxLines` | `int?` | Maximum number of lines to display |
| `overflow` | `TextOverflow` | How to handle text overflow |
| `enableAutoSize` | `bool` | Whether to automatically resize text to fit |

### Number Column

Specialized for numeric values with formatting options.

```dart
TrinaColumn(
  title: 'Price',
  field: 'price',
  type: TrinaColumnType.number(
    format: '#,##0.00',
    negative: true,
    decimal: true,
  ),
)
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `format` | `String?` | Number format pattern |
| `negative` | `bool` | Whether to allow negative values |
| `decimal` | `bool` | Whether to allow decimal values |
| `decimalDigits` | `int?` | Number of decimal places to display |
| `thousandSeparator` | `String` | Character used as thousand separator |
| `decimalSeparator` | `String` | Character used as decimal separator |
| `prefix` | `String?` | Text to display before the number (e.g., currency symbol) |
| `suffix` | `String?` | Text to display after the number (e.g., unit) |

### Date Column

For displaying and editing date values.

```dart
TrinaColumn(
  title: 'Birth Date',
  field: 'birthDate',
  type: TrinaColumnType.date(
    format: 'yyyy-MM-dd',
  ),
)
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `format` | `String` | Date format pattern |
| `startDate` | `DateTime?` | Minimum selectable date |
| `endDate` | `DateTime?` | Maximum selectable date |
| `datePickerTheme` | `DatePickerThemeData?` | Theme for the date picker |

### Time Column

For displaying and editing time values.

```dart
TrinaColumn(
  title: 'Start Time',
  field: 'startTime',
  type: TrinaColumnType.time(
    format: 'HH:mm',
  ),
)
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `format` | `String` | Time format pattern |
| `use24HourFormat` | `bool` | Whether to use 24-hour format |
| `minuteInterval` | `int` | Interval between selectable minutes |

### DateTime Column

Combines date and time functionality.

```dart
TrinaColumn(
  title: 'Created At',
  field: 'createdAt',
  type: TrinaColumnType.dateTime(
    dateFormat: 'yyyy-MM-dd',
    timeFormat: 'HH:mm:ss',
  ),
)
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `dateFormat` | `String` | Date format pattern |
| `timeFormat` | `String` | Time format pattern |
| `startDate` | `DateTime?` | Minimum selectable date |
| `endDate` | `DateTime?` | Maximum selectable date |
| `use24HourFormat` | `bool` | Whether to use 24-hour format |

### Select Column

For selecting from predefined options.

```dart
TrinaColumn(
  title: 'Status',
  field: 'status',
  type: TrinaColumnType.select(
    items: [
      SelectItem(value: 'pending', label: 'Pending'),
      SelectItem(value: 'in_progress', label: 'In Progress'),
      SelectItem(value: 'completed', label: 'Completed'),
      SelectItem(value: 'cancelled', label: 'Cancelled'),
    ],
  ),
)
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `items` | `List<SelectItem>` | List of selectable items |
| `enableSearch` | `bool` | Whether to enable search in dropdown |
| `enableFilter` | `bool` | Whether to enable filtering in dropdown |
| `enableMultiSelect` | `bool` | Whether to allow selecting multiple items |

### Boolean Column

For displaying and editing boolean values.

```dart
TrinaColumn(
  title: 'Active',
  field: 'isActive',
  type: TrinaColumnType.boolean(
    trueText: 'Yes',
    falseText: 'No',
    allowEmpty: false,
    defaultValue: false,
    width: 120,
    popupIcon: Icons.check_box,
    builder: (item) => CustomBooleanWidget(value: item),
    onItemSelected: (event) {
      // Handle selection event
    },
  ),
)
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `defaultValue` | `dynamic` | Default value for new cells (defaults to `false`) |
| `allowEmpty` | `bool` | Whether to allow null/empty values (defaults to `false`) |
| `trueText` | `String` | Text to display for true values (defaults to "Yes") |
| `falseText` | `String` | Text to display for false values (defaults to "No") |
| `width` | `double?` | Width of the popup selector |
| `popupIcon` | `IconData?` | Icon to display for opening the popup selector |
| `builder` | `Widget Function(dynamic item)?` | Custom widget builder for rendering boolean values |
| `onItemSelected` | `Function(TrinaGridOnSelectedEvent event)?` | Callback when a value is selected |

### Currency Column

Specialized for monetary values.

```dart
TrinaColumn(
  title: 'Price',
  field: 'price',
  type: TrinaColumnType.currency(
    symbol: '\$',
    decimalDigits: 2,
  ),
)
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `symbol` | `String` | Currency symbol |
| `symbolPosition` | `CurrencySymbolPosition` | Position of currency symbol (before/after) |
| `decimalDigits` | `int` | Number of decimal places |
| `thousandSeparator` | `String` | Character used as thousand separator |
| `decimalSeparator` | `String` | Character used as decimal separator |
| `negativeFormat` | `CurrencyNegativeFormat` | How to format negative values |

### Percentage Column

For displaying and editing percentage values.

```dart
TrinaColumn(
  title: 'Completion',
  field: 'completion',
  type: TrinaColumnType.percentage(
    decimalDigits: 1,
    showSymbol: true,
  ),
)
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `decimalDigits` | `int` | Number of decimal places |
| `showSymbol` | `bool` | Whether to show the % symbol |
| `symbolPosition` | `PercentageSymbolPosition` | Position of % symbol (before/after) |
| `inputAsDecimal` | `bool` | Whether to input as decimal (0.5) or percentage (50) |

### Custom Column

For implementing custom column behavior.

```dart
TrinaColumn(
  title: 'Rating',
  field: 'rating',
  type: TrinaColumnType.custom(
    renderer: (rendererContext) {
      // Custom rendering logic
      return StarRating(rating: rendererContext.cell.value);
    },
    editor: (editorContext) {
      // Custom editing logic
      return StarRatingEditor(
        initialValue: editorContext.cell.value,
        onChanged: (value) => editorContext.onChanged(value),
      );
    },
  ),
)
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `renderer` | `Widget Function(TrinaCellRendererContext)` | Custom cell renderer function |
| `editor` | `Widget Function(TrinaCellEditorContext)` | Custom cell editor function |
| `valueParser` | `dynamic Function(dynamic)` | Function to parse cell value |
| `valueFormatter` | `String Function(dynamic)` | Function to format cell value |
| `comparator` | `int Function(dynamic, dynamic)` | Custom comparator for sorting |

## Column Type Configuration

### Default Column Type

You can set a default column type for all columns in your grid:

```dart
TrinaGrid(
  columns: columns,
  rows: rows,
  configuration: TrinaGridConfiguration(
    defaultColumnType: TrinaColumnType.text(),
  ),
)
```

### Type Inheritance

Column types can inherit properties from other column types:

```dart
// Create a base column type with common properties
final baseTextColumn = TrinaColumnType.text(
  textAlign: TextAlign.start,
  maxLines: 2,
);

// Create columns that inherit from the base type
TrinaColumn(
  title: 'Description',
  field: 'description',
  type: baseTextColumn.copyWith(
    maxLines: 3,
    overflow: TextOverflow.ellipsis,
  ),
)
```

## Best Practices

1. **Choose the appropriate column type** for your data to leverage built-in formatting, editing, and validation
2. **Use custom column types** when you need specialized behavior not covered by built-in types
3. **Create reusable column type configurations** for consistent appearance across your grid
4. **Consider performance implications** when using complex custom renderers or editors
5. **Provide clear validation feedback** to users when they enter invalid data

## Examples

### Mixed Column Types

```dart
List<TrinaColumn> columns = [
  TrinaColumn(
    title: 'ID',
    field: 'id',
    type: TrinaColumnType.number(format: '#'),
    width: 80,
    frozen: true,
  ),
  TrinaColumn(
    title: 'Name',
    field: 'name',
    type: TrinaColumnType.text(),
    width: 150,
  ),
  TrinaColumn(
    title: 'Birth Date',
    field: 'birthDate',
    type: TrinaColumnType.date(format: 'yyyy-MM-dd'),
    width: 120,
  ),
  TrinaColumn(
    title: 'Salary',
    field: 'salary',
    type: TrinaColumnType.currency(
      symbol: '\$',
      decimalDigits: 2,
    ),
    width: 120,
  ),
  TrinaColumn(
    title: 'Active',
    field: 'isActive',
    type: TrinaColumnType.boolean(useCheckbox: true),
    width: 100,
  ),
  TrinaColumn(
    title: 'Department',
    field: 'department',
    type: TrinaColumnType.select(
      items: [
        SelectItem(value: 'engineering', label: 'Engineering'),
        SelectItem(value: 'marketing', label: 'Marketing'),
        SelectItem(value: 'sales', label: 'Sales'),
        SelectItem(value: 'hr', label: 'HR'),
      ],
    ),
    width: 150,
  ),
];
```

### Custom Rating Column

```dart
TrinaColumn(
  title: 'Rating',
  field: 'rating',
  type: TrinaColumnType.custom(
    renderer: (rendererContext) {
      final rating = rendererContext.cell.value as double;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          return Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 16,
          );
        }),
      );
    },
    editor: (editorContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          double rating = editorContext.cell.value ?? 0.0;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  setState(() {
                    rating = index + 1.0;
                    editorContext.onChanged(rating);
                  });
                },
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 24, minHeight: 24),
              );
            }),
          );
        },
      );
    },
  ),
  width: 150,
)
```

## Related Features

- [Column Renderers](column-renderer.md) - For more advanced column rendering
- [Cell Editing](cell-editing.md) - For more details on cell editing behavior
- [Cell Validation](cell-validation.md) - For validating cell input
- [Column Filtering](column-filtering.md) - For filtering data based on column values
- [Column Sorting](column-sorting.md) - For sorting data based on column values
