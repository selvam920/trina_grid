import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trina_grid/trina_grid.dart';

typedef TrinaAutoCompleteFetchItems<T> = Future<List<T>> Function(String input);
typedef TrinaAutoCompleteItemBuilder<T> =
    Widget Function(BuildContext context, T item, bool selected);

typedef TrinaAutocompleteOptionToString<T> = String Function(T option);

class TrinaAutoCompleteCell<T> extends StatefulWidget {
  /// Function to get display string for an option.
  final TrinaAutocompleteOptionToString<T>? displayStringForOption;

  final TrinaGridStateManager stateManager;

  final TrinaCell cell;

  final TrinaColumn column;

  final TrinaRow row;

  /// The function to fetch items based on input.
  final TrinaAutoCompleteFetchItems<T> fetchItems;

  /// The width of the menu.
  final double width;

  /// The initially selected value, which will be highlighted in the list.
  final T? initialValue;

  /// Called when an item is selected from the list.
  final void Function(T) onItemSelected;

  /// A builder function to create a custom widget for each item in the list.
  /// If null, a default [Text] widget is used.
  final TrinaAutoCompleteItemBuilder<T> itemBuilder;

  /// The height of each item in the list.
  final double itemHeight;

  /// The maximum height of the popup menu's scrollable area.
  final double maxHeight;

  const TrinaAutoCompleteCell({
    required this.stateManager,
    required this.cell,
    required this.column,
    required this.row,
    super.key,
    required this.fetchItems,
    required this.width,
    required this.initialValue,
    required this.onItemSelected,
    required this.itemBuilder,
    required this.itemHeight,
    required this.maxHeight,
    this.displayStringForOption,
  });

  @override
  State<TrinaAutoCompleteCell<T>> createState() =>
      _TrinaAutoCompleteCellState<T>();
}

class _TrinaAutoCompleteCellState<T> extends State<TrinaAutoCompleteCell<T>> {
  dynamic _initialCellValue;

  final _textController = TextEditingController();

  final TrinaDebounceByHashCode _debounce = TrinaDebounceByHashCode();

  late final FocusNode cellFocus;

  late _CellEditingStatus _cellEditingStatus;

  String get formattedValue =>
      widget.column.formattedValueForDisplayInEditing(widget.cell.value ?? '');

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<T> _filteredOptions = [];
  int _selectedIndex = -1;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  Timer? _debounceForTextController;

  final List<GlobalKey> _itemKeys = [];

  @override
  void initState() {
    super.initState();

    cellFocus = FocusNode(onKeyEvent: _handleOnKey);

    cellFocus.addListener(() {
      if (!cellFocus.hasFocus) {
        _handleOnComplete();
      }
    });

    widget.stateManager.setTextEditingController(_textController);

    _textController.text = formattedValue;

    _initialCellValue = _textController.text;

    _cellEditingStatus = _CellEditingStatus.init;

    _textController.addListener(() {
      _handleOnChanged(_textController.text.toString());
    });
  }

  @override
  void dispose() {
    /**
     * Saves the changed value when moving a cell while text is being input.
     * if user do not press enter key, onEditingComplete is not called and the value is not saved.
     */
    if (_cellEditingStatus.isChanged) {
      _changeValue();
    }

    if (!widget.stateManager.isEditing ||
        widget.stateManager.currentColumn?.enableEditingMode != true) {
      widget.stateManager.setTextEditingController(null);
    }

    _debounce.dispose();

    _textController.dispose();

    cellFocus.dispose();

    super.dispose();
  }

  void _restoreText() {
    if (_cellEditingStatus.isNotChanged) {
      return;
    }

    _textController.text = _initialCellValue.toString();

    widget.stateManager.changeCellValue(
      widget.stateManager.currentCell!,
      _initialCellValue,
      notify: false,
    );
  }

  bool _moveHorizontal(TrinaKeyManagerEvent keyManager) {
    if (!keyManager.isHorizontal) {
      return false;
    }

    if (widget.column.readOnly == true) {
      return true;
    }

    final selection = _textController.selection;

    if (selection.baseOffset != selection.extentOffset) {
      return false;
    }

    if (selection.baseOffset == 0 && keyManager.isLeft) {
      return true;
    }

    final textLength = _textController.text.length;

    if (selection.baseOffset == textLength && keyManager.isRight) {
      return true;
    }

    return false;
  }

  void _changeValue() {
    if (formattedValue == _textController.text) {
      return;
    }

    widget.stateManager.changeCellValue(widget.cell, _textController.text);

    _textController.text = formattedValue;

    _initialCellValue = _textController.text;

    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );

    _cellEditingStatus = _CellEditingStatus.updated;
  }

  void _handleOnChanged(String value) {
    _cellEditingStatus = formattedValue != value.toString()
        ? _CellEditingStatus.changed
        : _initialCellValue.toString() == value.toString()
        ? _CellEditingStatus.init
        : _CellEditingStatus.updated;
  }

  void _handleOnComplete() {
    final old = _textController.text;
    _changeValue();
    _handleOnChanged(old);
    _hideOverlay();
  }

  void _selectOption(T option) {
    _hideOverlay();
    final displayString = widget.displayStringForOption != null
        ? widget.displayStringForOption!(option)
        : option.toString();
    _textController.text = displayString;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
    Future.delayed(const Duration(milliseconds: 20), () {
      cellFocus.requestFocus();
    });
    widget.onItemSelected(option);
  }

  KeyEventResult _handleOnKey(FocusNode node, KeyEvent event) {
    if (_overlayEntry != null) {
      if (event is KeyDownEvent || event is KeyRepeatEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          if (_filteredOptions.isNotEmpty &&
              _selectedIndex < _filteredOptions.length - 1) {
            setState(() {
              _selectedIndex++;
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textController.text.length),
              );
            });

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToSelectedIndex();
            });
            _overlayEntry?.markNeedsBuild();
          }

          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          print(_selectedIndex);
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
          if (_filteredOptions.isNotEmpty && _selectedIndex >= 0) {
            if (_selectedIndex > 0) {
              _selectedIndex--;
              _overlayEntry?.markNeedsBuild();
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToSelectedIndex();
            });
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (_selectedIndex != -1) {
            _selectOption(_filteredOptions[_selectedIndex]);
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          _hideOverlay();
          return KeyEventResult.handled;
        }
      }

      return KeyEventResult.ignored;
    } else {
      var keyManager = TrinaKeyManagerEvent(focusNode: node, event: event);

      if (keyManager.isKeyUpEvent) {
        return KeyEventResult.handled;
      }

      // Trigger onKeyPressed callback if it exists
      if (widget.cell.onKeyPressed != null) {
        final keyEvent = TrinaGridOnKeyEvent(
          column: widget.column,
          row: widget.row,
          rowIdx: widget.stateManager.refRows.indexOf(widget.row),
          cell: widget.cell,
          event: event,
          isEnter: keyManager.isEnter,
          isEscape: keyManager.isEsc,
          isTab: keyManager.isTab,
          isShiftPressed: keyManager.isShiftPressed,
          isCtrlPressed: keyManager.isCtrlPressed,
          isAltPressed: keyManager.isAltPressed,
          logicalKey: event.logicalKey,
          currentValue: _textController.text,
        );

        widget.cell.onKeyPressed!(keyEvent);
      }

      final skip =
          !(keyManager.isVertical ||
              _moveHorizontal(keyManager) ||
              keyManager.isEsc ||
              keyManager.isTab ||
              keyManager.isEnter);

      // Movement and enter key, non-editable cell left and right movement, etc. key input is propagated to text field.
      if (skip) {
        return KeyEventResult.ignored;
      }

      if (_debounce.isDebounced(
        hashCode: _textController.text.hashCode,
        ignore: !kIsWeb,
      )) {
        return KeyEventResult.handled;
      }

      // Enter key is propagated to grid focus handler.
      if (keyManager.isEnter) {
        _handleOnComplete();
      }

      // ESC is propagated to grid focus handler.
      if (keyManager.isEsc) {
        _restoreText();
      }

      // KeyManager is delegated to handle the event.
      widget.stateManager.keyManager!.subject.add(keyManager);

      // All events are handled and event propagation is stopped.
      return KeyEventResult.handled;
    }
  }

  void _handleOnTap() {
    widget.stateManager.setKeepFocus(true);
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    // Find the position and size of the text field
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final double screenHeight = MediaQuery.of(context).size.height;
    final double spaceBelow = screenHeight - offset.dy - size.height;
    final double spaceAbove = offset.dy;
    // Estimate overlay height
    double overlayHeight = widget.maxHeight;
    bool showAbove = spaceBelow < overlayHeight && spaceAbove > overlayHeight;
    double overlayTop = showAbove
        ? offset.dy - overlayHeight
        : offset.dy + size.height;

    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return Positioned(
          left: offset.dx,
          width: widget.width,
          top: overlayTop,
          height: overlayHeight,
          child: Material(
            elevation: 4.0,
            child: _isLoading
                ? Container(
                    height: 60,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  )
                : _filteredOptions.isEmpty
                ? const SizedBox(
                    height: 60,
                    child: Center(child: Text('No results found')),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _filteredOptions.length,
                    itemBuilder: (BuildContext context, int index) {
                      final T option = _filteredOptions[index];
                      final bool isSelected = _selectedIndex == index;
                      return InkWell(
                        key: _itemKeys.length > index ? _itemKeys[index] : null,
                        onTap: () {
                          _textController.text = option.toString();
                          _textController
                              .selection = TextSelection.fromPosition(
                            TextPosition(offset: _textController.text.length),
                          );
                          _hideOverlay();
                          Future.delayed(const Duration(milliseconds: 20), () {
                            cellFocus.requestFocus();
                          });
                          widget.onItemSelected(option);
                        },
                        child: Container(
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withAlpha(38)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: widget.itemBuilder(
                              context,
                              option,
                              isSelected,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _scrollToSelectedIndex() {
    if (_selectedIndex >= 0 &&
        _filteredOptions.isNotEmpty &&
        _itemKeys.length > _selectedIndex) {
      final key = _itemKeys[_selectedIndex];
      final context = key.currentContext;
      if (context != null) {
        // Only scroll if not first or last item, or if not already fully visible
        final renderBox = context.findRenderObject() as RenderBox?;
        final listViewBox =
            _scrollController.position.context.storageContext.findRenderObject()
                as RenderBox?;
        if (renderBox != null && listViewBox != null) {
          final itemOffset = renderBox
              .localToGlobal(Offset.zero, ancestor: listViewBox)
              .dy;
          final itemHeight = renderBox.size.height;
          final listViewHeight = listViewBox.size.height;
          // If first item and fully visible, don't scroll
          if (_selectedIndex == 0 &&
              itemOffset >= 0 &&
              itemOffset + itemHeight <= listViewHeight) {
            return;
          }
          // If last item and fully visible, don't scroll
          if (_selectedIndex == _filteredOptions.length - 1 &&
              itemOffset >= 0 &&
              itemOffset + itemHeight <= listViewHeight) {
            return;
          }
        }
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 20),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _filterOptions() {
    _debounceForTextController?.cancel();
    final String query = _textController.text;
    if (query.isEmpty) {
      setState(() {
        _filteredOptions = [];
        _isLoading = false;
      });
      _hideOverlay();
      return;
    }
    setState(() {
      _isLoading = true;
      _filteredOptions = [];
      _selectedIndex = 0;
    });
    _overlayEntry?.markNeedsBuild();
    _showOverlay();
    _debounceForTextController = Timer(
      const Duration(milliseconds: 150),
      () async {
        final results = await widget.fetchItems(query);
        setState(() {
          _filteredOptions = results;
          _isLoading = false;
          _selectedIndex = results.isNotEmpty ? 0 : -1;
        });
        _overlayEntry?.markNeedsBuild();
        if (_filteredOptions.isEmpty) {
          _hideOverlay();
          _itemKeys.clear();
        } else {
          _itemKeys
            ..clear()
            ..addAll(
              List.generate(_filteredOptions.length, (_) => GlobalKey()),
            );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stateManager.keepFocus) {
      cellFocus.requestFocus();
    }

    Widget textField = Container(
      alignment: Alignment.center,
      child: TextField(
        focusNode: cellFocus,
        controller: _textController,
        readOnly: widget.column.checkReadOnly(widget.row, widget.cell),

        onEditingComplete: _handleOnComplete,
        onSubmitted: (_) => _handleOnComplete(),
        onTap: _handleOnTap,
        style: widget.stateManager.configuration.style.cellTextStyle,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        maxLines: 1,

        textAlign: widget.column.textAlign.value,
        onChanged: (value) {
          _filterOptions();
        },
      ),
    );

    Widget w = CompositedTransformTarget(link: _layerLink, child: textField);

    // Use column-level editCellRenderer if available, otherwise fall back to grid-level
    if (widget.column.editCellRenderer != null) {
      w = widget.column.editCellRenderer!(
        w,
        widget.cell,
        _textController,
        cellFocus,
        null,
      );
    } else if (widget.stateManager.editCellRenderer != null) {
      w = widget.stateManager.editCellRenderer!(
        w,
        widget.cell,
        _textController,
        cellFocus,
        null,
      );
    }

    return w;
  }
}

enum _CellEditingStatus {
  init,
  changed,
  updated;

  bool get isNotChanged {
    return _CellEditingStatus.changed != this;
  }

  bool get isChanged {
    return _CellEditingStatus.changed == this;
  }

  bool get isUpdated {
    return _CellEditingStatus.updated == this;
  }
}
