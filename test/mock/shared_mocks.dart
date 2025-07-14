import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mockito/annotations.dart';
import 'package:trina_grid/trina_grid.dart';
import 'package:trina_grid/src/manager/trina_cell_merge_manager.dart';

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
  MockSpec<TrinaCellMergeManager>(),
])
void main() {}
