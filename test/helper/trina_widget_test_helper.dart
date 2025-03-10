import 'package:flutter_test/flutter_test.dart';

typedef TrinaWidgetTestContext = Future<void> Function(
  String description,
  Function(WidgetTester tester) callback,
);

typedef TrinaWidgetTestCallback = Future<void> Function(WidgetTester tester);

class TrinaWidgetTestHelper {
  TrinaWidgetTestHelper(
    String description,
    WidgetTesterCallback testContext,
  ) {
    _setTestContext(description, testContext);
  }

  late TrinaWidgetTestContext _testContext;

  void _setTestContext(
      String contextDescription, WidgetTesterCallback testContext) {
    _testContext =
        (String testDescription, Function(WidgetTester tester) callback) async {
      group(contextDescription, () {
        testWidgets(testDescription, (WidgetTester tester) async {
          await testContext(tester);
          await tester.pumpAndSettle();
          await callback(tester);
          await tester.pumpAndSettle();
        });
      });
    };
  }

  void test(String description, TrinaWidgetTestCallback widgetTest) async {
    await _testContext(description, (tester) async {
      await widgetTest(tester);
    });
  }
}
