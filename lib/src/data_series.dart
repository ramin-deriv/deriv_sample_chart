import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'components.dart';
import 'models.dart';

class DataSeries<T extends Tick> extends Component {
  DataSeries(this.ticks, {this.dataSeriesId = 'DATASERIES'});

  final String dataSeriesId;

  @override
  String get id => dataSeriesId;

  final Paint _paint = Paint()
    ..color = Colors.blueAccent
    ..style = PaintingStyle.stroke;

  Tick? _prevLastEntry;

  final List<Tick> ticks;
  List<Tick> _visibleTicks = [];

  @override
  bool didUpdate(covariant DataSeries oldComponent) {
    if (oldComponent.ticks.isNotEmpty) _prevLastEntry = oldComponent.ticks.last;
    return true;
  }

  @override
  int? getMaxTime() {
    if (ticks.isNotEmpty) return ticks.last.time;
    return null;
  }

  @override
  int? getMinTime() {
    if (ticks.isNotEmpty) return ticks.first.time;
    return null;
  }

  @override
  double get maxValue =>
      _visibleTicks.isEmpty ? 1 : _visibleTicks.map((e) => e.value).reduce(max);

  @override
  double get minValue =>
      _visibleTicks.isEmpty ? 0 : _visibleTicks.map((e) => e.value).reduce(min);

  int _searchLowerIndex(int leftBoundTime) {
    if (ticks.isEmpty || leftBoundTime < ticks.first.time) {
      return 0;
    }

    if (leftBoundTime > ticks[ticks.length - 1].time) {
      return -1;
    }

    int lo = 0;
    int hi = ticks.length - 1;

    while (lo <= hi) {
      int mid = (hi + lo) ~/ 2;

      if (leftBoundTime < ticks[mid].time) {
        hi = mid - 1;
      } else if (leftBoundTime > ticks[mid].time) {
        lo = mid + 1;
      } else {
        return mid;
      }
    }

    // lo == hi + 1
    final closest = (ticks[lo].time) < (ticks[hi].time) ? lo : hi;
    final index = closest <= leftBoundTime
        ? closest
        : closest - 1 < 0
            ? closest
            : closest - 1;
    return index - 1 < 0 ? index : index - 1;
  }

  int _searchUpperIndex(int rightBoundTime) {
    if (ticks.isEmpty || rightBoundTime < ticks.first.time) {
      return -1;
    }
    if (rightBoundTime > ticks[ticks.length - 1].time) {
      return ticks.length;
    }

    int lo = 0;
    int hi = ticks.length - 1;

    while (lo <= hi) {
      int mid = (hi + lo) ~/ 2;

      if (rightBoundTime < ticks[mid].time) {
        hi = mid - 1;
      } else if (rightBoundTime > ticks[mid].time) {
        lo = mid + 1;
      } else {
        return mid;
      }
    }

    // lo == hi + 1
    final closest =
        (ticks[lo].time - rightBoundTime) < (rightBoundTime - ticks[hi].time)
            ? lo
            : hi;

    int index = closest >= rightBoundTime
        ? closest
        : (closest + 1 > ticks.length ? closest : closest + 1);
    return index == ticks.length ? index : index + 1;
  }

  @override
  void paint(
    Canvas canvas,
    Size size,
    TimeToX timeToX,
    ValueToY valueToY,
    AnimationInfo animationInfo,
    ChartConfig chartConfig,
  ) {
    if (_visibleTicks.length < 2) {
      return;
    }

    final Path path = Path();

    bool movedToStartPoint = false;

    for (int i = 0; i < _visibleTicks.length - 1; i++) {
      final tick = _visibleTicks[i];
      if (tick.value.isNaN) continue;

      if (!movedToStartPoint) {
        movedToStartPoint = true;
        path.moveTo(timeToX(tick.time), valueToY(tick.value));
        continue;
      }

      final x = timeToX(tick.time);
      final y = valueToY(tick.value);
      path.lineTo(x, y);
    }


    final lastPos = _addLastVisibleTick(timeToX, valueToY, animationInfo, path);
    canvas.drawPath(path, _paint);

    _drawArea(
      canvas,
      size,
      linePath: path,
      lineEndX: lastPos!.dx,
    );
  }

  Offset? _addLastVisibleTick(
    TimeToX timeToX,
    ValueToY valueToY,
    AnimationInfo animationInfo,
    ui.Path path,
  ) {
    final Tick lastTick = ticks.last;
    final Tick lastVisibleTick = _visibleTicks.last;
    Offset? lastVisibleTickPosition;

    if (lastTick == lastVisibleTick && _prevLastEntry != null) {
      final double tickX = ui.lerpDouble(
        timeToX(_prevLastEntry!.time),
        timeToX(lastTick.time),
        animationInfo.currentTickPercent,
      )!;

      final double tickY = valueToY(ui.lerpDouble(
        _prevLastEntry!.value,
        lastTick.value,
        animationInfo.currentTickPercent,
      )!);

      lastVisibleTickPosition = Offset(tickX, tickY);
    } else {
      lastVisibleTickPosition = Offset(
        timeToX(lastVisibleTick.time),
        valueToY(lastVisibleTick.value),
      );
    }

    path.lineTo(lastVisibleTickPosition.dx, lastVisibleTickPosition.dy);

    return lastVisibleTickPosition;
  }

  void _drawArea(
    Canvas canvas,
    Size size, {
    required Path linePath,
    required double lineEndX,
  }) {
    final areaPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [
          Colors.blue.withOpacity(0.3),
          Colors.blue.withOpacity(0.01),
        ],
      );

    linePath.lineTo(
      lineEndX,
      size.height,
    );

    linePath.lineTo(0, size.height);

    canvas.drawPath(
      linePath,
      areaPaint,
    );
  }

  @override
  bool shouldRepaint(Component oldData) {
    // Since this is a sample package.
    return true;
  }

  @override
  void update(int leftBoundTime, int rightBoundTime) {
    final startIndex = _searchLowerIndex(leftBoundTime);
    final endIndex = _searchUpperIndex(rightBoundTime);

    _visibleTicks = startIndex == -1 || endIndex == -1
        ? []
        : ticks.sublist(startIndex, endIndex);
  }
}
