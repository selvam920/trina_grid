# Trina Grid Export Services

Trina Grid provides multiple export options to convert grid data into different formats for download, sharing, or further processing.

![Export Demo](https://raw.githubusercontent.com/doonfrs/trina_grid/master/doc/assets/export.gif)

## Available Export Formats

Currently, Trina Grid supports the following export formats:

- **CSV** - For tabular data export to spreadsheet applications
- **JSON** - For structured data export and API consumption
- **PDF** - For printable documents with formatting

## Using Export Services

All export services implement the `TrinaGridExport` interface, providing a consistent API:

```dart
Future<dynamic> export({
  required TrinaGridStateManager stateManager,
  List<String>? columns,
  bool includeHeaders = true,
  bool ignoreFixedRows = false,
  // Additional format-specific options may be available
});
```

### Common Parameters

- **stateManager**: Required. The grid's state manager containing data to be exported
- **columns**: Optional. List of specific column titles to include (if null, exports all visible columns)
- **includeHeaders**: Optional. Whether to include column headers in the export (default: true)
- **ignoreFixedRows**: Optional. Whether to exclude frozen/fixed rows from the export (default: false)

## CSV Export

`TrinaGridExportCsv` exports grid data to comma-separated values format.

```dart
final csvExport = TrinaGridExportCsv();
final String csvData = await csvExport.export(
  stateManager: gridStateManager,
  columns: ['Column A', 'Column B'], // Optional
  includeHeaders: true, // Optional
  ignoreFixedRows: false, // Optional
  separator: ',', // Optional - Can be changed to ';', '\t', etc.
);
```

The CSV export:

- Properly escapes fields containing commas, quotes, or newlines
- Returns a String containing the CSV data
- Can optionally exclude frozen rows from export
- Supports custom separators (default is comma, but can be semicolon, tab, etc.)

## JSON Export

`TrinaGridExportJson` exports grid data to JSON format.

```dart
final jsonExport = TrinaGridExportJson();
final String jsonData = await jsonExport.export(
  stateManager: gridStateManager,
  columns: ['Column A', 'Column B'], // Optional
  includeHeaders: true, // Optional
  ignoreFixedRows: false, // Optional
);
```

The JSON export:

- Returns data as a string containing a JSON array
- Each row is represented as a JSON object with field names as keys
- If `includeHeaders` is true, the first object contains header information
- Can optionally exclude frozen rows from export

## PDF Export

`TrinaGridExportPdf` exports grid data to PDF format for printing or sharing.

```dart
final pdfExport = TrinaGridExportPdf();
final Uint8List pdfData = await pdfExport.export(
  stateManager: gridStateManager,
  columns: ['Column A', 'Column B'], // Optional
  includeHeaders: true, // Optional
  ignoreFixedRows: false, // Optional
  title: 'Grid Export', // Optional
  creator: 'Application Name', // Optional
  format: 'a4', // Optional
);
```

The PDF export:

- Returns a `Uint8List` containing the binary PDF data
- Supports additional PDF-specific parameters:
  - **title**: Optional. Title displayed in the PDF header
  - **creator**: Optional. Creator metadata in the PDF
  - **format**: Optional. Page format (defaults to A4 portrait)
- Includes styled headers and footers with page numbers and timestamps
- Can optionally exclude frozen rows from export

## Example Usage

```dart
// Get the state manager from your grid
final stateManager = myGrid.stateManager;

// Export to CSV
final csvExport = TrinaGridExportCsv();
final String csvData = await csvExport.export(
  stateManager: stateManager,
  ignoreFixedRows: true, // Exclude frozen rows
);

// Export to JSON
final jsonExport = TrinaGridExportJson();
final String jsonData = await jsonExport.export(
  stateManager: stateManager,
  ignoreFixedRows: true, // Exclude frozen rows
);

// Export to PDF
final pdfExport = TrinaGridExportPdf();
final Uint8List pdfData = await pdfExport.export(
  stateManager: stateManager,
  title: 'My Grid Export',
  ignoreFixedRows: true, // Exclude frozen rows
);
```

## Saving Exported Files

For mobile and desktop applications, use the `file_saver` package to save exported files:

```dart
import 'package:file_saver/file_saver.dart';

// Save PDF file
String? saveFilePath = await FileSaver.instance.saveFile(
  name: 'grid-export',
  bytes: pdfData, // Uint8List from PDF export
  ext: 'pdf',
  mimeType: MimeType.pdf,
);

// Save CSV file or JSON file
await FileSaver.instance.saveFile(
  name: 'grid-export',
  bytes: Uint8List.fromList(csvData.codeUnits), // Convert String to Uint8List
  ext: 'csv',
  mimeType: MimeType.csv,
);

```
