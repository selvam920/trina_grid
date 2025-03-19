import 'dart:typed_data';

import 'package:trina_grid/src/export/trina_grid_export.dart';
import 'package:trina_grid/src/manager/trina_grid_state_manager.dart';
import 'package:trina_grid/src/model/trina_column.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:trina_grid/src/model/trina_row.dart';

/// Implementation of PDF export for Trina Grid
class TrinaGridExportPdf implements TrinaGridExport {
  @override
  Future<Uint8List> export({
    required TrinaGridStateManager stateManager,
    List<String>? columns,
    bool includeHeaders = true,
    String? title,
    String? creator,
    String? format,
  }) async {
    final doc = pw.Document(creator: creator, title: title);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.portrait,
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        mainAxisAlignment: pw.MainAxisAlignment.start,
        header: title != null ? (context) => _getHeader(title: title) : null,
        footer: (context) => _getFooter(context),
        build:
            (pw.Context context) =>
                _exportInternal(context, stateManager, columns),
      ),
    );
    return await doc.save();
  }

  List<pw.Widget> _exportInternal(
    pw.Context context,
    TrinaGridStateManager stateManager,
    List<String>? columns,
  ) {
    final columnsToExport = _getColumnsToExport(
      stateManager: stateManager,
      columnNames: columns,
    );
    final rows = stateManager.refRows;
    return [_table(columnsToExport, rows)];
  }

  /// Helper method to get the columns to export based on provided column names
  /// or visible columns if no column names are provided
  List<TrinaColumn> _getColumnsToExport({
    required TrinaGridStateManager stateManager,
    List<String>? columnNames,
  }) {
    if (columnNames == null || columnNames.isEmpty) {
      // If no columns specified, use all visible columns
      return stateManager.columns;
    } else {
      // Filter columns by the provided column names
      return stateManager.refColumns
          .where((column) => columnNames.contains(column.title))
          .toList();
    }
  }

  pw.Widget _getHeader({required String title}) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              title,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _table(List<TrinaColumn> columns, List<TrinaRow> rows) {
    return pw.TableHelper.fromTextArray(
      border: null,
      cellAlignment: pw.Alignment.center,
      headerCellDecoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0x000000), width: 0.5),
      ),
      headerDecoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0x000000), width: 0.5),
      ),
      headerHeight: 25,
      cellHeight: 20,
      headerAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.all(1),
      cellDecoration:
          (index, data, rowNum) => pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromInt(0x000000), width: .5),
          ),
      headers: columns.map((column) => column.title).toList(),
      data:
          rows
              .map(
                (row) =>
                    row.cells.entries
                        .map((entry) => entry.value.value)
                        .toList(),
              )
              .toList(),
    );
  }

  pw.Widget _getFooter(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.max,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('# ${context.pageNumber}/${context.pagesCount}'),
          pw.Text(DateTime.now().toString()),
        ],
      ),
    );
  }
}
