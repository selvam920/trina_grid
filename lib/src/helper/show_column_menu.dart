import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

abstract class TrinaColumnMenuDelegate<T> {
  List<PopupMenuEntry<T>> buildMenuItems({
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
  });

  void onSelected({
    required BuildContext context,
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
    required bool mounted,
    required T? selected,
  });
}

class TrinaColumnMenuDelegateDefault
    implements TrinaColumnMenuDelegate<TrinaGridColumnMenuItem> {
  const TrinaColumnMenuDelegateDefault();

  @override
  List<PopupMenuEntry<TrinaGridColumnMenuItem>> buildMenuItems({
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
  }) {
    return _getDefaultColumnMenuItems(
      stateManager: stateManager,
      column: column,
    );
  }

  @override
  void onSelected({
    required BuildContext context,
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
    required bool mounted,
    required TrinaGridColumnMenuItem? selected,
  }) {
    switch (selected) {
      case TrinaGridColumnMenuItem.unfreeze:
        stateManager.toggleFrozenColumn(column, TrinaColumnFrozen.none);
        break;
      case TrinaGridColumnMenuItem.freezeToStart:
        stateManager.toggleFrozenColumn(column, TrinaColumnFrozen.start);
        break;
      case TrinaGridColumnMenuItem.freezeToEnd:
        stateManager.toggleFrozenColumn(column, TrinaColumnFrozen.end);
        break;
      case TrinaGridColumnMenuItem.autoFit:
        if (!mounted) return;
        stateManager.autoFitColumn(context, column);
        stateManager.notifyResizingListeners();
        break;
      case TrinaGridColumnMenuItem.hideColumn:
        stateManager.hideColumn(column, true);
        break;
      case TrinaGridColumnMenuItem.setColumns:
        if (!mounted) return;
        stateManager.showSetColumnsPopup(context);
        break;
      case TrinaGridColumnMenuItem.setFilter:
        if (!mounted) return;
        stateManager.showFilterPopup(context, calledColumn: column);
        break;
      case TrinaGridColumnMenuItem.resetFilter:
        stateManager.setFilter(null);
        break;
      default:
        break;
    }
  }
}

/// Open the context menu on the right side of the column.
Future<T?>? showColumnMenu<T>({
  required BuildContext context,
  required Offset position,
  required List<PopupMenuEntry<T>> items,
  Color backgroundColor = Colors.white,
}) {
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;

  return showMenu<T>(
    context: context,
    color: backgroundColor,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx + overlay.size.width,
      position.dy + overlay.size.height,
    ),
    items: items,
    useRootNavigator: true,
  );
}

List<PopupMenuEntry<TrinaGridColumnMenuItem>> _getDefaultColumnMenuItems({
  required TrinaGridStateManager stateManager,
  required TrinaColumn column,
}) {
  final Color textColor = stateManager.style.cellTextStyle.color!;

  final Color disableTextColor = textColor.withAlpha((0.5 * 255).toInt());

  final bool enoughFrozenColumnsWidth = stateManager.enoughFrozenColumnsWidth(
    stateManager.maxWidth! - column.width,
  );

  final localeText = stateManager.localeText;

  return [
    if (column.frozen.isFrozen == true)
      _buildMenuItem(
        value: TrinaGridColumnMenuItem.unfreeze,
        text: localeText.unfreezeColumn,
        textColor: textColor,
      ),
    if (column.frozen.isFrozen != true) ...[
      _buildMenuItem(
        value: TrinaGridColumnMenuItem.freezeToStart,
        enabled: enoughFrozenColumnsWidth,
        text: localeText.freezeColumnToStart,
        textColor: enoughFrozenColumnsWidth ? textColor : disableTextColor,
      ),
      _buildMenuItem(
        value: TrinaGridColumnMenuItem.freezeToEnd,
        enabled: enoughFrozenColumnsWidth,
        text: localeText.freezeColumnToEnd,
        textColor: enoughFrozenColumnsWidth ? textColor : disableTextColor,
      ),
    ],
    const PopupMenuDivider(),
    _buildMenuItem(
      value: TrinaGridColumnMenuItem.autoFit,
      text: localeText.autoFitColumn,
      textColor: textColor,
    ),
    if (column.enableHideColumnMenuItem == true)
      _buildMenuItem(
        value: TrinaGridColumnMenuItem.hideColumn,
        text: localeText.hideColumn,
        textColor: textColor,
        enabled: stateManager.refColumns.length > 1,
      ),
    if (column.enableSetColumnsMenuItem == true)
      _buildMenuItem(
        value: TrinaGridColumnMenuItem.setColumns,
        text: localeText.setColumns,
        textColor: textColor,
      ),
    if (column.enableFilterMenuItem == true) ...[
      const PopupMenuDivider(),
      _buildMenuItem(
        value: TrinaGridColumnMenuItem.setFilter,
        text: localeText.setFilter,
        textColor: textColor,
      ),
      _buildMenuItem(
        value: TrinaGridColumnMenuItem.resetFilter,
        text: localeText.resetFilter,
        textColor: textColor,
        enabled: stateManager.hasFilter,
      ),
    ],
  ];
}

PopupMenuItem<TrinaGridColumnMenuItem> _buildMenuItem<TrinaGridColumnMenuItem>({
  required String text,
  required Color? textColor,
  bool enabled = true,
  TrinaGridColumnMenuItem? value,
}) {
  return PopupMenuItem<TrinaGridColumnMenuItem>(
    value: value,
    height: 36,
    enabled: enabled,
    child: Text(
      text,
      style: TextStyle(
        color: enabled ? textColor : textColor!.withAlpha((0.5 * 255).toInt()),
        fontSize: 13,
      ),
    ),
  );
}

/// Items in the context menu on the right side of the column
enum TrinaGridColumnMenuItem {
  unfreeze,
  freezeToStart,
  freezeToEnd,
  hideColumn,
  setColumns,
  autoFit,
  setFilter,
  resetFilter,
}
