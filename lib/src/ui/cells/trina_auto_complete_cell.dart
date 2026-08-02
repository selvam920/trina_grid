import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trina_grid/trina_grid.dart';

class _PopupListScrollBehavior extends MaterialScrollBehavior {
  const _PopupListScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

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

  /// The maximum height of the popup menu's scrollable area.
  final double maxHeight;

  /// Whether to automatically open the dropdown when the cell is focused.
  final bool autoOpen;

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
    required this.maxHeight,
    this.autoOpen = false,
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
  bool _isSelecting = false;

  final List<GlobalKey> _itemKeys = [];

  @override
  void initState() {
    super.initState();

    cellFocus = FocusNode(onKeyEvent: _handleOnKey);

    cellFocus.addListener(() {
      if (cellFocus.hasFocus) {
        if (widget.autoOpen && !_isSelecting) {
          _filterOptions(forceShowAll: true);
        }
      } else {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !cellFocus.hasFocus) {
            if (!_isSelecting) {
              _restoreText();
            }
            _hideOverlay();
          }
        });
      }
    });

    widget.stateManager.setTextEditingController(_textController);

    _textController.text = formattedValue;

    _initialCellValue = widget.cell.value;

    _cellEditingStatus = _CellEditingStatus.init;

    _textController.addListener(() {
      _handleOnChanged(_textController.text.toString());
    });
  }

  @override
  void dispose() {
    final configuration = widget.stateManager.configuration;

    // If restore on cancel is enabled, restore before disposing if it was changed and not explicitly selected
    if (configuration.enableRestoreValueOnCancel &&
        _cellEditingStatus.isChanged &&
        !_isSelecting) {
      _restoreText();
    }

    // Remove overlay before disposing to prevent orphaned overlay entries
    _hideOverlay();

    /// Saves the changed value when moving a cell while text is being input.
    /// If user does not press enter key, onEditingComplete is not called.
    if (_cellEditingStatus.isChanged) {
      _changeValue();
    }

    if (!widget.stateManager.isEditing ||
        widget.stateManager.currentColumn?.enableEditingMode != true) {
      widget.stateManager.setTextEditingController(null);
    }

    _debounceForTextController?.cancel();

    _debounce.dispose();

    _scrollController.dispose();

    _textController.dispose();

    cellFocus.dispose();

    super.dispose();
  }

  void _restoreText() {
    if (!widget.stateManager.configuration.enableRestoreValueOnCancel) {
      return;
    }

    if (_textController.text == formattedValue &&
        _cellEditingStatus.isNotChanged) {
      return;
    }

    widget.stateManager.changeCellValue(
      widget.cell,
      _initialCellValue,
      notify: false,
    );

    _textController.text = formattedValue;
    _cellEditingStatus = _CellEditingStatus.init;
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

  void _selectOption(T option, {bool isKeyboardSelection = false}) {
    _isSelecting = true;
    _hideOverlay();
    _debounceForTextController?.cancel();
    final displayString = widget.displayStringForOption != null
        ? widget.displayStringForOption!(option)
        : option.toString();

    _textController.text = displayString;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );

    widget.stateManager.handleAfterSelectingRow(widget.cell, option);

    final config = widget.stateManager.configuration;
    // Only skip re-requesting focus when Enter itself is expected to move
    // the current cell afterwards. A mouse click has no such follow-up
    // navigation event, so it must always reclaim focus here — otherwise
    // the cell ends up unfocused and the delayed restore-on-cancel logic
    // reverts the just-selected value back to the old one.
    final shouldMove =
        isKeyboardSelection &&
        (config.enterKeyAction.isEditingAndMoveDown ||
            config.enterKeyAction.isEditingAndMoveRight ||
            config.enterKeyAction.isEditingAndMoveUp ||
            config.enterKeyAction.isEditingAndMoveLeft) &&
        widget.column.enableEnterMoveCell;

    if (!shouldMove) {
      cellFocus.requestFocus();
    }

    widget.onItemSelected(option);

    _cellEditingStatus = _CellEditingStatus.updated;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _isSelecting = false;
    });
  }

  void _handleOnComplete() {
    // If overlay is open, select the current item.
    // If overlay is closed, let the grid handle it.
    if (_overlayEntry != null) {
      if (_selectedIndex != -1) {
        _selectOption(
          _filteredOptions[_selectedIndex],
          isKeyboardSelection: true,
        );
      } else {
        _hideOverlay();
      }
      return;
    }

    final value = _textController.text == formattedValue
        ? widget.cell.value
        : _textController.text;

    widget.stateManager.handleAfterSelectingRow(widget.cell, value);

    _cellEditingStatus = _CellEditingStatus.updated;
  }

  KeyEventResult _handleOnKey(FocusNode node, KeyEvent event) {
    if (_overlayEntry != null) {
      if (event is KeyDownEvent || event is KeyRepeatEvent) {
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (_selectedIndex != -1) {
            // Broadcast with skipShortcutHandling so listeners get notified
            // but the shortcut handler won't double-move
            final keyManager = TrinaKeyManagerEvent(
              focusNode: node,
              event: event,
              sourceColumn: widget.column,
              sourceRow: widget.row,
              sourceCell: widget.cell,
              sourceRowIdx: widget.stateManager.refRows.indexOf(widget.row),
              sourceCellPosition: TrinaGridCellPosition(
                columnIdx: widget.stateManager.columnIndex(widget.column),
                rowIdx: widget.stateManager.refRows.indexOf(widget.row),
              ),
              skipShortcutHandling: true,
            );
            widget.stateManager.keyManager!.subject.add(keyManager);

            _selectOption(
              _filteredOptions[_selectedIndex],
              isKeyboardSelection: true,
            );

            return KeyEventResult.handled;
          } else {
            _hideOverlay();
            return KeyEventResult.ignored;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
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
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
          if (_filteredOptions.isNotEmpty && _selectedIndex > 0) {
            setState(() {
              _selectedIndex--;
            });
            _overlayEntry?.markNeedsBuild();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToSelectedIndex();
            });
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _restoreText();
          _hideOverlay();
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          _restoreText();
          _hideOverlay();
          return KeyEventResult.handled;
        }
      }

      if (_overlayEntry == null) {
        // Fall through to grid navigation if overlay was closed
        var keyManager = TrinaKeyManagerEvent(
          focusNode: node,
          event: event,
          sourceColumn: widget.column,
          sourceRow: widget.row,
          sourceCell: widget.cell,
          sourceRowIdx: widget.stateManager.refRows.indexOf(widget.row),
          sourceCellPosition: TrinaGridCellPosition(
            columnIdx: widget.stateManager.columnIndex(widget.column),
            rowIdx: widget.stateManager.refRows.indexOf(widget.row),
          ),
        );
        widget.stateManager.keyManager!.subject.add(keyManager);
        return KeyEventResult.handled;
      }

      return KeyEventResult.ignored;
    } else {
      var keyManager = TrinaKeyManagerEvent(
        focusNode: node,
        event: event,
        sourceColumn: widget.column,
        sourceRow: widget.row,
        sourceCell: widget.cell,
        sourceRowIdx: widget.stateManager.refRows.indexOf(widget.row),
        sourceCellPosition: TrinaGridCellPosition(
          columnIdx: widget.stateManager.columnIndex(widget.column),
          rowIdx: widget.stateManager.refRows.indexOf(widget.row),
        ),
      );

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

      if (event.logicalKey == LogicalKeyboardKey.space &&
          event is KeyDownEvent &&
          _overlayEntry == null) {
        _filterOptions(forceShowAll: true);
        return KeyEventResult.handled;
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
        final config = widget.stateManager.configuration;
        final shouldMove =
            config.enterKeyAction.isEditingAndMoveDown ||
            config.enterKeyAction.isEditingAndMoveRight ||
            config.enterKeyAction.isEditingAndMoveUp ||
            config.enterKeyAction.isEditingAndMoveLeft;

        if (!shouldMove) {
          return KeyEventResult.ignored;
        }
        // Broadcast with skipShortcutHandling — _handleOnComplete handles movement
        final enterEvent = TrinaKeyManagerEvent(
          focusNode: node,
          event: event,
          sourceColumn: widget.column,
          sourceRow: widget.row,
          sourceCell: widget.cell,
          sourceRowIdx: widget.stateManager.refRows.indexOf(widget.row),
          sourceCellPosition: TrinaGridCellPosition(
            columnIdx: widget.stateManager.columnIndex(widget.column),
            rowIdx: widget.stateManager.refRows.indexOf(widget.row),
          ),
          skipShortcutHandling: true,
        );
        widget.stateManager.keyManager!.subject.add(enterEvent);
        _handleOnComplete();
        return KeyEventResult.handled;
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
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final double screenHeight =
        MediaQuery.of(context).size.height -
        MediaQuery.of(context).viewInsets.bottom -
        MediaQuery.of(context).padding.bottom;
    final double spaceBelow = screenHeight - offset.dy - size.height;
    final double spaceAbove = offset.dy;

    bool showAbove = spaceBelow < widget.maxHeight && spaceAbove > spaceBelow;
    double availableSpace = showAbove ? spaceAbove : spaceBelow;
    double overlayHeight = widget.maxHeight <= availableSpace
        ? widget.maxHeight
        : availableSpace;

    // Use CompositedTransformFollower so the overlay tracks the cell if the grid scrolls
    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                _restoreText();
                _hideOverlay();
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
            // Positioned.fill (not UnconstrainedBox): CompositedTransformFollower
            // shifts its child at paint time only, so the ancestor's hit-test box
            // stays at the Stack origin. Sizing that ancestor to the popup would
            // leave everything painted outside that phantom rect unclickable.
            Positioned.fill(
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: showAbove
                    ? Offset(0, -overlayHeight)
                    : Offset(0, size.height),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: widget.width,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              ),
                            )
                          : Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              child: ScrollConfiguration(
                                behavior: const _PopupListScrollBehavior(),
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: _filteredOptions.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                        final T option =
                                            _filteredOptions[index];
                                        final bool isSelected =
                                            _selectedIndex == index;
                                        return InkWell(
                                          key: _itemKeys.length > index
                                              ? _itemKeys[index]
                                              : null,
                                          onTap: () => _selectOption(option),
                                          onHover: (isHovering) {
                                            if (isHovering &&
                                                _selectedIndex != index) {
                                              setState(() {
                                                _selectedIndex = index;
                                              });
                                              _overlayEntry?.markNeedsBuild();
                                            }
                                          },
                                          child: Container(
                                            alignment: widget
                                                .column
                                                .textAlign
                                                .alignmentValue,
                                            color: isSelected
                                                ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withAlpha(38)
                                                : null,
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
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
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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

  void _filterOptions({bool forceShowAll = false}) {
    // Setting _textController.text below in _selectOption() fires this
    // via TextField.onChanged (Flutter invokes onChanged for any
    // controller text change, not just user input). Skip re-opening the
    // overlay right after a click/enter selection.
    if (_isSelecting) {
      return;
    }

    _debounceForTextController?.cancel();

    final String query = forceShowAll ? '' : _textController.text;

    if (query.isEmpty && !widget.autoOpen && !forceShowAll) {
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
        try {
          final results = await widget.fetchItems(query);

          if (!mounted ||
              (forceShowAll ? false : _textController.text != query)) {
            return;
          }

          setState(() {
            _filteredOptions = results;
            _isLoading = false;

            // Select the item if it matches the current text
            final currentText = _textController.text;
            int matchIndex = -1;
            for (int i = 0; i < results.length; i++) {
              final itemText = widget.displayStringForOption != null
                  ? widget.displayStringForOption!(results[i])
                  : results[i].toString();
              if (itemText == currentText) {
                matchIndex = i;
                break;
              }
            }

            _selectedIndex = matchIndex != -1
                ? matchIndex
                : (results.isNotEmpty ? 0 : -1);
          });

          if (_filteredOptions.isEmpty) {
            _hideOverlay();
            _itemKeys.clear();
          } else {
            _overlayEntry?.markNeedsBuild();
            _itemKeys
              ..clear()
              ..addAll(
                List.generate(_filteredOptions.length, (_) => GlobalKey()),
              );

            if (_selectedIndex != -1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToSelectedIndex();
              });
            }
          }
        } catch (e) {
          if (mounted && (forceShowAll || _textController.text == query)) {
            setState(() {
              _isLoading = false;
            });
            _hideOverlay();
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stateManager.keepFocus && FocusScope.of(context).hasFocus) {
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
        textAlignVertical: TextAlignVertical.center,
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
