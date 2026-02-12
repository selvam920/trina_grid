import 'package:flutter/material.dart';
import 'package:trina_grid/src/helper/trina_general_helper.dart';
import 'package:trina_grid/src/model/trina_column_type_has_menu_popup.dart';
import 'package:trina_grid/src/ui/cells/trina_select_cell.dart';
import 'package:trina_grid/src/ui/widgets/trina_dropdown_menu.dart';
import 'package:trina_grid/trina_grid.dart';

/// A column type for selecting a value from a predefined list of items.
///
/// This type powers columns where each cell becomes a dropdown, allowing users
/// to choose from options you provide. It is highly customizable, offering
/// different menu styles (simple, with search, with filters) and allowing
/// for custom rendering of the items in the list.
class TrinaColumnTypeSelect<T>
    with TrinaColumnTypeDefaultMixin
    implements TrinaColumnType, TrinaColumnTypeHasMenuPopup<T> {
  /// Creates a select column type.
  const TrinaColumnTypeSelect({
    required this.items,
    required this.enableColumnFilter,
    required this.menuVariant,
    this.onItemSelected,
    this.menuFiltersInitiallyExpanded = true,
    this.defaultValue,
    this.menuFilters = const [],
    this.popupIcon,
    this.menuItemBuilder,
    this.menuEmptyFilterResultBuilder,
    this.menuEmptySearchResultBuilder,
    this.menuWidth,
    this.menuItemHeight = 40,
    this.menuMaxHeight = 300,
    this.itemToString,
    this.itemToValue,
    this.itemsProvider,
  });

  @override
  final T? defaultValue;

  @override
  final List<TrinaDropdownMenuFilter> menuFilters;

  @override
  final IconData? popupIcon;

  /// {@macro TrinaDropdownMenu.variant}
  @override
  final TrinaDropdownMenuVariant menuVariant;

  /// {@macro TrinaDropdownMenu.maxHeight}
  @override
  final double menuMaxHeight;

  /// {@macro TrinaDropdownMenu.itemHeight}
  @override
  final double menuItemHeight;

  /// {@macro TrinaDropdownMenu.itemBuilder}
  @override
  final ItemBuilder<T>? menuItemBuilder;

  /// {@macro TrinaDropdownMenu.items}
  @override
  final List<T> items;

  /// Whether to enable the default column filtering UI for this column.
  final bool enableColumnFilter;

  /// {@macro TrinaDropdownMenu.onItemSelected}
  @override
  final void Function(T item)? onItemSelected;

  /// {@macro TrinaDropdownMenu.filtersInitiallyExpanded}
  @override
  final bool menuFiltersInitiallyExpanded;

  /// {@macro TrinaDropdownMenu.width}
  ///
  /// if null, [TrinaColumn.width] will be used.
  @override
  final double? menuWidth;

  /// {@macro TrinaDropdownMenu.itemToString}
  @override
  final String Function(T item)? itemToString;

  /// {@macro TrinaDropdownMenu.itemToValue}
  @override
  final dynamic Function(T item)? itemToValue;

  /// {@macro TrinaDropdownMenu.emptyFilterResultBuilder}
  @override
  final WidgetBuilder? menuEmptyFilterResultBuilder;

  /// {@macro TrinaDropdownMenu.emptySearchResultBuilder}
  @override
  final WidgetBuilder? menuEmptySearchResultBuilder;

  /// A callback function that provides items dynamically based on the row.
  /// If provided, this takes precedence over the static [items] list.
  ///
  /// Example:
  /// ```dart
  /// itemsProvider: (row, cell) {
  ///   // Return different items based on row data
  ///   if (row.cells['category']?.value == 'A') {
  ///     return ['Option1', 'Option2'];
  ///   } else {
  ///     return ['Option3', 'Option4'];
  ///   }
  /// }
  /// ```
  final List<T> Function(TrinaRow row, TrinaCell cell)? itemsProvider;

  /// A value is valid if it is present in the [items] list.
  /// When [itemsProvider] is used, validation is skipped since items are dynamic.
  @override
  bool isValid(dynamic value) {
    // If itemsProvider is used, skip validation as items are dynamic per row
    if (itemsProvider != null) {
      return true;
    }
    return items.contains(value) == true;
  }

  /// Compares two values based on their index in the [items] list.
  /// When [itemsProvider] is used, compares values as strings.
  @override
  int compare(dynamic a, dynamic b) {
    return TrinaGeneralHelper.compareWithNull(a, b, () {
      // If itemsProvider is used, compare as strings since items are dynamic
      if (itemsProvider != null) {
        return a.toString().compareTo(b.toString());
      }
      return items.indexOf(a).compareTo(items.indexOf(b));
    });
  }

  /// Returns the value itself for comparison.
  @override
  dynamic makeCompareValue(dynamic v) {
    return v;
  }

  @override
  Widget buildCell(
    TrinaGridStateManager stateManager,
    TrinaCell cell,
    TrinaColumn column,
    TrinaRow row,
  ) {
    return TrinaSelectCell<T>(
      stateManager: stateManager,
      cell: cell,
      column: column,
      row: row,
    );
  }
}
