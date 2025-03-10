# Changelog

## [1.4.13] - 2025. 03. 10

* Added cell-level renderer support with TrinaCellRenderer

## [1.4.12] - 2025. 03. 10

* fix incase frozen columns & frozen rows
* Enhance the readme texts

## [1.4.11] - 2025. 03. 10

* Introducing Frozen Rows

## [1.4.10] - 2025. 03. 08

* Translate all korean comments & unit tests to english

## [1.4.9] - 2025. 03. 06

* Added scrollToColumn method

## [1.4.8] - 2025. 03. 06

* Added getVisibleColumns method & isColumnVisible

## [1.4.7] - 2025. 03. 04

* Fix pagination bug

## [1.4.6] - 2025. 03. 04

* Remove Stratagy pattern from the pagination widget and simplify the code
* Add total records
* Enhance the ui of the pagination widget

## [1.4.5] - 2025. 03. 01

* add initialPageSize to PageSizeDropdownTrinaLazyPaginationStrategy and default pageSizeToMove to 1
* Fix pagination bug

## [1.4.4] - 2025. 03. 01

* Added pagesize dropdown using strategy pattern
* Upgraded to latest Flutter version
* Used intl any version for compatibility
* Added onClear and clearIcon parameters to filter widgets
* Added filterWidgetDelegate to TrinaColumn
* Added missing filterWidgetBuilder and onFilterSuffixTap parameters
* Updated GitHub Actions tests
* Added optional width parameter to column in TrinaColumnType.select
* Added ability to disable row checkbox under specific conditions
* Fixed issue #105
* Added clear columns filter event
* Added empty screen to homepage
* Added VS Code formatting restrictions
* Fixed unit tests
* Added guard against missing scroll client (when disposed)
* Improved row wrapper implementation
* Changed WidgetBuilder to Widget Function(BuildContext, Widget)
* Enhanced infinity scroll to continue updating if screen not filled
* Fixed homescreen pointing to old package
* Implemented ability to disable row checkbox under conditions
* Added handling for pure checkbox values when disabled
* Added null check to prevent 'Null check operator used on a null value' exception
* Updated intl library to ^0.20.0
* Added onActiveCellChanged event

## [1.4.3] - 2024. 10. 23

* Added rowWrapper & editCellWrapper for the state manager
* Manually detect doubleTaps on desktop platform to eliminate delay
* Several improvements
* Add TrinaGridRowSelectionCheckBehavior which enables automatically setting the CheckBox values of selected rows
* Add TrinaGridRowSelectionCheckBehavior
* Upgrade packages

## [1.4.2] - 2024. 07. 15

* add rowWrapper
* Added an option for developers to use either the standard Material DatePicker or a custom datepicker.
* Datepicker - moved isOpenedPopup = true
* Added the ability to add a custom data property at the row level. For example: you can pass data to onSelect or any other onHandler. (not required)
* Upgrade some used package to the latest version.

## [1.4.1] - 2024. 05. 15

upgrade for flutter 3.22.0

## [1.4.0] - 2024. 04. 01

* Added onRowEnter, onRowExit callbacks to react on. @coruscant187
* Added logic to change background color of row if hovered. @coruscant187 doonfrs/trina_grid#29

## [1.3.1] - 2024. 03. 19

* upgrade packages to latest major version
