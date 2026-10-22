import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show SingleActivator;
import 'package:flutter_test/flutter_test.dart';
import 'package:trina_grid/trina_grid.dart';

/// The fork leaves F2-F4 out of the default shortcuts: the host app binds the
/// function keys to page actions (Save F1, Print F2, Edit F3...), and a grid
/// that swallowed them would steal those keys whenever it had focus.
void main() {
  test('F2, F3 and F4 are not default grid shortcuts', () {
    for (final key in [
      LogicalKeyboardKey.f2,
      LogicalKeyboardKey.f3,
      LogicalKeyboardKey.f4,
    ]) {
      expect(
        TrinaGridShortcut.defaultActions.keys.whereType<SingleActivator>().any(
          (a) => a.trigger == key,
        ),
        isFalse,
        reason: '${key.keyLabel} must stay free for the host app',
      );
    }
  });
}
