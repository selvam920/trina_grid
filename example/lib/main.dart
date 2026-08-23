import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
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
  final FocusNode _navFocusNode = FocusNode();
  final TextEditingController _rowIdxController = TextEditingController(text: '0');
  TrinaGridStateManager? stateManager;

  @override
  void dispose() {
    _navFocusNode.dispose();
    _rowIdxController.dispose();
    super.dispose();
  }

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
    if (name.contains('Paper') ||
        name.contains('Ink') ||
        name.contains('Tea')) {
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
    return [];
  }

  late final List<TrinaColumn> columns = <TrinaColumn>[
    /// Checkbox Column
    TrinaColumn(
      title: '',
      field: 'checked',
      type: TrinaColumnType.text(),
      width: 50,
      enableRowChecked: true,
      enableSorting: false,
      enableFilterMenuItem: false,
      enableColumnDrag: false,
    ),

    /// SNo. — uses renderer with isCurrentRow to change text color
    TrinaColumn(
      title: 'SNo.',
      field: 'sno',
      type: TrinaColumnType.text(),
      width: 60,
      readOnly: true,
      enableEditingMode: false,
      renderer: (rendererContext) {
        return Text(
          '${rendererContext.rowIdx + 1}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: rendererContext.isCurrentRow ? Colors.white : Colors.black,
            fontWeight: rendererContext.isCurrentRow
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        );
      },
    ),

    /// Product Name with Autocomplete
    TrinaColumn(
      title: 'Product Name',
      field: 'product_name',
      type: TrinaColumnType.autoComplete<Product>(
        fetchItems: (query) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return _products
              .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
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
          numberFormat: NumberFormat.currency(symbol: '₹', decimalDigits: 2),
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

    /// Actions Column (to test multiple icons color change)
    TrinaColumn(
      title: 'Actions',
      field: 'actions',
      type: TrinaColumnType.text(),
      width: 140,
      enableSorting: false,
      enableFilterMenuItem: false,
      enableColumnDrag: false,
      renderer: (rendererContext) {
        final color =
            rendererContext.isCurrentRow ? Colors.white : Colors.black;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.share, size: 18, color: color),
            Icon(Icons.edit, size: 18, color: color),
            Icon(Icons.delete, size: 18, color: color),
            Icon(Icons.more_vert, size: 18, color: color),
          ],
        );
      },
    ),
  ];

  late final List<TrinaRow> rows = List.generate(100, (index) {
    final product = _products[index % _products.length];
    final mrp = 500.0 + (index * 100);
    final rate = 450.0 + (index * 90);
    final qty = (index % 5) + 1.0;
    final units = _getUnitsForProduct(product);

    return TrinaRow(
      cells: {
        'checked': TrinaCell(value: ''),
        'sno': TrinaCell(value: '${index + 1}'),
        'product_name': TrinaCell(value: product),
        'mrp': TrinaCell(value: mrp),
        'rate': TrinaCell(value: rate),
        'qty': TrinaCell(value: qty),
        'unit': TrinaCell(value: units.isNotEmpty ? units.first : ''),
        'amount': TrinaCell(value: rate * qty),
        'actions': TrinaCell(value: ''),
      },
    );
  });

  /// Column groups for invoice layout.
  final List<TrinaColumnGroup> columnGroups = [
    TrinaColumnGroup(
      title: 'Product Details',
      fields: ['checked', 'sno', 'product_name', 'unit'],
    ),
    TrinaColumnGroup(title: 'Pricing & Qty', fields: ['mrp', 'rate', 'qty']),
    TrinaColumnGroup(title: 'Totals', fields: ['amount', 'actions']),
  ];

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
            icon: const Icon(Icons.touch_app),
            tooltip: 'Select random row',
            onPressed: () {
              if (stateManager == null) return;
              final random = math.Random();
              final nextRow = random.nextInt(stateManager!.refRows.length);
              stateManager!.selectRow(nextRow);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Toggle column filters',
            onPressed: () {
              if (stateManager == null) return;
              stateManager!.setShowColumnFilter(
                !stateManager!.showColumnFilter,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: KeyboardListener(
                      focusNode: _navFocusNode,
                      onKeyEvent: (event) {
                        if (stateManager == null) return;
                        if (event is KeyDownEvent || event is KeyRepeatEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            final currentIdx = stateManager!.currentRowIdx ?? -1;
                            if (currentIdx < stateManager!.refRows.length - 1) {
                              final nextRow = currentIdx + 1;
                              stateManager!.selectRow(nextRow);
                              _rowIdxController.text = nextRow.toString();
                            }
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            final currentIdx = stateManager!.currentRowIdx ?? 0;
                            if (currentIdx > 0) {
                              final prevRow = currentIdx - 1;
                              stateManager!.selectRow(prevRow);
                              _rowIdxController.text = prevRow.toString();
                            }
                          }
                        }
                      },
                      child: TextField(
                        controller: _rowIdxController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onSubmitted: (value) {
                          if (stateManager == null) return;
                          final idx = int.tryParse(value);
                          if (idx != null &&
                              idx >= 0 &&
                              idx < stateManager!.refRows.length) {
                            stateManager!.selectRow(idx);
                          } else {
                            _rowIdxController.text = (stateManager!.currentRowIdx ?? 0).toString();
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Row Index Navigation',
                          hintText: 'Enter row index and press Enter',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (stateManager == null) return;
                          final currentIdx = stateManager!.currentRowIdx ?? -1;
                          if (currentIdx < stateManager!.refRows.length - 1) {
                            final nextRow = currentIdx + 1;
                            stateManager!.selectRow(nextRow);
                            _rowIdxController.text = nextRow.toString();
                          }
                        },
                        icon: const Icon(Icons.arrow_drop_up),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        onPressed: () {
                          if (stateManager == null) return;
                          final currentIdx = stateManager!.currentRowIdx ?? 0;
                          if (currentIdx > 0) {
                            final prevRow = currentIdx - 1;
                            stateManager!.selectRow(prevRow);
                            _rowIdxController.text = prevRow.toString();
                          }
                        },
                        icon: const Icon(Icons.arrow_drop_down),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: OverflowBar(
                alignment: MainAxisAlignment.start,
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (stateManager == null) return;

                      final product =
                          _products[math.Random().nextInt(_products.length)];
                      final rate = 100.0 + math.Random().nextInt(900);
                      final qty = (math.Random().nextInt(5) + 1).toDouble();
                      final units = _getUnitsForProduct(product);

                      final newRow = TrinaRow(
                        cells: {
                          'checked': TrinaCell(value: ''),
                          'sno': TrinaCell(value: ''),
                          'product_name': TrinaCell(value: product),
                          'mrp': TrinaCell(value: rate + 50),
                          'rate': TrinaCell(value: rate),
                          'qty': TrinaCell(value: qty),
                          'unit': TrinaCell(
                            value: units.isNotEmpty ? units.first : '',
                          ),
                          'amount': TrinaCell(value: rate * qty),
                          'actions': TrinaCell(value: ''),
                        },
                      );

                      stateManager!.addRow(0, newRow);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Row at 0'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (stateManager == null ||
                          stateManager!.currentRowIdx == null) {
                        return;
                      }

                      final product =
                          _products[math.Random().nextInt(_products.length)];
                      final rate = 2000.0 + math.Random().nextInt(1000);
                      final qty = 1.0;
                      final units = _getUnitsForProduct(product);

                      final updatedRow = TrinaRow(
                        cells: {
                          'checked': TrinaCell(value: ''),
                          'sno': TrinaCell(value: ''),
                          'product_name': TrinaCell(value: product),
                          'mrp': TrinaCell(value: rate + 100),
                          'rate': TrinaCell(value: rate),
                          'qty': TrinaCell(value: qty),
                          'unit': TrinaCell(
                            value: units.isNotEmpty ? units.first : '',
                          ),
                          'amount': TrinaCell(value: rate * qty),
                          'actions': TrinaCell(value: ''),
                        },
                      );

                      stateManager!.updateRow(
                        stateManager!.currentRowIdx!,
                        updatedRow,
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Update Current Row'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (stateManager == null ||
                          stateManager!.currentRowIdx == null) {
                        return;
                      }
                      stateManager!.deleteRow(stateManager!.currentRowIdx!);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete Current Row'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TrinaGrid(
                columns: columns,
                rows: rows,
                onLoaded: (TrinaGridOnLoadedEvent event) {
                  stateManager = event.stateManager;
                  stateManager!.setShowColumnFilter(true);

                  if (stateManager!.refRows.isNotEmpty) {
                    stateManager!.selectRow(0);
                  }

                  // Update row navigation field when selection changes
                  stateManager!.addListener(() {
                    if (stateManager == null) return;
                    final rowIdx = stateManager!.currentRowIdx;
                    if (rowIdx != null &&
                        _rowIdxController.text != rowIdx.toString()) {
                      _rowIdxController.text = rowIdx.toString();
                    }
                  });
                },
                  onReachedEnd: (TrinaGridOnReachedEndEvent event) async {
                    debugPrint(
                      '--- FORMAL EVENT: Reached end of the grid (Offset: ${event.offset.toStringAsFixed(1)}) ---',
                    );

                    if (stateManager?.showLoading == true) return;

                    stateManager!.setShowLoading(
                    true,
                    level: TrinaGridLoadingLevel.rowsBottomCircular,
                  );

                  // Simulate a server fetch delay
                  await Future.delayed(const Duration(seconds: 1));

                  final startIdx = stateManager!.refRows.length;
                  final List<TrinaRow> nextRows = List.generate(20, (index) {
                    final currentIdx = startIdx + index;
                    final product =
                        _products[currentIdx % _products.length];
                    final mrp = 500.0 + (currentIdx * 100);
                    final rate = 450.0 + (currentIdx * 90);
                    final qty = (currentIdx % 5) + 1.0;
                    final units = _getUnitsForProduct(product);

                    return TrinaRow(
                      cells: {
                        'checked': TrinaCell(value: ''),
                        'sno': TrinaCell(value: '${currentIdx + 1}'),
                        'product_name': TrinaCell(value: product),
                        'mrp': TrinaCell(value: mrp),
                        'rate': TrinaCell(value: rate),
                        'qty': TrinaCell(value: qty),
                        'unit': TrinaCell(
                          value: units.isNotEmpty ? units.first : '',
                        ),
                        'amount': TrinaCell(value: rate * qty),
                        'actions': TrinaCell(value: ''),
                      },
                    );
                  });

                  stateManager!.appendRows(nextRows);
                  stateManager!.setShowLoading(false);
                },
                onRowSelected: (TrinaGridOnRowSelectedEvent event) {
                  debugPrint(
                    'onRowSelected: rowIdx=${event.rowIdx}, rowKey=${event.row.key}, cellKey=${event.cell?.key}',
                  );
                },
                onSelected: (TrinaGridOnSelectedEvent event) {
                  debugPrint(
                    'onSelected: rowIdx=${event.rowIdx}, rowKey=${event.row?.key}, cellKey=${event.cell?.key}, selectedRows=${event.selectedRows?.length ?? 0}',
                  );
                },
                onRowChecked: (event) {
                  debugPrint(
                    'Row Checked: ${event.isChecked} | Is All: ${event.isAll}',
                  );
                },
                onChanged: (TrinaGridOnChangedEvent event) {
                  debugPrint(
                    'Field: ${event.column.field} | Value: ${event.value} (${event.value.runtimeType}) | Old: ${event.oldValue}',
                  );

                  // You can get the typed objects directly:
                  if (event.column.field == 'unit') {
                    final unit = event.value is Unit
                        ? event.value as Unit
                        : null;
                    if (unit != null) {
                      debugPrint(
                        'Selected Unit Object: ID=${unit.id}, Name=${unit.name}',
                      );
                    }
                  }

                  // When product changes, reset unit if current one is invalid
                  if (event.column.field == 'product_name') {
                    final unitCell = event.row.cells['unit'];
                    if (unitCell != null) {
                      final product = event.value is Product
                          ? event.value as Product
                          : null;
                      final validUnits = _getUnitsForProduct(product);
                      if (!validUnits.contains(unitCell.value)) {
                        debugPrint(
                          'Product changed: updating unit cell to default.',
                        );
                        stateManager!.changeCellValue(
                          unitCell,
                          validUnits.isNotEmpty ? validUnits.first : null,
                          notify: true,
                        );
                      }
                    }
                  }

                  // When rate or qty changes, update the amount cell
                  if (event.column.field == 'rate' ||
                      event.column.field == 'qty') {
                    final rate = event.row.cells['rate']?.value ?? 0.0;
                    final qty = event.row.cells['qty']?.value ?? 0.0;
                    final amountCell = event.row.cells['amount'];

                    if (amountCell != null) {
                      debugPrint('Updating amount: $rate * $qty');
                      stateManager!.changeCellValue(
                        amountCell,
                        rate * qty,
                        notify: true,
                      );
                    }
                  }
                },
                configuration: TrinaGridConfiguration(
                  columnSize: const TrinaGridColumnSizeConfig(
                    autoSizeMode: TrinaAutoSizeMode.scale,
                  ),
                  // Rollback text if editing is canceled
                  enableRestoreValueOnCancel: _restoreOnCancel,
                  // Desktop-focused: Enter edits then moves right (Excel-like)
                  enterKeyAction: TrinaGridEnterKeyAction.editingAndMoveRight,
                  // Tab moves to next cell on edge (Excel-like)
                  tabKeyAction: TrinaGridTabKeyAction.moveToNextOnEdge,
                  // Enable cell selection mode
                  selectingMode: TrinaGridSelectingMode.cell,
                  // Desktop scrollbar with drag support
                  scrollbar: const TrinaGridScrollbarConfig(
                    isAlwaysShown: true,
                  ),
                  style: const TrinaGridStyleConfig(
                    enableRowColorAnimation: true,
                    enableRowHoverColor: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
