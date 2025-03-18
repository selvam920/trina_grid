import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

class TrinaHorizontalScrollBar extends StatefulWidget {
  const TrinaHorizontalScrollBar({
    super.key,
    required this.stateManager,
    required this.horizontalScrollExtentNotifier,
    required this.horizontalViewportExtentNotifier,
    required this.horizontalScrollOffsetNotifier,
    required this.context,
    required this.width,
  });

  final TrinaGridStateManager stateManager;
  final ValueNotifier<double> horizontalScrollExtentNotifier;
  final ValueNotifier<double> horizontalViewportExtentNotifier;
  final ValueNotifier<double> horizontalScrollOffsetNotifier;
  final BuildContext context;
  final double width;

  @override
  State<TrinaHorizontalScrollBar> createState() =>
      _TrinaHorizontalScrollBarState();
}

class _TrinaHorizontalScrollBarState extends State<TrinaHorizontalScrollBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _hovering = false;
  bool _isDragging = false;

  // Track the last scroll position to detect scrolling
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();

    // Create a fade animation controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Initialize the fade controller based on isAlwaysShown setting
    if (widget.stateManager.configuration.scrollbar.isAlwaysShown) {
      _fadeController.value = 1.0;
    } else {
      _fadeController.value = 0.0;
    }

    // Listen for scroll changes to show the scrollbar temporarily
    widget.horizontalScrollOffsetNotifier.addListener(_handleScrollChange);

    // Listen to stateManager for configuration changes
    widget.stateManager.addListener(_handleConfigChange);
  }

  void _handleConfigChange() {
    // Check configuration changes, specifically scrollbar settings
    final scrollConfig = widget.stateManager.configuration.scrollbar;
    if (scrollConfig.isAlwaysShown && scrollConfig.thumbVisible) {
      // Always show the scrollbar
      _fadeController.animateTo(1.0);
    } else if (!scrollConfig.thumbVisible) {
      // Hide scrollbar if thumbVisible is false
      _fadeController.animateTo(0.0);
    } else if (!scrollConfig.isAlwaysShown) {
      // Hide scrollbar if not always shown and not actively scrolling/hovering
      if (!_hovering && !_isDragging) {
        _fadeController.animateTo(0.0);
      }
    }
  }

  @override
  void didUpdateWidget(TrinaHorizontalScrollBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Get old and new configurations
    final oldConfig = oldWidget.stateManager.configuration.scrollbar;
    final newConfig = widget.stateManager.configuration.scrollbar;

    // Check for changes in visibility settings
    if (oldConfig.isAlwaysShown != newConfig.isAlwaysShown ||
        oldConfig.thumbVisible != newConfig.thumbVisible) {
      // When isAlwaysShown or thumbVisible changes
      if (newConfig.isAlwaysShown && newConfig.thumbVisible) {
        // Always show the scrollbar
        _fadeController.animateTo(1.0);
      } else if (!newConfig.thumbVisible) {
        // Hide scrollbar if thumbVisible is false
        _fadeController.animateTo(0.0);
      } else if (!newConfig.isAlwaysShown) {
        // Hide scrollbar if not always shown and not actively scrolling/hovering
        if (!_hovering && !_isDragging) {
          _fadeController.animateTo(0.0);
        }
      }
    }
  }

  void _handleScrollChange() {
    final scrollConfig = widget.stateManager.configuration.scrollbar;
    final currentOffset = widget.horizontalScrollOffsetNotifier.value;

    // If not set to always shown and we detect scrolling
    if (!scrollConfig.isAlwaysShown && currentOffset != _lastScrollOffset) {
      _showScrollbar();
      _lastScrollOffset = currentOffset;
    }
  }

  void _showScrollbar() {
    _fadeController.forward();

    // If not hovering or dragging, hide after delay
    if (!widget.stateManager.configuration.scrollbar.isAlwaysShown &&
        !_hovering &&
        !_isDragging) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!_hovering && !_isDragging && mounted) {
          _fadeController.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.horizontalScrollOffsetNotifier.removeListener(_handleScrollChange);
    widget.stateManager.removeListener(_handleConfigChange);
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrollConfig = widget.stateManager.configuration.scrollbar;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovering = true;
          if (!scrollConfig.isAlwaysShown) {
            _fadeController.forward();
          }
        });
      },
      onExit: (_) {
        setState(() {
          _hovering = false;
          if (!scrollConfig.isAlwaysShown && !_isDragging) {
            _fadeController.reverse();
          }
        });
      },
      child: GestureDetector(
        onPanDown: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
            if (!scrollConfig.isAlwaysShown && !_hovering) {
              _fadeController.reverse();
            }
          });
        },
        onPanCancel: () {
          setState(() {
            _isDragging = false;
            if (!scrollConfig.isAlwaysShown && !_hovering) {
              _fadeController.reverse();
            }
          });
        },
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ValueListenableBuilder<double>(
            valueListenable: widget.horizontalScrollExtentNotifier,
            builder: (context, scrollExtent, _) {
              if (scrollExtent <= 0) {
                return SizedBox(height: scrollConfig.thickness);
              }

              return ValueListenableBuilder<double>(
                valueListenable: widget.horizontalViewportExtentNotifier,
                builder: (context, viewportExtent, _) {
                  final double thumbWidth =
                      (viewportExtent / (viewportExtent + scrollExtent)) *
                      widget.width;

                  return ValueListenableBuilder<double>(
                    valueListenable: widget.horizontalScrollOffsetNotifier,
                    builder: (context, scrollOffset, _) {
                      final double thumbPosition =
                          (scrollOffset / scrollExtent) *
                          (widget.width - thumbWidth);

                      return SizedBox(
                        width: widget.width,
                        height: scrollConfig.thickness + 4, // Add padding
                        child: Stack(
                          children: [
                            // Track
                            if (scrollConfig.showTrack)
                              Container(
                                height: scrollConfig.thickness,
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: scrollConfig.effectiveTrackColor,
                                  borderRadius: BorderRadius.circular(
                                    scrollConfig.thickness / 2,
                                  ),
                                ),
                              ),
                            // Thumb
                            if (scrollConfig.thumbVisible)
                              Positioned(
                                left: thumbPosition.isNaN ? 0 : thumbPosition,
                                width:
                                    thumbWidth.isNaN
                                        ? widget.width
                                        : thumbWidth.clamp(
                                          scrollConfig.minThumbLength,
                                          widget.width,
                                        ),
                                height: scrollConfig.thickness,
                                top: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: scrollConfig.effectiveThumbColor,
                                    borderRadius: BorderRadius.circular(
                                      scrollConfig.thickness / 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
