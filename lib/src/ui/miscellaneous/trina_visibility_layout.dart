import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:trina_grid/trina_grid.dart';

/// It is used to lay out the widgets
/// of [TrinaCell] or [TrinaColumn], [TrinaColumnGroup] of [TrinaRow]
/// or render only the widgets displayed according to the screen width.
class TrinaVisibilityLayout extends RenderObjectWidget
    implements MultiChildRenderObjectWidget {
  const TrinaVisibilityLayout({
    super.key,
    required this.children,
    required this.delegate,
    required this.scrollController,
    this.initialViewportDimension = 1920,
  });

  @override
  final List<TrinaVisibilityLayoutId> children;

  final MultiChildLayoutDelegate delegate;

  final ScrollController scrollController;

  /// When the viewportDimension of scrollPosition cannot be obtained in the first build stage,
  /// it is used instead of viewportDimension of scroll.
  final double initialViewportDimension;

  @override
  TrinaVisibilityLayoutRenderObjectElement createElement() =>
      TrinaVisibilityLayoutRenderObjectElement(
        widget: this,
        scrollController: scrollController,
        initialViewportDimension: initialViewportDimension,
      );

  @override
  RenderCustomMultiChildLayoutBox createRenderObject(BuildContext context) {
    return RenderCustomMultiChildLayoutBox(delegate: delegate);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderCustomMultiChildLayoutBox renderObject,
  ) {
    renderObject.delegate = delegate;
  }
}

class TrinaVisibilityLayoutRenderObjectElement extends RenderObjectElement
    implements MultiChildRenderObjectElement {
  TrinaVisibilityLayoutRenderObjectElement({
    required TrinaVisibilityLayout widget,
    required this.scrollController,
    this.initialViewportDimension = 1920,
  }) : assert(!debugChildrenHaveDuplicateKeys(widget, widget.children)),
       super(widget);

  final ScrollController scrollController;

  final double initialViewportDimension;

  @override
  ContainerRenderObjectMixin<
    RenderObject,
    ContainerParentDataMixin<RenderObject>
  >
  get renderObject {
    return super.renderObject
        as ContainerRenderObjectMixin<
          RenderObject,
          ContainerParentDataMixin<RenderObject>
        >;
  }

  @override
  @protected
  @visibleForTesting
  Iterable<Element> get children => _children.where((Element child) {
    return !_forgottenChildren.contains(child);
  });

  late List<Element> _children;

  final Set<Element> _forgottenChildren = HashSet<Element>();

  Iterable<TrinaVisibilityLayoutId> get _widgetChildren {
    return (widget as TrinaVisibilityLayout).children;
  }

  double get _visibleFirst => scrollController.offset;

  double get _visibleLast => _visibleFirst + _contentSize;

  double get _contentSize {
    return scrollController.position.hasViewportDimension == true
        ? scrollController.position.viewportDimension
        : initialViewportDimension;
  }

  void scrollListener() {
    markNeedsBuild();
  }

  bool visible({
    required double startOffset,
    required TrinaVisibilityLayoutChild layoutChild,
  }) {
    // Column is visible if it's within viewport OR kept alive (e.g. current cell)
    // Add a small epsilon for floating point precision and a buffer to ensure
    // columns at the very edge are rendered correctly.
    const double epsilon = 1.0e-10;
    const double buffer = 40.0;

    return layoutChild.keepAlive ||
        (startOffset < _visibleLast + buffer + epsilon &&
            startOffset + layoutChild.width > _visibleFirst - buffer - epsilon);
  }

  Element? findChildByLayoutId(Object layoutId) {
    return _children.firstWhereOrNull((element) {
      if (element.widget is TrinaVisibilityLayoutId) {
        return (element.widget as TrinaVisibilityLayoutId).id == layoutId;
      }
      return false;
    });
  }

  @override
  void performRebuild() {
    super.performRebuild();

    final visibleWidgets = <Widget>[];
    final slots = <IndexedSlot>[];

    Element? previousChild;
    double startOffset = 0;

    for (int i = 0; i < _widgetChildren.length; i += 1) {
      final child = _widgetChildren.elementAt(i);
      final layoutChild = child.layoutChild;
      final width = layoutChild.width;

      if (visible(startOffset: startOffset, layoutChild: layoutChild)) {
        final foundElement = findChildByLayoutId(child.id);

        visibleWidgets.add(child);
        slots.add(IndexedSlot<Element?>(i, previousChild));

        if (foundElement != null) {
          previousChild = foundElement;
        }
      }

      startOffset += width;
    }

    _children = updateChildren(
      _children,
      visibleWidgets,
      forgottenChildren: _forgottenChildren.isNotEmpty ? _forgottenChildren : null,
      slots: slots,
    );

    _forgottenChildren.clear();
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);

    scrollController.addListener(scrollListener);

    final List<Element> children = <Element>[];

    Element? previousChild;
    double startOffset = 0;

    for (int i = 0; i < _widgetChildren.length; i += 1) {
      final child = _widgetChildren.elementAt(i);
      final layoutChild = child.layoutChild;
      final width = layoutChild.width;

      if (visible(startOffset: startOffset, layoutChild: layoutChild)) {
        final Element newChild = inflateWidget(
          child,
          IndexedSlot<Element?>(i, previousChild),
        );
        children.add(newChild);
        previousChild = newChild;
      }

      startOffset += width;
    }

    _children = children;
  }

  @override
  void unmount() {
    super.unmount();

    scrollController.removeListener(scrollListener);
  }

  @override
  void update(TrinaVisibilityLayout newWidget) {
    super.update(newWidget);

    assert(widget == newWidget);

    assert(!debugChildrenHaveDuplicateKeys(widget, _widgetChildren));

    final List<Widget> visibleWidgets = [];
    final slots = <IndexedSlot>[];
    Element? previousChild;
    double startOffset = 0;

    for (int i = 0; i < _widgetChildren.length; i += 1) {
      final child = _widgetChildren.elementAt(i);
      final layoutChild = child.layoutChild;
      final width = layoutChild.width;

      if (visible(startOffset: startOffset, layoutChild: layoutChild)) {
        visibleWidgets.add(child);
        slots.add(IndexedSlot<Element?>(i, previousChild));

        final foundElement = findChildByLayoutId(child.id);
        if (foundElement != null) {
          previousChild = foundElement;
        }
      }

      startOffset += width;
    }

    _children = updateChildren(
      _children,
      visibleWidgets,
      forgottenChildren: _forgottenChildren.isNotEmpty ? _forgottenChildren : null,
      slots: slots,
    );

    _forgottenChildren.clear();
  }

  @override
  void insertRenderObjectChild(RenderObject child, IndexedSlot<Element?> slot) {
    final ContainerRenderObjectMixin<
      RenderObject,
      ContainerParentDataMixin<RenderObject>
    >
    renderObject = this.renderObject;
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child, after: slot.value?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void moveRenderObjectChild(
    RenderObject child,
    IndexedSlot<Element?> oldSlot,
    IndexedSlot<Element?> newSlot,
  ) {
    final ContainerRenderObjectMixin<
      RenderObject,
      ContainerParentDataMixin<RenderObject>
    >
    renderObject = this.renderObject;
    assert(child.parent == renderObject);
    renderObject.move(child, after: newSlot.value?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) {
    final ContainerRenderObjectMixin<
      RenderObject,
      ContainerParentDataMixin<RenderObject>
    >
    renderObject = this.renderObject;
    assert(child.parent == renderObject);
    renderObject.remove(child);
    assert(renderObject == this.renderObject);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (final Element child in _children) {
      if (!_forgottenChildren.contains(child)) visitor(child);
    }
  }

  @override
  void forgetChild(Element child) {
    assert(_children.contains(child));
    assert(!_forgottenChildren.contains(child));
    _forgottenChildren.add(child);
    super.forgetChild(child);
  }

  @override
  Element inflateWidget(Widget newWidget, Object? newSlot) {
    final Element newChild = super.inflateWidget(newWidget, newSlot);
    assert(_debugCheckHasAssociatedRenderObject(newChild));
    return newChild;
  }

  bool _debugCheckHasAssociatedRenderObject(Element newChild) {
    assert(() {
      if (newChild.renderObject == null) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary(
                'The children of `MultiChildRenderObjectElement` must each has an associated render object.',
              ),
              ErrorHint(
                'This typically means that the `${newChild.widget}` or its children\n'
                'are not a subtype of `RenderObjectWidget`.',
              ),
              newChild.describeElement(
                'The following element does not have an associated render object',
              ),
              DiagnosticsDebugCreator(DebugCreator(newChild)),
            ]),
          ),
        );
      }
      return true;
    }());
    return true;
  }
}

class TrinaVisibilityLayoutId extends LayoutId {
  TrinaVisibilityLayoutId({
    super.key,
    required super.id,
    required TrinaVisibilityLayoutChild super.child,
  });

  TrinaVisibilityLayoutChild get layoutChild =>
      child as TrinaVisibilityLayoutChild;
}

abstract class TrinaVisibilityLayoutChild implements Widget {
  double get width;

  double get startPosition;

  bool get keepAlive => false;
}

