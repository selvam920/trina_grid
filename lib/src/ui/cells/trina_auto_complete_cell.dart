import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
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

  /// Hardware barcode scanner input: keys at scanner speed ended by the
  /// scanner's own Enter or Tab hand the typed code here instead of
  /// searching. Null = no scan handling.
  final void Function(String code)? onScan;

  /// With [onScan]: the most milliseconds, on average, between the characters
  /// of one scan. Null = 50.
  final int Function()? scanGapMs;

  /// With [onScan]: the scanner sends no Enter or Tab, so a run at scanner
  /// speed is a scan once its keys stop. Null = false.
  final bool Function()? scanEndsOnPause;

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
    this.onScan,
    this.scanGapMs,
    this.scanEndsOnPause,
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

  // With [TrinaAutoCompleteCell.onScan]: the current run of typing -- changes
  // closer than [_runGapMs] -- and the characters it added, to tell a scanner
  // from a hand. Characters, not key presses: some scanners put the whole
  // code in at once. The search waits out that gap, so a scan never reaches
  // it.
  DateTime? _runStart;
  DateTime? _lastChange;
  int _runChars = 0;
  Timer? _holdTimer;

  // The text's length before and after its latest change, programmatic ones
  // included: what each change added.
  int _lengthBefore = 0;
  int _length = 0;

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
    _length = _textController.text.length;

    _initialCellValue = widget.cell.value;

    _cellEditingStatus = _CellEditingStatus.init;

    _textController.addListener(() {
      _lengthBefore = _length;
      _length = _textController.text.length;
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

    _holdTimer?.cancel();

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
    // A scanner that ends with the IME's action rather than an Enter key.
    if (_takeScan()) return;

    // If overlay is open, select the current item.
    // If overlay is closed, let the grid handle it.
    if (_overlayEntry != null) {
      if (_selectedIndex != -1 && _selectedIndex < _filteredOptions.length) {
        _selectOption(
          _filteredOptions[_selectedIndex],
          isKeyboardSelection: true,
        );
      } else if (!_isLoading) {
        _hideOverlay();
      }
      // Still loading, there is no item to select yet: the list stays, and
      // the next Enter picks from it.
      return;
    }

    final value = _textController.text == formattedValue
        ? widget.cell.value
        : _textController.text;

    widget.stateManager.handleAfterSelectingRow(widget.cell, value);

    _cellEditingStatus = _CellEditingStatus.updated;
  }

  KeyEventResult _handleOnKey(FocusNode node, KeyEvent event) {
    // A scanner's own Enter / Tab ends its scan here, before the list or the
    // grid sees the key.
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter ||
            event.logicalKey == LogicalKeyboardKey.tab) &&
        _takeScan()) {
      return KeyEventResult.handled;
    }

    if (_overlayEntry != null) {
      if (event is KeyDownEvent || event is KeyRepeatEvent) {
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          // Still loading there is no item to select yet: the list stays,
          // and the next Enter picks from it.
          if (_isLoading) return KeyEventResult.handled;
          if (_selectedIndex != -1 &&
              _selectedIndex < _filteredOptions.length) {
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

  int get _scanGapMs => widget.scanGapMs?.call() ?? 50;

  /// A pause this long ends a run of typing: the search waits it out, and a
  /// scanner's Enter / Tab comes within it.
  int get _runGapMs => math.max(100, 2 * _scanGapMs);

  /// The current run came at scanner speed: at least three characters, on
  /// average no more than [TrinaAutoCompleteCell.scanGapMs] apart. A code put
  /// in whole takes no time at all.
  bool get _runIsScan {
    final start = _runStart;
    final last = _lastChange;
    if (start == null || last == null || _runChars < 3) return false;
    return last.difference(start).inMilliseconds <=
        _scanGapMs * (_runChars - 1);
  }

  /// Typing with [TrinaAutoCompleteCell.onScan]: the search waits until the
  /// keys stop for [_runGapMs]. A scanner never leaves that gap before its
  /// own Enter / Tab ends the scan ([_takeScan]), so a scan calls no
  /// [TrinaAutoCompleteCell.fetchItems] and opens no list, while typing by
  /// hand searches once it pauses.
  void _holdForScan() {
    if (_isSelecting) return;
    final now = DateTime.now();
    final last = _lastChange;
    if (last == null || now.difference(last).inMilliseconds >= _runGapMs) {
      _runStart = now;
      _runChars = 0;
    }
    if (_length > _lengthBefore) _runChars += _length - _lengthBefore;
    _lastChange = now;
    _holdTimer?.cancel();
    _debounceForTextController?.cancel();

    if (_textController.text.isEmpty) {
      _filterOptions();
      return;
    }
    if (_runIsScan) {
      _hideOverlay();
    } else if (_overlayEntry != null) {
      // The open list is for the text before this key: wait, don't pick
      // from it.
      setState(() {
        _isLoading = true;
        _filteredOptions = [];
        _selectedIndex = -1;
      });
      _overlayEntry?.markNeedsBuild();
    }
    _holdTimer = Timer(Duration(milliseconds: _runGapMs), () {
      // Left the cell before the pause: no list behind it.
      if (!mounted || !cellFocus.hasFocus) return;
      // A scanner with no end key: its scan ends with this pause.
      if ((widget.scanEndsOnPause?.call() ?? false) && _takeScan(ended: true)) {
        return;
      }
      _filterOptions(delay: Duration.zero);
    });
  }

  /// Enter / Tab close behind a run of keys at scanner speed -- or, [ended],
  /// the pause after one when the scanner sends no end key -- hands the typed
  /// code to [TrinaAutoCompleteCell.onScan], and the cell goes back to what
  /// it held. False for typing by hand: the key then does its usual job.
  bool _takeScan({bool ended = false}) {
    final onScan = widget.onScan;
    final last = _lastChange;
    final code = _textController.text.trim();
    if (onScan == null ||
        last == null ||
        code.isEmpty ||
        (!ended &&
            DateTime.now().difference(last).inMilliseconds >= _runGapMs) ||
        !_runIsScan) {
      return false;
    }
    _holdTimer?.cancel();
    _debounceForTextController?.cancel();
    _hideOverlay();
    _isLoading = false;
    _lastChange = null;
    _isSelecting = true;
    _textController.text = formattedValue;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
    _cellEditingStatus = _CellEditingStatus.init;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _isSelecting = false;
    });
    onScan(code);
    return true;
  }

  void _filterOptions({
    bool forceShowAll = false,
    Duration delay = const Duration(milliseconds: 150),
  }) {
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

    _debounceForTextController = Timer(delay, () async {
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
    });
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
          if (widget.onScan != null) {
            _holdForScan();
          } else {
            _filterOptions();
          }
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
