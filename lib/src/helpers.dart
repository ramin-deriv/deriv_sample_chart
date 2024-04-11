import 'dart:math';

import 'package:flutter/material.dart';

import 'components.dart';

/// An extension on Iterable with [Component] elements.
extension ChartDataListExtension on Iterable<Component?> {
  /// Gets the minimum of [Component.getMinTime]s.
  int? getMinEpoch() => _getEpochWithPredicate(
      (Component c) => c.getMinTime(), (int a, int b) => min<int>(a, b));

  /// Gets the maximum of [Component.getMaxTime]s.
  int? getMaxEpoch() => _getEpochWithPredicate(
      (Component c) => c.getMaxTime(), (int a, int b) => max<int>(a, b));

  int? _getEpochWithPredicate(
    int? Function(Component) getEpoch,
    int Function(int, int) epochComparator,
  ) {
    final Iterable<int?> maxEpochs = where((Component? c) => c != null)
        .map((Component? c) => getEpoch(c!))
        .where((int? epoch) => epoch != null);

    return maxEpochs.isNotEmpty
        ? maxEpochs.reduce(
            (int? current, int? next) => epochComparator(current!, next!),
          )
        : null;
  }

  /// Gets the minimum of [Component.minValue]s.
  double getMinValue() {
    final Iterable<double> minValues =
        where((Component? c) => c != null && !c.minValue.isNaN)
            .map((Component? c) => c!.minValue);
    return minValues.isEmpty ? double.nan : minValues.reduce(min);
  }

  /// Gets the maximum of [Component.maxValue]s.
  double getMaxValue() {
    final Iterable<double> maxValues =
        where((Component? c) => c != null && !c.maxValue.isNaN)
            .map((Component? c) => c!.maxValue);
    return maxValues.isEmpty ? double.nan : maxValues.reduce(max);
  }
}

class MultipleAnimatedBuilder extends StatelessWidget {
  /// Create multiple animated builder.
  const MultipleAnimatedBuilder({
    required this.animations,
    required this.builder,
    Key? key,
  }) : super(key: key);

  /// List of animations that build will listen to.
  final List<Listenable?> animations;

  /// Called every time any of the animations changes value.
  final TransitionBuilder builder;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge(animations),
        builder: builder,
      );
}
