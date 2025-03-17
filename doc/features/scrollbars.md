# Scrollbars

TrinaGrid provides extensive customization options for scrollbars, allowing you to create a better user experience, especially for desktop applications.

## Overview

Scrollbars in TrinaGrid can be customized in two ways:

1. Using the `scrollbar` property in `TrinaGridConfiguration` for general scrollbar behavior
2. Using the `scrollbarConfig` extension property for detailed appearance customization

## Basic Usage

By default, TrinaGrid shows scrollbars when needed, but they can be configured to always be visible:

```dart
TrinaGrid(
  columns: columns,
  rows: rows,
  configuration: TrinaGridConfiguration(
    scrollbar: TrinaGridScrollbarConfig(
      isAlwaysShown: true,
    ),
  ),
)
```

## Advanced Scrollbar Customization

For more detailed control over the grid's scrollbars, you can use the `scrollbarConfig` extension property:

```dart
final config = TrinaGridConfiguration(
  // General scrollbar behavior
  scrollbar: TrinaGridScrollbarConfig(
    isAlwaysShown: true,
    draggableScrollbar: true,
  ),
);

// Set custom scrollbar appearance
config.scrollbarConfig = TrinaScrollbarConfig(
  visible: true,
  showTrack: true,
  showHorizontal: true,
  showVertical: true,
  thickness: 8.0,
  minThumbLength: 40.0,
  thumbColor: Colors.blue.withOpacity(0.6),
  trackColor: Colors.grey.withOpacity(0.2),
);

TrinaGrid(
  columns: columns,
  rows: rows,
  configuration: config,
)
```

## Configuration Options

### TrinaGridScrollbarConfig

The `TrinaGridScrollbarConfig` class provides general scrollbar behavior settings:

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `isAlwaysShown` | `bool` | `false` | Whether the scrollbar is always visible |
| `draggableScrollbar` | `bool` | `true` | Whether the scrollbar can be dragged |
| `scrollbarThickness` | `double` | `6.0` | Thickness of the scrollbar |
| `scrollbarThicknessWhileDragging` | `double` | `8.0` | Thickness of the scrollbar while dragging |
| `hoverWidth` | `double` | `12.0` | Width of the hover area |
| `scrollBarColor` | `Color?` | `null` | Color of the scrollbar |
| `scrollBarTrackColor` | `Color?` | `null` | Color of the scrollbar track |

### TrinaScrollbarConfig

The `TrinaScrollbarConfig` class provides detailed appearance customization:

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `visible` | `bool` | `true` | Whether the scrollbar thumb is visible |
| `showTrack` | `bool` | `true` | Whether to show the scrollbar track |
| `showHorizontal` | `bool` | `true` | Whether to show the horizontal scrollbar |
| `showVertical` | `bool` | `true` | Whether to show the vertical scrollbar |
| `thickness` | `double` | `8.0` | Thickness of the scrollbar |
| `minThumbLength` | `double` | `40.0` | Minimum length of the scrollbar thumb |
| `thumbColor` | `Color?` | `Colors.grey.withOpacity(0.6)` | Color of the scrollbar thumb |
| `trackColor` | `Color?` | `Colors.grey.withOpacity(0.2)` | Color of the scrollbar track |

## Examples

### Always Visible Scrollbars

```dart
TrinaGrid(
  columns: columns,
  rows: rows,
  configuration: TrinaGridConfiguration(
    scrollbar: TrinaGridScrollbarConfig(
      isAlwaysShown: true,
    ),
  ),
)
```

### Custom Scrollbar Colors

```dart
final config = TrinaGridConfiguration();
config.scrollbarConfig = TrinaScrollbarConfig(
  thumbColor: Colors.blue.withOpacity(0.6),
  trackColor: Colors.grey.withOpacity(0.2),
);

TrinaGrid(
  columns: columns,
  rows: rows,
  configuration: config,
)
```

### Hiding Horizontal Scrollbar

```dart
final config = TrinaGridConfiguration();
config.scrollbarConfig = TrinaScrollbarConfig(
  showHorizontal: false,
  showVertical: true,
);

TrinaGrid(
  columns: columns,
  rows: rows,
  configuration: config,
)
```

### Thicker Scrollbars for Touch Devices

```dart
final config = TrinaGridConfiguration();
config.scrollbarConfig = TrinaScrollbarConfig(
  thickness: 12.0,
  minThumbLength: 60.0,
);

TrinaGrid(
  columns: columns,
  rows: rows,
  configuration: config,
)
```

## Best Practices

1. **Desktop Applications**: For desktop applications, consider setting `isAlwaysShown: true` to make scrollbars always visible, improving usability.

2. **Touch Devices**: For touch devices, consider using thicker scrollbars by increasing the `thickness` value.

3. **Consistent Styling**: Match scrollbar colors with your application's theme for a consistent look and feel.

4. **Accessibility**: Ensure scrollbars are visible enough for all users, especially those with visual impairments.

## Limitations

- The `TrinaScrollbarConfig` settings only apply to the grid's main scrollbars, not to any scrollable widgets inside cells.
- Some scrollbar properties might not be available on all platforms due to platform-specific implementations.

## Related Features

- [Column Freezing](column-freezing.md) - Learn how to freeze columns in place while scrolling horizontally
- [Frozen Rows](frozen-rows.md) - Learn how to freeze rows in place while scrolling vertically 