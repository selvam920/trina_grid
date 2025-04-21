import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

class MultiLineColumnFilter extends StatefulWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final void Function(String) handleOnChanged;
  final TrinaGridStateManager stateManager;
  const MultiLineColumnFilter({
    super.key,
    required this.focusNode,
    required this.controller,
    required this.handleOnChanged,
    required this.stateManager,
  });

  @override
  State<MultiLineColumnFilter> createState() => _MultiLineColumnFilterState();
}

class _MultiLineColumnFilterState extends State<MultiLineColumnFilter> {
  Timer? _debounceTimer;
  String _lastValue = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final fillColor =
        widget.stateManager.configuration.style.cellColorInEditState;

    return Stack(
      children: [
        TextField(
          focusNode: widget.focusNode,
          controller: widget.controller,
          style: widget.stateManager.configuration.style.cellTextStyle,
          maxLines: null,
          onChanged: (value) {
            if (_lastValue == value) {
              return;
            }
            _lastValue = value;

            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 500), () {
              widget.handleOnChanged(widget.controller.text);
            });
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            border: _border,
            enabledBorder: _border,
            focusedBorder: _enabledBorder,
            hintText: 'Filter',
            contentPadding: const EdgeInsets.all(5),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.controller.text.isNotEmpty)
                  SizedBox(
                    width: 30,
                    child: Opacity(
                      opacity: 0.5,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          widget.controller.clear();
                          widget.handleOnChanged('');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                  ),
                SizedBox(
                  width: 30,
                  child: Opacity(
                    opacity: 0.5,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Edit Filter'),
                            content: Material(
                              child: TextField(
                                controller: widget.controller,
                                maxLines: null,
                                minLines: 10,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  widget.handleOnChanged(
                                    widget.controller.text,
                                  );
                                  Navigator.pop(context);
                                },
                                child: const Text('Ok'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputBorder get _border => OutlineInputBorder(
        borderSide: BorderSide(
          color: widget.stateManager.configuration.style.borderColor,
          width: 0.0,
        ),
        borderRadius: BorderRadius.zero,
      );

  InputBorder get _enabledBorder => OutlineInputBorder(
        borderSide: BorderSide(
          color: widget.stateManager.configuration.style.activatedBorderColor,
          width: 0.0,
        ),
        borderRadius: BorderRadius.zero,
      );
}
