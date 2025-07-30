import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mockito/annotations.dart';
import 'package:trina_grid/trina_grid.dart';

@GenerateNiceMocks([
  MockSpec<TrinaGridStateManager>(),
  MockSpec<TrinaGridEventManager>(),
  MockSpec<TrinaGridScrollController>(),
  MockSpec<TrinaGridKeyPressed>(),
  MockSpec<LinkedScrollControllerGroup>(),
  MockSpec<ScrollController>(),
  MockSpec<ScrollPosition>(),
  MockSpec<StreamSubscription>(),
  MockSpec<FocusNode>(),
])
void main() {}
