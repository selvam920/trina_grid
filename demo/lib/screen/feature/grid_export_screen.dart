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
  }

  Future<void> _exportGrid(TrinaGridExportFormat format,
      {List<String>? selectedColumns}) async {
    setState(() {
      isExporting = true;
      exportStatus = 'Exporting as ${format.name.toUpperCase()}...';
    });

    try {
      final result = await TrinaGridExportService.export(
        format: format,
        stateManager: stateManager,
        columns: selectedColumns,
      );

      // In a real app, you would save the result to a file or display it
      setState(() {
        exportStatus = 'Successfully exported as ${format.name.toUpperCase()}';
        isExporting = false;
      });

      // Show success snackbar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Successfully exported as ${format.name.toUpperCase()}'),
          backgroundColor: Colors.green,
        ),
      );

      // For demonstration purposes, print the result to console
      print('Export result: $result');
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
        Text('Coming soon...'),
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
                  () => _exportGrid(TrinaGridExportFormat.pdf),
                ),
                const SizedBox(width: 16),
                _buildExportButton(
                  'Export as CSV',
                  FontAwesomeIcons.fileExcel,
                  Colors.green,
                  () => _exportGrid(TrinaGridExportFormat.csv),
                ),
                const SizedBox(width: 16),
                _buildExportButton(
                  'Export as JSON',
                  FontAwesomeIcons.fileCode,
                  Colors.blue,
                  () => _exportGrid(TrinaGridExportFormat.json),
                ),
                const SizedBox(width: 16),
                _buildExportButton(
                  'Export as Excel',
                  FontAwesomeIcons.fileExcel,
                  Colors.blue,
                  () => _exportGrid(TrinaGridExportFormat.excel),
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
