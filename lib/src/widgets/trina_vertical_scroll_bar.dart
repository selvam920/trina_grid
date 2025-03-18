import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

class TrinaVerticalScrollBar extends StatelessWidget {
  const TrinaVerticalScrollBar({
    super.key,
    required this.stateManager,
    required this.verticalScrollExtentNotifier,
    required this.verticalViewportExtentNotifier,
    required this.verticalScrollOffsetNotifier,
    required this.context,
    required this.height,
  });

  final TrinaGridStateManager stateManager;
  final ValueNotifier<double> verticalScrollExtentNotifier;
  final ValueNotifier<double> verticalViewportExtentNotifier;
  final ValueNotifier<double> verticalScrollOffsetNotifier;
  final BuildContext context;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scrollConfig = stateManager.configuration.scrollbar;

    return ValueListenableBuilder<double>(
      valueListenable: verticalScrollExtentNotifier,
      builder: (context, scrollExtent, _) {
        if (scrollExtent <= 0) return SizedBox(width: scrollConfig.thickness);

        return ValueListenableBuilder<double>(
          valueListenable: verticalViewportExtentNotifier,
          builder: (context, viewportExtent, _) {
            final double thumbHeight =
                (viewportExtent / (viewportExtent + scrollExtent)) * height;

            return ValueListenableBuilder<double>(
              valueListenable: verticalScrollOffsetNotifier,
              builder: (context, scrollOffset, _) {
                final double thumbPosition =
                    (scrollOffset / scrollExtent) * (height - thumbHeight);

                return SizedBox(
                  width: scrollConfig.thickness + 4, // Add padding
                  height: height,
                  child: Stack(
                    children: [
                      // Track
                      if (scrollConfig.showTrack)
                        Container(
                          width: scrollConfig.thickness,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
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
                          top: thumbPosition.isNaN ? 0 : thumbPosition,
                          height:
                              thumbHeight.isNaN
                                  ? height
                                  : thumbHeight.clamp(
                                    scrollConfig.minThumbLength,
                                    height,
                                  ),
                          width: scrollConfig.thickness,
                          right: 2,
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
