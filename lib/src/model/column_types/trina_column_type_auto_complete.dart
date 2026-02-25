import 'package:flutter/material.dart';
import 'package:trina_grid/src/helper/trina_general_helper.dart';
import 'package:trina_grid/src/ui/cells/trina_auto_complete_cell.dart';
import 'package:trina_grid/trina_grid.dart';

/// A column type that provides autocomplete/typeahead functionality.
///
/// As the user types, [fetchItems] is called to retrieve matching suggestions.
/// Results are displayed in a dropdown overlay with keyboard navigation support.
///
/// Example:
/// ```dart
/// TrinaColumnType.autoComplete<String>(
///   fetchItems: (query) async {
///     return cities.where((c) => c.toLowerCase().contains(query.toLowerCase())).toList();
///   },
/// )
/// ```
class TrinaColumnTypeAutoComplete<T>
    with TrinaColumnTypeDefaultMixin
    implements TrinaColumnType {
  /// Async function to fetch matching items based on user input.
  final TrinaAutoCompleteFetchItems<T> fetchItems;

  /// Width of the autocomplete dropdown. If null, uses the column width.
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

  /// Whether to automatically open the autocomplete dropdown when the cell is focused.
  final bool autoOpen;

  /// Function to get display string for an option.
  /// Used to set the text field value when an option is selected.
  /// If null, `toString()` is used.
  final TrinaAutocompleteOptionToString<T>? displayStringForOption;

  /// Function to convert an item to its string representation for display.
  /// If null, `toString()` is used.
  final String Function(T item)? itemToString;

  /// Function to extract a comparable value from an item.
  /// Used for sorting and comparison. If null, the item itself is used.
  final dynamic Function(T item)? itemToValue;

  const TrinaColumnTypeAutoComplete({
    this.defaultValue,
    required this.fetchItems,
    this.width,
    this.initialValue,
    this.onItemSelected,
    this.itemBuilder,
    this.maxHeight = 300,
    this.autoOpen = false,
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
    return TrinaGeneralHelper.compareWithNull(
      a,
      b,
      () => a.toString().compareTo(b.toString()),
    );
  }

  @override
  dynamic makeCompareValue(dynamic v) {
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
    return TrinaAutoCompleteCell<T>(
      stateManager: stateManager,
      cell: cell,
      column: column,
      row: row,
      fetchItems: fetchItems,
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
