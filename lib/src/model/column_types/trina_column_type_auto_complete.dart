import 'package:flutter/material.dart';
import 'package:trina_grid/src/helper/trina_general_helper.dart';
import 'package:trina_grid/src/ui/cells/trina_auto_complete.dart';
import 'package:trina_grid/trina_grid.dart';

class TrinaColumnTypeAutoComplete<T>
    with TrinaColumnTypeDefaultMixin
    implements TrinaColumnType {
  final TrinaAutoCompleteFetchItems<T> fetchItems;
  final double width;
  final T? initialValue;
  final void Function(T item) onItemSelected;
  final TrinaAutoCompleteItemBuilder<T> itemBuilder;
  final double maxHeight;
  final TrinaAutocompleteOptionToString<T>? displayStringForOption;

  const TrinaColumnTypeAutoComplete({
    this.defaultValue,
    required this.fetchItems,
    required this.width,
    required this.initialValue,
    required this.onItemSelected,
    required this.itemBuilder,
    required this.maxHeight,
    this.displayStringForOption,
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
      width: width,
      initialValue: initialValue,
      onItemSelected: onItemSelected,
      itemBuilder: itemBuilder,
      maxHeight: maxHeight,
      displayStringForOption: displayStringForOption,
    );
  }
}
