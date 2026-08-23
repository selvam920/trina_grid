import 'package:material_ui/material_ui.dart';
import 'package:trina_grid/src/helper/trina_general_helper.dart';
import 'package:trina_grid/src/ui/cells/trina_dropdown_cell.dart';
import 'package:trina_grid/trina_grid.dart';

/// A column type that provides a dropdown selection from a static list of items.
///
/// Unlike [TrinaColumnTypeSelect], this type uses an overlay-based dropdown
/// similar to [TrinaColumnTypeAutoComplete] but without an editable text field.
/// It also supports automatically opening the dropdown when the cell is focused.
class TrinaColumnTypeDropdown<T>
    with TrinaColumnTypeDefaultMixin
    implements TrinaColumnType {
  /// The list of items to display in the dropdown.
  final List<T> items;

  /// A callback to provide items dynamically per row.
  /// If provided, this takes precedence over [items].
  final List<T> Function(TrinaRow row, TrinaCell cell)? itemsProvider;

  /// Width of the dropdown. If null, uses the column width.
  final double? width;

  /// The initially selected value, which will be highlighted in the list.
  final T? initialValue;

  /// Called when an item is selected from the list.
  final void Function(T item)? onItemSelected;

  /// A builder function to create a custom widget for each item in the list.
  /// If null, a default Text widget showing the item's string representation is used.
  final TrinaAutoCompleteItemBuilder<T>? itemBuilder;

  /// The maximum height of the popup menu's scrollable area.
  final double maxHeight;

  /// Whether to automatically open the dropdown when the cell is focused.
  final bool autoOpen;

  /// Function to get display string for an option.
  /// Used to set the text field value when an option is selected.
  /// If null, `toString()` is used.
  final TrinaAutocompleteOptionToString<T>? displayStringForOption;

  /// Function to convert an item to its string representation.
  /// Used for generating comparison values.
  final String Function(T)? itemToString;

  /// Function to extract a comparable value from an item.
  /// Used for sorting.
  final dynamic Function(T)? itemToValue;

  const TrinaColumnTypeDropdown({
    this.defaultValue,
    required this.items,
    this.itemsProvider,
    this.width,
    this.initialValue,
    this.onItemSelected,
    this.itemBuilder,
    this.maxHeight = 300,
    this.autoOpen = true,
    this.displayStringForOption,
    this.itemToString,
    this.itemToValue,
  });

  @override
  final dynamic defaultValue;

  @override
  bool isValid(dynamic value) {
    return true;
  }

  @override
  int compare(dynamic a, dynamic b) {
    if (itemToValue != null) {
      return itemToValue!(a).compareTo(itemToValue!(b));
    }
    return TrinaGeneralHelper.compareWithNull(
      a,
      b,
      () {
        if (itemsProvider != null) {
          return a.toString().compareTo(b.toString());
        }
        return items.indexOf(a).compareTo(items.indexOf(b));
      },
    );
  }

  @override
  dynamic makeCompareValue(dynamic v) {
    if (itemToString != null) {
      return itemToString!(v);
    }
    return v.toString();
  }

  @override
  String? formatValue(dynamic value) {
    if (value == null) return null;
    if (displayStringForOption != null && value is T) {
      return displayStringForOption!(value);
    }
    return null;
  }

  /// Default item builder that renders a simple text widget.
  static Widget _defaultItemBuilder<T>(
    BuildContext context,
    T item,
    bool selected,
  ) {
    return Text(
      item.toString(),
      style: TextStyle(
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget buildCell(
    TrinaGridStateManager stateManager,
    TrinaCell cell,
    TrinaColumn column,
    TrinaRow row,
  ) {
    return TrinaDropdownCell<T>(
      stateManager: stateManager,
      cell: cell,
      column: column,
      row: row,
      items: items,
      itemsProvider: itemsProvider,
      width: width ?? column.width,
      initialValue: initialValue,
      onItemSelected: onItemSelected ?? (_) {},
      itemBuilder: itemBuilder ?? _defaultItemBuilder<T>,
      maxHeight: maxHeight,
      autoOpen: autoOpen,
      displayStringForOption: displayStringForOption,
    );
  }
}
