import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

class TrinaHorizontalScrollBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final scrollConfig = stateManager.configuration.scrollbar;

    return ValueListenableBuilder<double>(
      valueListenable: horizontalScrollExtentNotifier,
      builder: (context, scrollExtent, _) {
        if (scrollExtent <= 0) return SizedBox(height: scrollConfig.thickness);

        return ValueListenableBuilder<double>(
          valueListenable: horizontalViewportExtentNotifier,
          builder: (context, viewportExtent, _) {
            final double thumbWidth =
                (viewportExtent / (viewportExtent + scrollExtent)) * width;

            return ValueListenableBuilder<double>(
              valueListenable: horizontalScrollOffsetNotifier,
              builder: (context, scrollOffset, _) {
                final double thumbPosition =
                    (scrollOffset / scrollExtent) * (width - thumbWidth);

                return SizedBox(
                  width: width,
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
                                  ? width
                                  : thumbWidth.clamp(
                                    scrollConfig.minThumbLength,
                                    width,
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
    );
  }
}
