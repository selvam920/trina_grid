import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:trina_grid/src/export/trina_grid_export.dart';
import 'package:trina_grid/src/manager/trina_grid_state_manager.dart';
import 'package:trina_grid/src/model/trina_column.dart';
import 'package:trina_grid/src/model/trina_row.dart';

/// Implementation of [TrinaGridExport] for PDF format
class TrinaGridExportPdf implements TrinaGridExport {
  @override
  Future<String> export({
    required TrinaGridStateManager stateManager,
    List<String>? columns,
  }) async {
    try {
      // Get visible columns if no specific columns are requested
      final List<TrinaColumn> visibleColumns = columns != null
          ? stateManager.refColumns
              .where((column) => columns.contains(column.title))
              .toList()
          : stateManager.getVisibleColumns();
      
      if (visibleColumns.isEmpty) {
        throw Exception('No columns to export');
      }
      
      // Get rows
      final List<TrinaRow> rows = stateManager.refRows;
      
      // In a real implementation, this would generate a PDF file
      // For demo purposes, we'll create a simple representation
      final Map<String, dynamic> pdfData = {
        'format': 'PDF',
        'columns': visibleColumns.map((column) => column.title).toList(),
        'data': rows.map((row) {
          final Map<String, dynamic> rowData = {};
          for (final column in visibleColumns) {
            final cell = row.cells[column.field];
            rowData[column.title] = cell?.value?.toString() ?? '';
          }
          return rowData;
        }).toList(),
      };
      
      // Return a JSON string representation of the PDF data
      // In a real implementation, this would be the PDF file content
      return jsonEncode(pdfData);
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting to PDF: $e');
      }
      rethrow;
    }
  }
}
