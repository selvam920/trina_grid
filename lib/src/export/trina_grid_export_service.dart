import 'package:trina_grid/src/export/trina_grid_export.dart';
import 'package:trina_grid/src/export/trina_grid_export_excel.dart';
import 'package:trina_grid/src/export/trina_grid_export_pdf.dart';
import 'package:trina_grid/src/export/trina_grid_export_csv.dart';
import 'package:trina_grid/src/export/trina_grid_export_json.dart';
import 'package:trina_grid/src/manager/trina_grid_state_manager.dart';

/// Export format types supported by the Trina Grid export service
enum TrinaGridExportFormat {
  /// PDF export format
  pdf,

  /// CSV export format
  csv,

  /// JSON export format
  json,

  /// Excel export format
  excel,
}

/// Service for exporting Trina Grid data in various formats
class TrinaGridExportService {
  /// Creates an export service for the specified format
  ///
  /// [format] - The export format to use
  static TrinaGridExport createExporter(TrinaGridExportFormat format) {
    switch (format) {
      case TrinaGridExportFormat.pdf:
        return TrinaGridExportPdf();
      case TrinaGridExportFormat.csv:
        return TrinaGridExportCsv();
      case TrinaGridExportFormat.json:
        return TrinaGridExportJson();
      case TrinaGridExportFormat.excel:
        return TrinaGridExportExcel();
    }
  }

  /// Exports grid data in the specified format
  ///
  /// [format] - The export format to use
  /// [stateManager] - The grid state manager containing grid data
  /// [columns] - Optional list of column names to export. If null, all visible columns will be exported
  static Future<dynamic> export({
    required TrinaGridExportFormat format,
    required TrinaGridStateManager stateManager,
    List<String>? columns,
  }) {
    final exporter = createExporter(format);
    return exporter.export(stateManager: stateManager, columns: columns);
  }
}
