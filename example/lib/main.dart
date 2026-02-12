import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trina_grid/trina_grid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrinaGrid Invoice Entry',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TrinaGridExamplePage(),
    );
  }
}

class Product {
  final int id;
  final String name;

  const Product({required this.id, required this.name});

  @override
  String toString() => name;
}

class Unit {
  final int id;
  final String name;

  const Unit({required this.id, required this.name});

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Unit && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// TrinaGrid Example — Invoice items entry grid with autocomplete and calculations.
class TrinaGridExamplePage extends StatefulWidget {
  const TrinaGridExamplePage({super.key});

  @override
  State<TrinaGridExamplePage> createState() => _TrinaGridExamplePageState();
}

class _TrinaGridExamplePageState extends State<TrinaGridExamplePage> {
  bool _restoreOnCancel = true;

  // --- Simulated data source for invoice products ---
  static const _products = [
    Product(id: 1, name: 'Apple iPhone 15'),
    Product(id: 2, name: 'Samsung Galaxy S23'),
    Product(id: 3, name: 'Sony WH-1000XM5'),
    Product(id: 4, name: 'MacBook Air M2'),
    Product(id: 5, name: 'Dell XPS 13'),
    Product(id: 6, name: 'Logitech MX Master 3S'),
    Product(id: 7, name: 'Kindle Paperwhite'),
    Product(id: 8, name: 'Nikon Z6 II'),
    Product(id: 9, name: 'GoPro Hero 12'),
    Product(id: 10, name: 'iPad Pro 11"'),
    Product(id: 11, name: 'Office Desk'),
    Product(id: 12, name: 'Ergonomic Chair'),
    Product(id: 13, name: 'LED Monitor 27"'),
    Product(id: 14, name: 'Mechanical Keyboard'),
    Product(id: 15, name: 'USB-C Hub'),
    Product(id: 16, name: 'External SSD 1TB'),
    Product(id: 17, name: 'Wireless Router'),
    Product(id: 18, name: 'Webcam 4K'),
    Product(id: 19, name: 'Standing Desk'),
    Product(id: 20, name: 'A4 Paper Bundle'),
    Product(id: 21, name: 'Printer Ink Black'),
    Product(id: 22, name: 'Laptop Stand'),
    Product(id: 23, name: 'Coffee Beans 1kg'),
    Product(id: 24, name: 'Organic Milk'),
    Product(id: 25, name: 'Green Tea Pack'),
    Product(id: 26, name: 'Electric Kettle'),
    Product(id: 27, name: 'Bread Toaster'),
    Product(id: 28, name: 'Smart Watch v2'),
  ];

  List<Unit> _getUnitsForProduct(Product? product) {
    if (product == null) {
      return [
        const Unit(id: 100, name: 'Pcs'),
        const Unit(id: 101, name: 'Unit'),
      ];
    }
    final name = product.name;
    if (name.contains('Paper') || name.contains('Ink') || name.contains('Tea')) {
      return [
        const Unit(id: 200, name: 'Bundle'),
        const Unit(id: 201, name: 'Pack'),
        const Unit(id: 202, name: 'Box'),
        const Unit(id: 203, name: 'Carton'),
      ];
    }
    if (name.contains('Desk') ||
        name.contains('Chair') ||
        name.contains('Kettle')) {
      return [
        const Unit(id: 300, name: 'Set'),
        const Unit(id: 101, name: 'Unit'),
        const Unit(id: 100, name: 'Pcs'),
      ];
    }
    if (name.contains('Milk') || name.contains('Beans')) {
      return [
        const Unit(id: 400, name: 'Kg'),
        const Unit(id: 401, name: 'Ltr'),
        const Unit(id: 402, name: 'Gram'),
        const Unit(id: 403, name: 'Bottle'),
      ];
    }
    return [
     
    ];
  }

  late final List<TrinaColumn> columns = <TrinaColumn>[
    /// Product Name with Autocomplete
    TrinaColumn(
      title: 'Product Name',
      field: 'product_name',
      type: TrinaColumnType.autoComplete<Product>(
        fetchItems: (query) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return _products
              .where(
                (p) => p.name.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
        },
        displayStringForOption: (item) => item.name,
      ),
      width: 250,
    ),

    /// MRP
    TrinaColumn(
      title: 'MRP',
      field: 'mrp',
      type: TrinaColumnType.currency(symbol: '₹', decimalDigits: 2),
      width: 120,
      textAlign: TrinaColumnTextAlign.right,
    ),

    /// Rate
    TrinaColumn(
      title: 'Rate',
      field: 'rate',
      type: TrinaColumnType.currency(symbol: '₹', decimalDigits: 2),
      width: 120,
      textAlign: TrinaColumnTextAlign.right,
    ),

    /// Quantity
    TrinaColumn(
      title: 'Qty',
      field: 'qty',
      type: TrinaColumnType.number(format: '#,###.##'),
      width: 100,
      textAlign: TrinaColumnTextAlign.center,
    ),

    /// Unit
    TrinaColumn(
      title: 'Unit',
      field: 'unit',
      type: TrinaColumnType.dropdown<Unit>(
        items: <Unit>[],
        itemsProvider: (row, cell) {
          final product = row.cells['product_name']?.value;
          return _getUnitsForProduct(product is Product ? product : null);
        },
        displayStringForOption: (unit) => unit.name,
        autoOpen: true,
      ),
      width: 100,
    ),

    /// Amount (Calculated)
    TrinaColumn(
      title: 'Amount',
      field: 'amount',
      type: TrinaColumnType.currency(symbol: '₹', decimalDigits: 2),
      width: 150,
      readOnly: true,
      textAlign: TrinaColumnTextAlign.right,
      footerRenderer: (rendererContext) {
        return TrinaAggregateColumnFooter(
          rendererContext: rendererContext,
          type: TrinaAggregateColumnType.sum,
          alignment: Alignment.centerRight,
          numberFormat: NumberFormat.currency(
            symbol: '₹',
            decimalDigits: 2,
          ),
          titleSpanBuilder: (text) {
            return [
              const TextSpan(
                text: 'Grand Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' : '),
              TextSpan(text: text),
            ];
          },
        );
      },
    ),
  ];

  late final List<TrinaRow> rows = List.generate(
    100,
    (index) {
      final product = _products[index % _products.length];
      final mrp = 500.0 + (index * 100);
      final rate = 450.0 + (index * 90);
      final qty = (index % 5) + 1.0;
      final units = _getUnitsForProduct(product);

      return TrinaRow(
        cells: {
          'product_name': TrinaCell(value: product),
          'mrp': TrinaCell(value: mrp),
          'rate': TrinaCell(value: rate),
          'qty': TrinaCell(value: qty),
          'unit': TrinaCell(value: units.isNotEmpty ? units.first : ''),
          'amount': TrinaCell(value: rate * qty),
        },
      );
    },
  );

  /// Column groups for invoice layout.
  final List<TrinaColumnGroup> columnGroups = [
    TrinaColumnGroup(
      title: 'Product Details',
      fields: ['product_name', 'unit'],
    ),
    TrinaColumnGroup(
      title: 'Pricing & Qty',
      fields: ['mrp', 'rate', 'qty'],
    ),
    TrinaColumnGroup(title: 'Totals', fields: ['amount']),
  ];

  late final TrinaGridStateManager stateManager;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrinaGrid — Invoice Items Entry'),
        actions: [
          Row(
            children: [
              const Text('Restore on Cancel'),
              Switch(
                value: _restoreOnCancel,
                onChanged: (val) {
                  setState(() {
                    _restoreOnCancel = val;
                  });
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Toggle column filters',
            onPressed: () {
              stateManager.setShowColumnFilter(!stateManager.showColumnFilter);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: TrinaGrid(
          columns: columns,
          rows: rows,
          columnGroups: columnGroups,
          onLoaded: (TrinaGridOnLoadedEvent event) {
            stateManager = event.stateManager;
            stateManager.setShowColumnFilter(true);
          },
          onChanged: (TrinaGridOnChangedEvent event) {
            debugPrint(
              'Field: ${event.column.field} | Value: ${event.value} (${event.value.runtimeType}) | Old: ${event.oldValue}',
            );

            // You can get the typed objects directly:
            if (event.column.field == 'unit') {
              final unit = event.value is Unit ? event.value as Unit : null;
              if (unit != null) {
                debugPrint('Selected Unit Object: ID=${unit.id}, Name=${unit.name}');
              }
            }

            // When product changes, reset unit if current one is invalid
            if (event.column.field == 'product_name') {
              final unitCell = event.row.cells['unit'];
              if (unitCell != null) {
                final product = event.value is Product ? event.value as Product : null;
                final validUnits = _getUnitsForProduct(product);
                if (!validUnits.contains(unitCell.value)) {
                  debugPrint('Product changed: updating unit cell to default.');
                  stateManager.changeCellValue(
                    unitCell,
                    validUnits.isNotEmpty ? validUnits.first : null,
                    notify: true,
                  );
                }
              }
            }

            // When rate or qty changes, update the amount cell
            if (event.column.field == 'rate' || event.column.field == 'qty') {
              final rate = event.row.cells['rate']?.value ?? 0.0;
              final qty = event.row.cells['qty']?.value ?? 0.0;
              final amountCell = event.row.cells['amount'];

              if (amountCell != null) {
                debugPrint('Updating amount: $rate * $qty');
                stateManager.changeCellValue(
                  amountCell,
                  rate * qty,
                  notify: true,
                );
              }
            }
          },
          configuration: TrinaGridConfiguration(
            // Rollback text if editing is canceled
            enableRestoreValueOnCancel: _restoreOnCancel,
            // Move right after selecting from dropdown/autocomplete
            enableMoveRightAfterSelecting: true,
            // Desktop-focused: Enter edits then moves right (Excel-like)
            enterKeyAction: TrinaGridEnterKeyAction.editingAndMoveRight,
            // Tab moves to next cell on edge (Excel-like)
            tabKeyAction: TrinaGridTabKeyAction.moveToNextOnEdge,
            // Enable cell selection mode
            selectingMode: TrinaGridSelectingMode.cell,
            // Desktop scrollbar with drag support
            scrollbar: const TrinaGridScrollbarConfig(isAlwaysShown: true),
            style: const TrinaGridStyleConfig(
              enableRowColorAnimation: true,
              enableRowHoverColor: true,
            ),
          ),
        ),
      ),
    );
  }
}
