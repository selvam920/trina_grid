import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trina_grid/trina_grid.dart';

class TrinaDropdownCell<T> extends StatefulWidget {
  final TrinaGridStateManager stateManager;
  final TrinaCell cell;
  final TrinaColumn column;
  final TrinaRow row;
  final List<T> items;
  final List<T> Function(TrinaRow row, TrinaCell cell)? itemsProvider;
  final double width;
  final T? initialValue;
  final void Function(T) onItemSelected;
  final TrinaAutoCompleteItemBuilder<T> itemBuilder;
  final double maxHeight;
  final bool autoOpen;
  final TrinaAutocompleteOptionToString<T>? displayStringForOption;

  const TrinaDropdownCell({
    required this.stateManager,
    required this.cell,
    required this.column,
    required this.row,
    required this.items,
    this.itemsProvider,
    required this.width,
    required this.initialValue,
    required this.onItemSelected,
    required this.itemBuilder,
    required this.maxHeight,
    this.autoOpen = true,
    this.displayStringForOption,
    super.key,
  });

  @override
  State<TrinaDropdownCell<T>> createState() => _TrinaDropdownCellState<T>();
}

class _TrinaDropdownCellState<T> extends State<TrinaDropdownCell<T>> {
  final _textController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  int _selectedIndex = -1;
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _itemKeys = [];
  late final FocusNode cellFocus;
  bool _isSelecting = false;

  List<T> get effectiveItems =>
      widget.itemsProvider?.call(widget.row, widget.cell) ?? widget.items;

  String get formattedValue =>
      widget.column.formattedValueForDisplayInEditing(widget.cell.value ?? '');

  @override
  void initState() {
    super.initState();
    cellFocus = FocusNode(onKeyEvent: _handleOnKey);

    cellFocus.addListener(() {
      if (cellFocus.hasFocus) {
        if (widget.autoOpen && !_isSelecting) {
          _showOverlay();
        }
      } else {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _hideOverlay();
          }
        });
      }
    });

    _textController.text = formattedValue;

    // Set selected index based on current value
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final currentText = _textController.text;
    final items = effectiveItems;
    int matchIndex = -1;
    for (int i = 0; i < items.length; i++) {
      final itemText = widget.displayStringForOption != null
          ? widget.displayStringForOption!(items[i])
          : items[i].toString();
      if (itemText == currentText) {
        matchIndex = i;
        break;
      }
    }
    _selectedIndex = matchIndex != -1 ? matchIndex : (items.isNotEmpty ? 0 : -1);
  }

  @override
  void dispose() {
    _hideOverlay();
    _scrollController.dispose();
    _textController.dispose();
    cellFocus.dispose();
    super.dispose();
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final double screenHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).viewInsets.bottom -
        MediaQuery.of(context).padding.bottom;
    final double spaceBelow = screenHeight - offset.dy - size.height;
    final double spaceAbove = offset.dy;

    bool showAbove = spaceBelow < widget.maxHeight && spaceAbove > spaceBelow;
    double availableSpace = showAbove ? spaceAbove : spaceBelow;
    double overlayHeight =
        widget.maxHeight <= availableSpace ? widget.maxHeight : availableSpace;

    final items = effectiveItems;
    _itemKeys.clear();
    _itemKeys.addAll(List.generate(items.length, (_) => GlobalKey()));

    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return UnconstrainedBox(
          alignment: Alignment.topLeft,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: showAbove ? Offset(0, -overlayHeight) : Offset(0, size.height),
            child: SizedBox(
              width: widget.width,
              height: overlayHeight,
              child: Material(
                elevation: 4.0,
                child: items.isEmpty
                    ? const SizedBox(
                        height: 60,
                        child: Center(child: Text('No options available')),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (BuildContext context, int index) {
                          final T option = items[index];
                          final bool isSelected = _selectedIndex == index;
                          return InkWell(
                            key: _itemKeys[index],
                            onTap: () => _selectOption(option),
                            child: Container(
                              alignment: widget.column.textAlign.alignmentValue,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary.withAlpha(38)
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
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);

    if (_selectedIndex != -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedIndex();
      });
    }
  }

  void _scrollToSelectedIndex() {
    if (_selectedIndex >= 0 &&
        effectiveItems.isNotEmpty &&
        _itemKeys.length > _selectedIndex) {
      final key = _itemKeys[_selectedIndex];
      final context = key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 20),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _selectOption(T option) {
    _isSelecting = true;
    _hideOverlay();
    final displayString = widget.displayStringForOption != null
        ? widget.displayStringForOption!(option)
        : option.toString();

    final bool isChanged = formattedValue != displayString;

    final configuration = widget.stateManager.configuration;
    final shouldMove = configuration.enableMoveDownAfterSelecting ||
        configuration.enableMoveRightAfterSelecting;

    if (!shouldMove) {
      cellFocus.requestFocus();
    }

    if (isChanged || shouldMove) {
      widget.stateManager.handleAfterSelectingRow(widget.cell, displayString);
      widget.onItemSelected(option);
    }
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _isSelecting = false;
    });
  }

  void _handleOnComplete() {
    if (_overlayEntry != null) {
      final items = effectiveItems;
      if (_selectedIndex != -1 && items.isNotEmpty) {
        _selectOption(items[_selectedIndex]);
      } else {
        _hideOverlay();
      }
      return;
    }

    widget.stateManager.handleAfterSelectingRow(widget.cell, _textController.text);
  }

  KeyEventResult _handleOnKey(FocusNode node, KeyEvent event) {
    if (_overlayEntry != null) {
      final items = effectiveItems;
      if (event is KeyDownEvent || event is KeyRepeatEvent) {
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (_selectedIndex != -1 && items.isNotEmpty) {
            _selectOption(items[_selectedIndex]);
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          if (items.isNotEmpty && _selectedIndex < items.length - 1) {
            setState(() {
              _selectedIndex++;
            });
            _overlayEntry?.markNeedsBuild();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToSelectedIndex();
            });
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          if (items.isNotEmpty && _selectedIndex > 0) {
            setState(() {
              _selectedIndex--;
            });
            _overlayEntry?.markNeedsBuild();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToSelectedIndex();
            });
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          _hideOverlay();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    } else {
      var keyManager = TrinaKeyManagerEvent(focusNode: node, event: event);
      if (keyManager.isKeyUpEvent) return KeyEventResult.handled;

      if (event.logicalKey == LogicalKeyboardKey.space) {
        _showOverlay();
        return KeyEventResult.handled;
      }

      // Enter key is handled by _handleOnComplete.
      if (keyManager.isEnter) {
        _handleOnComplete();
        return KeyEventResult.handled;
      }

      // ESC is propagated to grid focus handler.
      if (keyManager.isEsc) {
        _hideOverlay();
      }

      widget.stateManager.keyManager!.subject.add(keyManager);
      return KeyEventResult.handled;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stateManager.keepFocus) {
      cellFocus.requestFocus();
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        alignment: Alignment.center,
        child: TextField(
          focusNode: cellFocus,
          controller: _textController,
          readOnly: true,
          onTap: () {
            widget.stateManager.setKeepFocus(true);
            _showOverlay();
          },
          style: widget.stateManager.configuration.style.cellTextStyle,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            suffixIcon: Icon(Icons.arrow_drop_down),
          ),
          maxLines: 1,
          textAlignVertical: TextAlignVertical.center,
          textAlign: widget.column.textAlign.value,
        ),
      ),
    );
  }
}
