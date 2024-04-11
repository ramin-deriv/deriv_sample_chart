class Tick {
  final int time;
  final double value;

  Tick({required this.time, required this.value});
}

class OHLC extends Tick {
  OHLC({
    required int time,
    required this.open,
    required this.close,
    required this.high,
    required this.low,
  }) : super(
    time: time,
    value: close,
  );

  final double open;
  final double close;
  final double high;
  final double low;
}

/// A class that hold animation progress values.
class AnimationInfo {
  /// Initializes
  const AnimationInfo({this.currentTickPercent = 1});

  /// Animation percent of current tick.
  final double currentTickPercent;
}

class ChartConfig {}