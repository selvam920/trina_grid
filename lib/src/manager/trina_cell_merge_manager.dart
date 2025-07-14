import 'package:trina_grid/trina_grid.dart';

/// Manager for handling cell merging operations
class TrinaCellMergeManager {
  final TrinaGridStateManager stateManager;

  TrinaCellMergeManager(this.stateManager);

  /// Merges cells in the specified range
  /// Returns true if merge was successful, false otherwise
  bool mergeCells(TrinaCellMergeRange range) {
    if (!_canMergeCells(range)) {
      return false;
    }

    final columns = stateManager.refColumns;
    final rows = stateManager.refRows;

    // Get the main cell (top-left cell of the range)
    final mainRowIdx = range.startRowIdx;
    final mainColIdx = range.startColIdx;
    final mainField = columns[mainColIdx].field;
    final mainCell = rows[mainRowIdx].cells[mainField];

    if (mainCell == null) {
      return false;
    }

    // Create merge info for the main cell
    final mainMergeInfo = TrinaCellMerge.mainCell(
      rowSpan: range.rowCount,
      colSpan: range.colCount,
    );

    // Update the main cell with merge information
    final updatedMainCell = TrinaCell(
      value: mainCell.value,
      key: mainCell.key,
      renderer: mainCell.renderer,
      onChanged: mainCell.onChanged,
      merge: mainMergeInfo,
    );

    // Initialize the new cell with column and row information
    if (mainCell.initialized) {
      updatedMainCell.setColumn(mainCell.column);
      updatedMainCell.setRow(mainCell.row);
    }

    rows[mainRowIdx].cells[mainField] = updatedMainCell;

    // Update all spanned cells to reference the main cell
    for (int rowIdx = range.startRowIdx; rowIdx <= range.endRowIdx; rowIdx++) {
      for (int colIdx = range.startColIdx;
          colIdx <= range.endColIdx;
          colIdx++) {
        // Skip the main cell
        if (rowIdx == mainRowIdx && colIdx == mainColIdx) continue;

        final field = columns[colIdx].field;
        final cell = rows[rowIdx].cells[field];

        if (cell != null) {
          final spannedMergeInfo = TrinaCellMerge.spannedCell(
            mainCellRowIdx: mainRowIdx,
            mainCellField: mainField,
          );

          final updatedSpannedCell = TrinaCell(
            value: cell.value,
            key: cell.key,
            renderer: cell.renderer,
            onChanged: cell.onChanged,
            merge: spannedMergeInfo,
          );

          // Initialize the new cell with column and row information
          if (cell.initialized) {
            updatedSpannedCell.setColumn(cell.column);
            updatedSpannedCell.setRow(cell.row);
          }

          rows[rowIdx].cells[field] = updatedSpannedCell;
        }
      }
    }

    // Notify listeners about the change
    stateManager.notifyListeners();
    return true;
  }

  /// Unmerges cells in the specified range or containing the specified cell
  /// Returns true if unmerge was successful, false otherwise
  bool unmergeCells({TrinaCellMergeRange? range, TrinaCell? cell}) {
    if (range != null) {
      return _unmergeCellsByRange(range);
    } else if (cell != null) {
      return _unmergeCellByCell(cell);
    }
    return false;
  }

  /// Unmerges all merged cells in the grid
  void unmergeAllCells() {
    final rows = stateManager.refRows;
    final columns = stateManager.refColumns;

    bool hasChanges = false;

    for (int rowIdx = 0; rowIdx < rows.length; rowIdx++) {
      for (int colIdx = 0; colIdx < columns.length; colIdx++) {
        final field = columns[colIdx].field;
        final cell = rows[rowIdx].cells[field];

        if (cell?.merge != null) {
          final updatedCell = TrinaCell(
            value: cell!.value,
            key: cell.key,
            renderer: cell.renderer,
            onChanged: cell.onChanged,
            merge: null,
          );

          // Initialize the new cell with column and row information
          if (cell.initialized) {
            updatedCell.setColumn(cell.column);
            updatedCell.setRow(cell.row);
          }

          rows[rowIdx].cells[field] = updatedCell;
          hasChanges = true;
        }
      }
    }

    if (hasChanges) {
      stateManager.notifyListeners();
    }
  }

  /// Gets the merge range for a merged cell
  TrinaCellMergeRange? getMergeRange(TrinaCell cell, int rowIdx, int colIdx) {
    if (cell.merge == null) {
      return null;
    }

    if (cell.merge!.isMainCell) {
      return TrinaCellMergeRange(
        startRowIdx: rowIdx,
        endRowIdx: rowIdx + cell.merge!.rowSpan - 1,
        startColIdx: colIdx,
        endColIdx: colIdx + cell.merge!.colSpan - 1,
      );
    } else {
      // For spanned cells, find the main cell and get its range
      final mainCell = TrinaCellMergeUtils.getMainCell(
        cell,
        stateManager.refRows,
        stateManager.refColumns,
      );

      if (mainCell != null) {
        final mainRowIdx = cell.merge!.mainCellRowIdx!;
        final mainColIdx = stateManager.refColumns
            .indexWhere((col) => col.field == cell.merge!.mainCellField);

        if (mainColIdx != -1) {
          return TrinaCellMergeRange(
            startRowIdx: mainRowIdx,
            endRowIdx: mainRowIdx + mainCell.merge!.rowSpan - 1,
            startColIdx: mainColIdx,
            endColIdx: mainColIdx + mainCell.merge!.colSpan - 1,
          );
        }
      }
    }

    return null;
  }

  /// Checks if cells can be merged in the specified range
  bool _canMergeCells(TrinaCellMergeRange range) {
    final columns = stateManager.refColumns;
    final rows = stateManager.refRows;

    // Validate range bounds
    if (!TrinaCellMergeUtils.isValidMergeRange(range, rows, columns)) {
      return false;
    }

    // Check if all columns in the range allow merging
    for (int colIdx = range.startColIdx; colIdx <= range.endColIdx; colIdx++) {
      if (!columns[colIdx].enableCellMerge) {
        return false;
      }
    }

    // Check if any cells in the range are already merged
    for (int rowIdx = range.startRowIdx; rowIdx <= range.endRowIdx; rowIdx++) {
      for (int colIdx = range.startColIdx;
          colIdx <= range.endColIdx;
          colIdx++) {
        final field = columns[colIdx].field;
        final cell = rows[rowIdx].cells[field];
        if (cell?.merge != null) {
          return false;
        }
      }
    }

    return true;
  }

  /// Unmerges cells by range
  bool _unmergeCellsByRange(TrinaCellMergeRange range) {
    final columns = stateManager.refColumns;
    final rows = stateManager.refRows;

    bool hasChanges = false;

    for (int rowIdx = range.startRowIdx; rowIdx <= range.endRowIdx; rowIdx++) {
      for (int colIdx = range.startColIdx;
          colIdx <= range.endColIdx;
          colIdx++) {
        final field = columns[colIdx].field;
        final cell = rows[rowIdx].cells[field];

        if (cell?.merge != null) {
          final updatedCell = TrinaCell(
            value: cell!.value,
            key: cell.key,
            renderer: cell.renderer,
            onChanged: cell.onChanged,
            merge: null,
          );

          // Initialize the new cell with column and row information
          if (cell.initialized) {
            updatedCell.setColumn(cell.column);
            updatedCell.setRow(cell.row);
          }

          rows[rowIdx].cells[field] = updatedCell;
          hasChanges = true;
        }
      }
    }

    if (hasChanges) {
      stateManager.notifyListeners();
    }

    return hasChanges;
  }

  /// Unmerges a specific cell
  bool _unmergeCellByCell(TrinaCell cell) {
    if (cell.merge == null) {
      return false;
    }

    final columns = stateManager.refColumns;
    final rows = stateManager.refRows;

    if (cell.merge!.isMainCell) {
      // Find the main cell position
      int? mainRowIdx;
      int? mainColIdx;

      for (int rowIdx = 0; rowIdx < rows.length; rowIdx++) {
        for (int colIdx = 0; colIdx < columns.length; colIdx++) {
          final field = columns[colIdx].field;
          if (rows[rowIdx].cells[field] == cell) {
            mainRowIdx = rowIdx;
            mainColIdx = colIdx;
            break;
          }
        }
        if (mainRowIdx != null) break;
      }

      if (mainRowIdx != null && mainColIdx != null) {
        final range = TrinaCellMergeRange(
          startRowIdx: mainRowIdx,
          endRowIdx: mainRowIdx + cell.merge!.rowSpan - 1,
          startColIdx: mainColIdx,
          endColIdx: mainColIdx + cell.merge!.colSpan - 1,
        );

        return _unmergeCellsByRange(range);
      }
    } else {
      // For spanned cells, find the main cell and unmerge the entire range
      final mainCell = TrinaCellMergeUtils.getMainCell(
        cell,
        rows,
        columns,
      );

      if (mainCell != null) {
        return _unmergeCellByCell(mainCell);
      }
    }

    return false;
  }

  /// Gets all merged cell ranges in the grid
  List<TrinaCellMergeRange> getAllMergedRanges() {
    final List<TrinaCellMergeRange> ranges = [];
    final columns = stateManager.refColumns;
    final rows = stateManager.refRows;

    for (int rowIdx = 0; rowIdx < rows.length; rowIdx++) {
      for (int colIdx = 0; colIdx < columns.length; colIdx++) {
        final field = columns[colIdx].field;
        final cell = rows[rowIdx].cells[field];

        if (cell?.merge?.isMainCell == true) {
          final range = TrinaCellMergeRange(
            startRowIdx: rowIdx,
            endRowIdx: rowIdx + cell!.merge!.rowSpan - 1,
            startColIdx: colIdx,
            endColIdx: colIdx + cell.merge!.colSpan - 1,
          );
          ranges.add(range);
        }
      }
    }

    return ranges;
  }

  /// Checks if a cell is merged
  bool isCellMerged(TrinaCell cell) {
    return cell.merge != null;
  }

  /// Checks if a cell should be rendered (not a spanned cell)
  bool shouldRenderCell(TrinaCell cell) {
    return cell.merge?.shouldRender ?? true;
  }

  /// Gets the main cell for a spanned cell
  TrinaCell? getMainCell(TrinaCell spannedCell) {
    return TrinaCellMergeUtils.getMainCell(
      spannedCell,
      stateManager.refRows,
      stateManager.refColumns,
    );
  }

  /// Gets all spanned cells for a main cell
  List<TrinaCell> getSpannedCells(TrinaCell mainCell, int rowIdx, int colIdx) {
    return TrinaCellMergeUtils.getSpannedCells(
      mainCell,
      rowIdx,
      colIdx,
      stateManager.refRows,
      stateManager.refColumns,
    );
  }
}
