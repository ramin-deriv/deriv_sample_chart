import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:deriv_sample_chart/src/models.dart';

import 'components.dart';

const annotationWidth = 30;
const annotationHeight = 14;

class Annotation extends Component {
  Annotation(this.tick);

  bool _isOnRange = false;
  Tick? _prevTick;
  final Tick tick;

  @override
  bool didUpdate(covariant Annotation olcComponent) {
    _prevTick = olcComponent.tick;
    return true;
  }

  @override
  int? getMaxTime() => tick.time;

  @override
  int? getMinTime() => tick.time;

  @override
  String get id => 'Annotation';

  @override
  double get maxValue => _isOnRange ? tick.value : double.nan;

  @override
  double get minValue => _isOnRange ? tick.value : double.nan;

  Paint _paint = Paint()..color = Colors.deepOrangeAccent;

  @override
  void paint(
    Canvas canvas,
    Size size,
    TimeToX timeToX,
    ValueToY valueToY,
    AnimationInfo animationInfo,
    ChartConfig chartConfig,
  ) {
    if (!_isOnRange) return;
    
    late Offset tickAnimatedPosition;

    if (_prevTick != null) {
      final x = lerpDouble(
        timeToX(_prevTick!.time),
        timeToX(tick.time),
        animationInfo.currentTickPercent,
      )!;
      final y = lerpDouble(
        valueToY(_prevTick!.value),
        valueToY(tick.value),
        animationInfo.currentTickPercent,
      )!;

      tickAnimatedPosition = Offset(x, y);
    } else {
      tickAnimatedPosition = Offset(timeToX(tick.time), valueToY(tick.value));
    }

    canvas.drawCircle(tickAnimatedPosition, 3, _paint);
    canvas.drawLine(
      tickAnimatedPosition,
      Offset(size.width, tickAnimatedPosition.dy),
      _paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
            size.width - annotationWidth,
            tickAnimatedPosition.dy - annotationHeight / 2,
            size.width,
            tickAnimatedPosition.dy + annotationHeight / 2),
        Radius.circular(4),
      ),
      _paint,
    );
  }

  @override
  bool shouldRepaint(Component oldComponent) => true;

  @override
  void update(int leftBoundTime, int rightBoundTime) {
    _isOnRange = tick.time < rightBoundTime && tick.time > leftBoundTime;
  }
}
