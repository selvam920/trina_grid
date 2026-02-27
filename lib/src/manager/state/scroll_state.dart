import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

abstract class IScrollState {
  /// Controller to control the scrolling of the grid.
  TrinaGridScrollController get scroll;

  bool get isHorizontalOverScrolled;

  double get correctHorizontalOffset;

  Offset get directionalScrollEdgeOffset;

  Offset toDirectionalOffset(Offset offset);

  /// [direction] Scroll direction
  /// [offset] Scroll position
  void scrollByDirection(TrinaMoveDirection direction, double offset);

  /// Whether the cell can be scrolled when moving.
  bool canHorizontalCellScrollByDirection(
    TrinaMoveDirection direction,
    TrinaColumn columnToMove,
  );

  /// Scroll to [rowIdx] position.
  void moveScrollByRow(TrinaMoveDirection direction, int? rowIdx);

  /// Scroll to the row at [rowIdx].
  void scrollToRowIdx(int rowIdx, {bool animate = true});

  /// Scroll to [columnIdx] position.
  void moveScrollByColumn(TrinaMoveDirection direction, int? columnIdx);

  bool needMovingScroll(Offset offset, TrinaMoveDirection move);

  void updateCorrectScrollOffset();

  void updateScrollViewport();

  void resetScrollToZero();
}

mixin ScrollState implements ITrinaGridState {
  @override
  bool get isHorizontalOverScrolled =>
      scroll.bodyRowsHorizontal!.offset > scroll.maxScrollHorizontal ||
      scroll.bodyRowsHorizontal!.offset < 0;

  @override
  double get correctHorizontalOffset {
    if (isHorizontalOverScrolled) {
      return scroll.horizontalOffset < 0 ? 0 : scroll.maxScrollHorizontal;
    }

    return scroll.horizontalOffset;
  }

  @override
  Offset get directionalScrollEdgeOffset =>
      isLTR ? Offset.zero : Offset(gridGlobalOffset!.dx, 0);

  @override
  Offset toDirectionalOffset(Offset offset) {
    if (isLTR) {
      return offset;
    }

    return Offset((maxWidth! + gridGlobalOffset!.dx) - offset.dx, offset.dy);
  }

  @override
  void scrollByDirection(TrinaMoveDirection direction, double offset) {
    if (direction.vertical) {
      scroll.vertical!.jumpTo(offset);
    } else {
      scroll.horizontal!.jumpTo(offset);
    }
  }

  @override
  bool canHorizontalCellScrollByDirection(
    TrinaMoveDirection direction,
    TrinaColumn columnToMove,
  ) {
    // When the frozen column is visible, the column to move is a frozen column, the scrolling is unnecessary.
    return !(showFrozenColumn == true && columnToMove.frozen.isFrozen);
  }

  @override
  void moveScrollByRow(TrinaMoveDirection direction, int? rowIdx) {
    if (!direction.vertical) {
      return;
    }

    final int newRowIdx = direction.isUp ? rowIdx! - 1 : rowIdx! + 1;

    if (newRowIdx < 0 || newRowIdx >= refRows.length) {
      return;
    }

    // Use scrollToRowIdx which has better alignment and viewport calculation.
    // For manual navigation (arrow keys), jump immediately for better responsiveness.
    scrollToRowIdx(newRowIdx, animate: false);
  }

  @override
  void scrollToRowIdx(int rowIdx, {bool animate = true}) {
    if (rowIdx < 0 || rowIdx >= refRows.length) {
      return;
    }

    if (maxHeight == null ||
        scroll.vertical == null ||
        !scroll.vertical!.hasAttachedControllers) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToRowIdx(rowIdx, animate: animate);
      });
      return;
    }

    double totalOffset = 0.0;
    for (int i = 0; i < rowIdx; i++) {
      totalOffset +=
          getRowHeight(i) + configuration.style.cellHorizontalBorderWidth;
    }

    final double rowTotalHeight =
        getRowHeight(rowIdx) + configuration.style.cellHorizontalBorderWidth;

    final double rowBottomOffset = totalOffset + rowTotalHeight;

    final double viewportHeight =
        maxHeight! - rowsTopOffset - footerHeight - columnFooterHeight;

    final double viewportTopOffset = scroll.verticalOffset;
    final double viewportBottomOffset = viewportTopOffset + viewportHeight;

    if (totalOffset < viewportTopOffset) {
      // Row is above the viewport, scroll up to bring its top to the top of the viewport
      if (animate) {
        scroll.vertical!.animateTo(
          totalOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        scroll.vertical!.jumpTo(totalOffset);
      }
    } else if (rowBottomOffset > viewportBottomOffset) {
      // Row is below the viewport, scroll down to bring its bottom to the bottom of the viewport
      double targetOffset = rowBottomOffset - viewportHeight;

      // For the last row, ensure we scroll to the extreme end to trigger scroll listeners
      if (rowIdx == refRows.length - 1 &&
          scroll.bodyRowsVertical != null &&
          scroll.bodyRowsVertical!.hasClients) {
        targetOffset = math.max(
          targetOffset,
          scroll.bodyRowsVertical!.position.maxScrollExtent,
        );
      }

      if (animate) {
        scroll.vertical!.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        scroll.vertical!.jumpTo(targetOffset);
      }
    }
  }

  @override
  void moveScrollByColumn(TrinaMoveDirection direction, int? columnIdx) {
    if (!direction.horizontal) {
      return;
    }

    final columnIndexes = columnIndexesByShowFrozen;

    final TrinaColumn columnToMove =
        refColumns[columnIndexes[columnIdx! + direction.offset]];

    if (!canHorizontalCellScrollByDirection(direction, columnToMove)) {
      return;
    }

    double offsetToMove = columnToMove.startPosition;

    final double? screenOffset = showFrozenColumn == true
        ? maxWidth! - leftFrozenColumnsWidth - rightFrozenColumnsWidth
        : maxWidth;

    if (direction.isRight) {
      if (offsetToMove > scroll.horizontal!.offset) {
        offsetToMove -= screenOffset!;
        offsetToMove += columnToMove.width;
        offsetToMove += scrollOffsetByFrozenColumn;

        if (offsetToMove < scroll.horizontal!.offset) {
          return;
        }
      }
    } else {
      final offsetToNeed = offsetToMove + columnToMove.width;

      final currentOffset = screenOffset! + scroll.horizontal!.offset;

      if (offsetToNeed > currentOffset) {
        offsetToMove = scroll.horizontal!.offset + offsetToNeed - currentOffset;
        offsetToMove += scrollOffsetByFrozenColumn;
      } else if (offsetToMove > scroll.horizontal!.offset) {
        return;
      }
    }

    scrollByDirection(direction, offsetToMove);
  }

  @override
  bool needMovingScroll(Offset? offset, TrinaMoveDirection move) {
    if (selectingMode.isNone) {
      return false;
    }

    switch (move) {
      case TrinaMoveDirection.left:
        return offset!.dx < bodyLeftScrollOffset;
      case TrinaMoveDirection.right:
        return offset!.dx > bodyRightScrollOffset;
      case TrinaMoveDirection.up:
        return offset!.dy < bodyUpScrollOffset;
      case TrinaMoveDirection.down:
        return offset!.dy > bodyDownScrollOffset;
    }
  }

  @override
  void updateCorrectScrollOffset() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (scroll.bodyRowsHorizontal?.hasClients != true) {
        return;
      }

      if (isHorizontalOverScrolled) {
        scroll.horizontal!.animateTo(
          correctHorizontalOffset,
          curve: Curves.ease,
          duration: const Duration(milliseconds: 300),
        );
      }
    });
  }

  @override
  void updateScrollViewport() {
    if (maxWidth == null ||
        scroll.bodyRowsHorizontal?.position.hasViewportDimension != true) {
      return;
    }

    double bodyWidth = maxWidth! - bodyLeftOffset - bodyRightOffset;

    scroll.horizontal!.applyViewportDimension(bodyWidth);

    updateCorrectScrollOffset();
  }

  /// Called to fix an error
  /// that the screen cannot be touched due to an incorrect scroll range
  /// when resizing the screen.
  @override
  void resetScrollToZero() {
    if ((scroll.bodyRowsVertical?.offset ?? 0) <= 0) {
      scroll.bodyRowsVertical?.jumpTo(0);
    }

    if ((scroll.bodyRowsHorizontal?.offset ?? 0) <= 0) {
      scroll.bodyRowsHorizontal?.jumpTo(0);
    }
  }
}
