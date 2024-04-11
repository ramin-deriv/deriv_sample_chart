import 'package:flutter/material.dart';
import 'models.dart';

/// Conversion function to convert time value to canvas X.
typedef TimeToX = double Function(int);

/// Conversion function to convert value to canvas Y.
typedef ValueToY = double Function(double);

/// Any component that can be painted on the Chart's canvas.
abstract class Component {
  /// The ID of this [Component].
  ///
  /// [id] is used to recognize an old [Component] with its new state after
  /// chart being updated. Doing so makes the chart able to perform live update
  /// animation.
  String get id;

  /// Will be called by the chart when it was updated.
  ///
  /// Returns `true` if this chart data has changed with the chart
  /// widget update.
  bool didUpdate(Component olcComponent);

  /// Checks if this [Component] needs to repaint with the chart widget's
  ///  new frame.
  bool shouldRepaint(Component oldComponent);

  /// Updates this [Component] after tye chart's time boundaries changes.
  void update(int leftBoundTime, int rightBoundTime);

  /// The minimum value this [Component] has at the current X-Axis time range
  /// after [update] is called.
  ///
  /// [double.nan] should be returned if this [Component] doesn't have any
  /// element to have a minimum value.
  double get minValue;

  /// The maximum value this [Component] has at the current X-Axis time range
  /// after [update] is called.
  ///
  /// [double.nan] should be returned if this [Component] doesn't have any
  /// element to have a maximum value.
  double get maxValue;

  /// Minimum epoch of this [Component] on the chart's X-Axis.
  ///
  /// The chart calls this on any of its [Component]s and gets their minimum
  /// epoch then sets its X-Axis leftmost scroll limit based on them.
  int? getMinTime();

  /// Maximum time of this [Component] on the chart's X-Axis.
  ///
  /// The chart uses it same as [getMinTime] to determine its rightmost scroll
  /// limit.
  int? getMaxTime();

  /// Paints this [Component] on the given [canvas].
  ///
  /// [Size] is the size of the [canvas].
  ///
  /// [timeToX] and [valueToY] are conversion functions in the chart's
  /// coordinate system. They respectively convert time to canvas X and value
  /// to canvas Y.
  ///
  /// [animationInfo] Contains animations progress values in this frame of
  /// painting.
  ///
  /// [ChartConfig] is the chart's config.
  void paint(
    Canvas canvas,
    Size size,
    TimeToX timeToX,
    ValueToY valueToY,
    AnimationInfo animationInfo,
    ChartConfig chartConfig,
  );
}
