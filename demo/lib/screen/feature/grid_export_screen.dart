import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../widget/trina_example_button.dart';
import '../../widget/trina_example_screen.dart';
import '../../dummy_data/dummy_data.dart';

class GridExportScreen extends StatefulWidget {
  static const routeName = 'feature/grid-export';

  const GridExportScreen({super.key});

  @override
  State<GridExportScreen> createState() => _GridExportScreenState();
}

class _GridExportScreenState extends State<GridExportScreen> {
  late TrinaGridStateManager stateManager;

  final List<TrinaColumn> columns = [];
  final List<TrinaRow> rows = [];

  bool isExporting = false;
  String exportStatus = '';

  // Column selection and export options
  final Map<String, bool> selectedColumns = {};
  bool includeHeaders = true;
  bool ignoreFixedRows = false;
  String csvSeparator = ',';
  bool showColumnSelection = false;

  static const String formatCsv = 'csv';
  static const String formatJson = 'json';
  static const String formatPdf = 'pdf';

  @override
  void initState() {
    super.initState();

    // Initialize columns
    columns.addAll([
      TrinaColumn(
        title: 'ID',
        field: 'id',
        type: TrinaColumnTypeNumber(
          format: '#,###',
          negative: true,
          applyFormatOnInit: true,
          allowFirstDot: true,
          locale: 'en_US',
        ),
        width: 80,
      ),
      TrinaColumn(
        title: 'Name',
        field: 'name',
        type: const TrinaColumnTypeText(),
        width: 200,
      ),
      TrinaColumn(
        title: 'Age',
        field: 'age',
        type: TrinaColumnTypeNumber(
          format: '#,###',
          negative: false,
          applyFormatOnInit: true,
          allowFirstDot: true,
          locale: 'en_US',
        ),
        width: 80,
      ),
      TrinaColumn(
        title: 'Role',
        field: 'role',
        type: const TrinaColumnTypeText(),
        width: 150,
      ),
      TrinaColumn(
        title: 'Joined Date',
        field: 'joined_date',
        type: TrinaColumnTypeDate(
          format: 'yyyy-MM-dd',
          headerFormat: 'yyyy-MM-dd',
          applyFormatOnInit: true,
        ),
        width: 150,
      ),
      TrinaColumn(
        title: 'Salary',
        field: 'salary',
        type: TrinaColumnTypeCurrency(
          format: '\$#,###',
          negative: true,
          applyFormatOnInit: true,
          allowFirstDot: true,
          locale: 'en_US',
        ),
        width: 120,
      ),
      TrinaColumn(
        title: 'Active',
        field: 'active',
        type: TrinaColumnTypeBoolean(
          defaultValue: false,
          allowEmpty: false,
          trueText: 'Yes',
          falseText: 'No',
          onItemSelected: (value) {},
        ),
        width: 100,
      ),
    ]);

    // Initialize rows with dummy data
    rows.addAll(DummyData.generateEmployeeData(30));

    // Make the first 3 rows frozen to demonstrate ignoreFixedRows feature
    for (var i = 0; i < 3 && i < rows.length; i++) {
      // Create a new row with frozen property set to start (top)
      final cells = rows[i].cells;
      final newRow = TrinaRow(
        cells: cells,
        frozen: TrinaRowFrozen.start,
      );
      rows[i] = newRow;
    }

    // Initialize column selection (all selected by default)
    for (var column in columns) {
      selectedColumns[column.title] = true;
    }
  }

  void _showExportOptionsDialog(String formatName) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Export as $formatName'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Include headers option
                    Row(
                      children: [
                        Checkbox(
                          value: includeHeaders,
                          onChanged: (value) {
                            setDialogState(() {
                              includeHeaders = value ?? true;
                            });
                          },
                        ),
                        const Text('Include column headers'),
                      ],
                    ),

                    // Ignore fixed rows option
                    Row(
                      children: [
                        Checkbox(
                          value: ignoreFixedRows,
                          onChanged: (value) {
                            setDialogState(() {
                              ignoreFixedRows = value ?? false;
                            });
                          },
                        ),
                        const Text('Ignore frozen/fixed rows'),
                      ],
                    ),

                    // CSV specific options
                    if (formatName == formatCsv) ...[
                      const SizedBox(height: 8),
                      const Text('CSV Separator:'),
                      Row(
                        children: [
                          Radio<String>(
                            value: ',',
                            groupValue: csvSeparator,
                            onChanged: (value) {
                              setDialogState(() {
                                csvSeparator = value!;
                              });
                            },
                          ),
                          const Text('Comma (,)'),
                          const SizedBox(width: 10),
                          Radio<String>(
                            value: ';',
                            groupValue: csvSeparator,
                            onChanged: (value) {
                              setDialogState(() {
                                csvSeparator = value!;
                              });
                            },
                          ),
                          const Text('Semicolon (;)'),
                          const SizedBox(width: 10),
                          Radio<String>(
                            value: '\t',
                            groupValue: csvSeparator,
                            onChanged: (value) {
                              setDialogState(() {
                                csvSeparator = value!;
                              });
                            },
                          ),
                          const Text('Tab'),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Column selection
                    const Text('Select columns to export:'),
                    const SizedBox(height: 8),

                    // Select/Deselect all buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              for (var key in selectedColumns.keys) {
                                selectedColumns[key] = true;
                              }
                            });
                          },
                          child: const Text('Select All'),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              for (var key in selectedColumns.keys) {
                                selectedColumns[key] = false;
                              }
                            });
                          },
                          child: const Text('Deselect All'),
                        ),
                      ],
                    ),

                    // Column checkboxes
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView.builder(
                        itemCount: columns.length,
                        itemBuilder: (context, index) {
                          final column = columns[index];
                          return CheckboxListTile(
                            title: Text(column.title),
                            value: selectedColumns[column.title] ?? false,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedColumns[column.title] = value ?? false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Get selected columns
                    final List<String> columnsToExport = selectedColumns.entries
                        .where((entry) => entry.value)
                        .map((entry) => entry.key)
                        .toList();

                    // Close dialog
                    Navigator.of(context).pop();

                    // Export grid with selected columns
                    _exportGrid(formatName, selectedColumns: columnsToExport);
                  },
                  child: const Text('Export'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportGrid(String formatName,
      {List<String>? selectedColumns}) async {
    setState(() {
      isExporting = true;
      exportStatus = 'Exporting as $formatName...';
    });

    String fileName = 'grid_export_${DateTime.now().millisecondsSinceEpoch}';
    String saveFilePath = '';
    try {
      // For CSV, generate and download the file
      if (formatName == formatCsv) {
        final content = await TrinaGridExportCsv().export(
          stateManager: stateManager,
          columns: selectedColumns,
          includeHeaders: includeHeaders,
          ignoreFixedRows: ignoreFixedRows,
          separator: csvSeparator,
        );
        saveFilePath = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(content.codeUnits),
          ext: formatName,
          mimeType: MimeType.csv,
        );
      } else if (formatName == formatJson) {
        final content = await TrinaGridExportJson().export(
          stateManager: stateManager,
          columns: selectedColumns,
          includeHeaders: includeHeaders,
          ignoreFixedRows: ignoreFixedRows,
        );
        saveFilePath = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(content.codeUnits),
          ext: formatName,
          mimeType: MimeType.json,
        );
      } else if (formatName == formatPdf) {
        final content = await TrinaGridExportPdf().export(
          stateManager: stateManager,
          columns: selectedColumns,
          includeHeaders: includeHeaders,
          ignoreFixedRows: ignoreFixedRows,
        );
        saveFilePath = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: content,
          ext: formatName,
          mimeType: MimeType.pdf,
        );
      } else {
        throw Exception('Unsupported format: $formatName');
      }

      setState(() {
        exportStatus = 'Successfully exported as $formatName';
        isExporting = false;
      });

      if (!mounted) {
        return;
      }
      if (saveFilePath.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved to $saveFilePath'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        exportStatus = 'Export failed: $e';
        isExporting = false;
      });

      // Show error snackbar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TrinaExampleScreen(
      title: 'Grid Export',
      topTitle: 'Grid Export',
      topContents: const [
        Text('CSV Export with column selection and headers option'),
        SizedBox(height: 10),
        Text(
            'Export grid data as PDF, CSV, Excel, or JSON. You can export all visible columns or select specific columns to export.'),
      ],
      topButtons: [
        TrinaExampleButton(
          url:
              'https://github.com/doonfrs/trina_grid/blob/master/demo/lib/screen/feature/grid_export_screen.dart',
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildExportButton(
                  'Export as PDF',
                  FontAwesomeIcons.filePdf,
                  Colors.red,
                  () => _showExportOptionsDialog(formatPdf),
                ),
                const SizedBox(width: 16),
                _buildExportButton(
                  'Export as CSV',
                  FontAwesomeIcons.fileExcel,
                  Colors.green,
                  () => _showExportOptionsDialog(formatCsv),
                ),
                const SizedBox(width: 16),
                _buildExportButton(
                  'Export as JSON',
                  FontAwesomeIcons.fileCode,
                  Colors.blue,
                  () => _showExportOptionsDialog(formatJson),
                ),
              ],
            ),
          ),
          if (isExporting || exportStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isExporting)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (isExporting) const SizedBox(width: 10),
                  Text(
                    exportStatus,
                    style: TextStyle(
                      color: exportStatus.contains('failed')
                          ? Colors.red
                          : exportStatus.contains('Successfully')
                              ? Colors.green
                              : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Note: The first 3 rows are frozen (fixed at the top).',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const Text(
                  'Use the "Ignore frozen/fixed rows" option to exclude them from exports.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: TrinaGrid(
              columns: columns,
              rows: rows,
              onLoaded: (event) {
                stateManager = event.stateManager;
              },
              configuration: const TrinaGridConfiguration(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      icon: FaIcon(icon, size: 16, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: isExporting ? null : onPressed,
    );
  }
}
