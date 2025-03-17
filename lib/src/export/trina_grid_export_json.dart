import 'package:trina_grid/src/export/trina_grid_export.dart';
import 'package:trina_grid/src/manager/trina_grid_state_manager.dart';
import 'package:trina_grid/src/model/trina_column.dart';

/// Implementation of JSON export for Trina Grid
class TrinaGridExportJson implements TrinaGridExport {
  @override
  Future<dynamic> export({
    required TrinaGridStateManager stateManager,
    List<String>? columns,
  }) async {
    // Get columns to export
    final List<TrinaColumn> columnsToExport = _getColumnsToExport(
      stateManager: stateManager,
      columnNames: columns,
    );

    // This is a placeholder for the actual implementation
    return Future.value({
      'format': 'JSON',
      'columns': columnsToExport.map((col) => col.title).toList(),
      'rowCount': stateManager.refRows.length,
    });
  }

  /// Helper method to get the columns to export based on provided column names
  /// or visible columns if no column names are provided
  List<TrinaColumn> _getColumnsToExport({
    required TrinaGridStateManager stateManager,
    List<String>? columnNames,
  }) {
    if (columnNames == null || columnNames.isEmpty) {
      // If no columns specified, use all visible columns
      return stateManager.getVisibleColumns();
    } else {
      // Filter columns by the provided column names
      return stateManager.refColumns
          .where((column) => columnNames.contains(column.title))
          .toList();
    }
  }
}
