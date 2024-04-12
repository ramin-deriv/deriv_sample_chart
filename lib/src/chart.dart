import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_financial_chart/src/components.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter_financial_chart/src/helpers.dart';
import 'models.dart';

class ChartWidget extends StatefulWidget {
  const ChartWidget({
    required this.mainComponent,
    this.components = const [],
    super.key,
  });

  final Component mainComponent;
  final List<Component> components;

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget>
    with TickerProviderStateMixin {
  late final AnimationController _updateController;
  late final AnimationController _rightBoundController;
  late final AnimationController _topValueController;
  late final AnimationController _bottomValueController;

  late int _rightBoundTime;

  Size? _chartSize;
  double _msPerPx = 500;
  double _prevMsPerPx = 500;

  double _timeToX(int time) {
    final leftBoundTime = _rightBoundTime - _chartSize!.width * _msPerPx;
    return (time - leftBoundTime) /
        (_rightBoundTime - leftBoundTime) *
        (_chartSize!.width);
  }

  double _valueToY(double value) {
    const topPadding = 300;
    const bottomPadding = 300;
    final double drawingRange =
        _chartSize!.height - (topPadding + bottomPadding);
    final double quoteRange =
        _topValueController.value - _bottomValueController.value;

    if (quoteRange == 0) {
      return topPadding + drawingRange / 2;
    }

    final double valueToBottomFraction =
        (value - _bottomValueController.value) / quoteRange;
    final double valueToTopFraction = 1 - valueToBottomFraction;

    final double pxFromTop = valueToTopFraction * drawingRange;

    return topPadding + pxFromTop;
  }

  int xToTime(double x) {
    final int leftBoundTime =
        (_rightBoundTime - _chartSize!.width * _msPerPx).toInt();

    return (x * (_rightBoundTime - leftBoundTime) / _chartSize!.width +
            leftBoundTime)
        .toInt();
  }

  @override
  void initState() {
    super.initState();

    _updateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _topValueController = AnimationController.unbounded(vsync: this, value: 10);
    _bottomValueController = AnimationController.unbounded(
      vsync: this,
      value: 0,
      duration: const Duration(milliseconds: 300),
    );
    _rightBoundController = AnimationController.unbounded(
      vsync: this,
      value: DateTime.now().millisecondsSinceEpoch.toDouble(),
      duration: const Duration(milliseconds: 300),
    );

    _rightBoundTime = _rightBoundController.value.toInt();
  }

  @override
  void didUpdateWidget(covariant ChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.mainComponent.id == oldWidget.mainComponent.id) {
      widget.mainComponent.didUpdate(oldWidget.mainComponent);
    }

    for (final Component data in widget.components.where(
      // Exclude mainSeries, since its didUpdate is already called
      (Component c) => c.id != widget.mainComponent.id,
    )) {
      final Component? oldData = oldWidget.components.firstWhereOrNull(
        (Component c) => c.id == data.id,
      );

      if (oldData != null) {
        data.didUpdate(oldData);
      }
    }

    _updateController.reset();
    _updateController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      _chartSize = Size(constraints.maxWidth, constraints.maxHeight);
      return AnimatedBuilder(
          animation: _rightBoundController,
          builder: (_, __) {
            _updateVisibleData();
            _updateTopBottomValue();

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (details) {
                setState(() {});
                // _rightBoundController.value = _sharedRange.rightXAxisValue.toDouble();
              },
              onHorizontalDragUpdate: (details) {
                _rightBoundController.value -= details.delta.dx * _msPerPx;
              },
              onHorizontalDragEnd: (details) {
                final maxTime = widget.mainComponent.getMaxTime() ??
                    DateTime.now().millisecondsSinceEpoch;

                final double velocity =
                    -details.velocity.pixelsPerSecond.dx * _msPerPx;
                final double maxRightTime =
                    xToTime(_timeToX(maxTime) + 100).toDouble();

                final scrollSimulation = BoundedFrictionSimulation(
                  0.05,
                  _rightBoundController.value.clamp(0, maxRightTime),
                  velocity,
                  0,
                  maxRightTime,
                );
                _rightBoundController.animateWith(scrollSimulation);
              },
              onScaleStart: (details) => setState(() {
                _prevMsPerPx = _msPerPx;
              }),
              onScaleUpdate: (details) {
                _msPerPx = _prevMsPerPx / details.scale;
                setState(() {});
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MultipleAnimatedBuilder(
                      animations: [
                        _updateController,
                        _topValueController,
                        _bottomValueController,
                      ],
                      builder: (_, __) {
                        return CustomPaint(
                          painter: ChartPainter(
                            components: [
                              widget.mainComponent,
                              ...widget.components
                            ],
                            timeToX: _timeToX,
                            valueToY: _valueToY,
                            animationInfo: AnimationInfo(
                              currentTickPercent: _updateController.value,
                            ),
                          ),
                        );
                      })
                ],
              ),
            );
          });
    });
  }

  void _updateVisibleData() {
    _clampRightBoundTime();

    final leftBoundTime =
        (_rightBoundTime - _chartSize!.width * _msPerPx).toInt();

    widget.mainComponent.update(leftBoundTime, _rightBoundTime);
    for (final c in widget.components) {
      c.update(leftBoundTime, _rightBoundTime);
    }
  }

  void _clampRightBoundTime() {
    final int? maxTime = widget.mainComponent.getMaxTime();

    if (maxTime != null) {
      _rightBoundTime = _rightBoundController.value
          .clamp(
            0,
            xToTime(_timeToX(maxTime) + 60),
          )
          .toInt();
    }
  }

  void _updateTopBottomValue() {
    double minValue =
        [widget.mainComponent, ...widget.components].getMinValue();

    double maxValue =
        [widget.mainComponent, ...widget.components].getMaxValue();

    // If the minQuote and maxQuote are the same there should be a default state
    // to show chart quotes.
    if (minValue == maxValue) {
      minValue -= 2;
      maxValue += 2;
    }

    _bottomValueController.animateTo(
      minValue,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
    );
    _topValueController.animateTo(
      maxValue,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
    );
  }
}

class ChartPainter extends CustomPainter {
  ChartPainter({
    required this.components,
    required this.timeToX,
    required this.valueToY,
    required this.animationInfo,
  });

  final List<Component> components;
  final TimeToX timeToX;
  final ValueToY valueToY;
  final AnimationInfo animationInfo;

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in components) {
      c.paint(canvas, size, timeToX, valueToY, animationInfo, ChartConfig());
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // As this is a sample package doesn't include performance optimization yet.
    return true;
  }
}
