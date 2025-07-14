import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

/// Represents the merge information for a cell
class TrinaCellMerge {
  /// Number of rows this cell spans (1 means no row spanning)
  final int rowSpan;

  /// Number of columns this cell spans (1 means no column spanning)
  final int colSpan;

  /// Whether this cell is the main cell of a merged group
  /// Only the main cell renders content, others are hidden
  final bool isMainCell;

  /// The row index of the main cell if this is a spanned cell
  final int? mainCellRowIdx;

  /// The column field of the main cell if this is a spanned cell
  final String? mainCellField;

  const TrinaCellMerge({
    this.rowSpan = 1,
    this.colSpan = 1,
    this.isMainCell = true,
    this.mainCellRowIdx,
    this.mainCellField,
  });

  /// Creates a merge info for a main cell that spans multiple rows/columns
  TrinaCellMerge.mainCell({
    required this.rowSpan,
    required this.colSpan,
  })  : isMainCell = true,
        mainCellRowIdx = null,
        mainCellField = null;

  /// Creates a merge info for a spanned cell that references the main cell
  TrinaCellMerge.spannedCell({
    required this.mainCellRowIdx,
    required this.mainCellField,
  })  : rowSpan = 1,
        colSpan = 1,
        isMainCell = false;

  /// Creates a merge info for a regular cell (no merging)
  TrinaCellMerge.regular()
      : rowSpan = 1,
        colSpan = 1,
        isMainCell = true,
        mainCellRowIdx = null,
        mainCellField = null;

  /// Whether this cell is merged (spans multiple rows or columns)
  bool get isMerged => rowSpan > 1 || colSpan > 1;

  /// Whether this cell is part of a merged group but not the main cell
  bool get isSpannedCell => !isMainCell;

  /// Whether this cell should be rendered (only main cells and regular cells)
  bool get shouldRender => isMainCell;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrinaCellMerge &&
        other.rowSpan == rowSpan &&
        other.colSpan == colSpan &&
        other.isMainCell == isMainCell &&
        other.mainCellRowIdx == mainCellRowIdx &&
        other.mainCellField == mainCellField;
  }

  @override
  int get hashCode {
    return Object.hash(
      rowSpan,
      colSpan,
      isMainCell,
      mainCellRowIdx,
      mainCellField,
    );
  }

  @override
  String toString() {
    if (isSpannedCell) {
      return 'TrinaCellMerge.spannedCell(mainRow: $mainCellRowIdx, mainField: $mainCellField)';
    }
    return 'TrinaCellMerge(rowSpan: $rowSpan, colSpan: $colSpan, isMain: $isMainCell)';
  }
}

/// Represents a range of cells to be merged
class TrinaCellMergeRange {
  final int startRowIdx;
  final int endRowIdx;
  final int startColIdx;
  final int endColIdx;

  const TrinaCellMergeRange({
    required this.startRowIdx,
    required this.endRowIdx,
    required this.startColIdx,
    required this.endColIdx,
  });

  /// Creates a merge range from two cell positions
  factory TrinaCellMergeRange.fromPositions(
    TrinaGridCellPosition start,
    TrinaGridCellPosition end,
  ) {
    return TrinaCellMergeRange(
      startRowIdx: start.rowIdx! < end.rowIdx! ? start.rowIdx! : end.rowIdx!,
      endRowIdx: start.rowIdx! > end.rowIdx! ? start.rowIdx! : end.rowIdx!,
      startColIdx:
          start.columnIdx! < end.columnIdx! ? start.columnIdx! : end.columnIdx!,
      endColIdx:
          start.columnIdx! > end.columnIdx! ? start.columnIdx! : end.columnIdx!,
    );
  }

  /// Number of rows in this range
  int get rowCount => endRowIdx - startRowIdx + 1;

  /// Number of columns in this range
  int get colCount => endColIdx - startColIdx + 1;

  /// Whether this range represents a single cell
  bool get isSingleCell => rowCount == 1 && colCount == 1;

  /// Whether this range is valid for merging
  bool get isValidForMerge => rowCount > 1 || colCount > 1;

  /// Checks if a cell position is within this range
  bool containsPosition(int rowIdx, int colIdx) {
    return rowIdx >= startRowIdx &&
        rowIdx <= endRowIdx &&
        colIdx >= startColIdx &&
        colIdx <= endColIdx;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrinaCellMergeRange &&
        other.startRowIdx == startRowIdx &&
        other.endRowIdx == endRowIdx &&
        other.startColIdx == startColIdx &&
        other.endColIdx == endColIdx;
  }

  @override
  int get hashCode {
    return Object.hash(startRowIdx, endRowIdx, startColIdx, endColIdx);
  }

  @override
  String toString() {
    return 'TrinaCellMergeRange(rows: $startRowIdx-$endRowIdx, cols: $startColIdx-$endColIdx)';
  }
}

/// Utilities for working with cell merging
class TrinaCellMergeUtils {
  /// Validates if a merge range is valid
  static bool isValidMergeRange(
    TrinaCellMergeRange range,
    List<TrinaRow> rows,
    List<TrinaColumn> columns,
  ) {
    // Check bounds
    if (range.startRowIdx < 0 ||
        range.endRowIdx >= rows.length ||
        range.startColIdx < 0 ||
        range.endColIdx >= columns.length) {
      return false;
    }

    // Check if any cells in the range are already merged
    for (int rowIdx = range.startRowIdx; rowIdx <= range.endRowIdx; rowIdx++) {
      for (int colIdx = range.startColIdx;
          colIdx <= range.endColIdx;
          colIdx++) {
        final field = columns[colIdx].field;
        final cell = rows[rowIdx].cells[field];
        if (cell?.merge != null && cell!.merge!.isMerged) {
          return false;
        }
      }
    }

    return true;
  }

  /// Gets the main cell for a spanned cell
  static TrinaCell? getMainCell(
    TrinaCell spannedCell,
    List<TrinaRow> rows,
    List<TrinaColumn> columns,
  ) {
    if (spannedCell.merge?.isSpannedCell != true) {
      return null;
    }

    final mainRowIdx = spannedCell.merge!.mainCellRowIdx!;
    final mainField = spannedCell.merge!.mainCellField!;

    if (mainRowIdx >= 0 && mainRowIdx < rows.length) {
      return rows[mainRowIdx].cells[mainField];
    }

    return null;
  }

  /// Gets all spanned cells for a main cell
  static List<TrinaCell> getSpannedCells(
    TrinaCell mainCell,
    int mainRowIdx,
    int mainColIdx,
    List<TrinaRow> rows,
    List<TrinaColumn> columns,
  ) {
    if (mainCell.merge?.isMainCell != true || !mainCell.merge!.isMerged) {
      return [];
    }

    final List<TrinaCell> spannedCells = [];
    final rowSpan = mainCell.merge!.rowSpan;
    final colSpan = mainCell.merge!.colSpan;

    for (int rowIdx = mainRowIdx; rowIdx < mainRowIdx + rowSpan; rowIdx++) {
      for (int colIdx = mainColIdx; colIdx < mainColIdx + colSpan; colIdx++) {
        // Skip the main cell itself
        if (rowIdx == mainRowIdx && colIdx == mainColIdx) continue;

        if (rowIdx < rows.length && colIdx < columns.length) {
          final field = columns[colIdx].field;
          final cell = rows[rowIdx].cells[field];
          if (cell != null) {
            spannedCells.add(cell);
          }
        }
      }
    }

    return spannedCells;
  }

  /// Calculates the visual bounds of a merged cell
  static Rect calculateMergedCellBounds(
    TrinaCell mainCell,
    int mainRowIdx,
    int mainColIdx,
    List<TrinaColumn> columns,
    double rowHeight,
  ) {
    if (mainCell.merge?.isMainCell != true) {
      return Rect.zero;
    }

    final rowSpan = mainCell.merge!.rowSpan;
    final colSpan = mainCell.merge!.colSpan;

    // Calculate width by summing column widths
    double width = 0;
    for (int i = mainColIdx;
        i < mainColIdx + colSpan && i < columns.length;
        i++) {
      width += columns[i].width;
    }

    // Calculate height by multiplying row height by row span
    final height = rowHeight * rowSpan;

    return Rect.fromLTWH(0, 0, width, height);
  }
}
