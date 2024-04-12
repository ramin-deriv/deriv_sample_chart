import 'dart:async';
import 'dart:math';

import 'package:flutter_financial_chart/deriv_sample_chart.dart';

typedef OnNewCandle = void Function(OHLC);
typedef OnOHLCHistory = void Function(List<OHLC>);

const double trendDirectionChance = 0.56;

class MockAPI {
  MockAPI({
    required this.onNewCandle,
    this.onOHLCHistory,
    required this.granularity,
    int historyForPastSeconds = 1000,
    final Duration generateInterval = const Duration(milliseconds: 500),
  }) {
    _intervalStartTime = DateTime.now()
        .toUtc()
        .subtract(Duration(seconds: historyForPastSeconds));

    if (onOHLCHistory != null) {
      DateTime now = DateTime.now()
          .toUtc()
          .subtract(Duration(seconds: historyForPastSeconds));
      final List<OHLC> ohlcValues = [];
      for (int i = 0; i < historyForPastSeconds; i++) {
        now = now.add(Duration(seconds: 1));
        _generateOHLC(now, (OHLC ohlc) {
          final OHLC entry = ohlc;
          if (ohlcValues.isNotEmpty && ohlc.time == ohlcValues.last.time) {
            ohlcValues.removeLast();
          }
          ohlcValues.add(entry);
        });
      }

      onOHLCHistory?.call(ohlcValues);
    }

    _timer = Timer.periodic(
      generateInterval,
      (_) => _generateOHLC(DateTime.now().toUtc(), onNewCandle),
    );
  }

  Random _random = Random();

  Timer? _timer;

  double _max = 201;
  double _min = 199;

  double _value = 200;

  late DateTime _intervalStartTime;

  final int granularity;

  double? _open;

  double? _low;

  double? _high;

  bool _trendToUp = true;

  final OnNewCandle onNewCandle;

  final OnOHLCHistory? onOHLCHistory;

  bool _decideBasedOnTrend() => _trendToUp
      ? _random.nextDouble() < trendDirectionChance
      : _random.nextDouble() >= trendDirectionChance;

  _updateMinMaxPrices() {
    final minMaxChange = _random.nextDouble() + 0.2;

    final bool increase = _random.nextBool();

    _max = increase ? _max + minMaxChange : _max - minMaxChange;
    _min = increase ? _min + minMaxChange : _min - minMaxChange;
  }

  void dispose() {
    _timer?.cancel();
  }

  void _generateOHLC(DateTime now, OnNewCandle onNewCandle) {
    final randomValue = _random.nextDouble() * 0.056 * sqrt(granularity);

    _value =
        _decideBasedOnTrend() ? _value + randomValue : _value - randomValue;

    // Switching market trend when goes over limit
    if (_value > _max) {
      _trendToUp = false;
      _updateMinMaxPrices();
    } else if (_value < _min) {
      _trendToUp = true;
    }

    if (now.difference(_intervalStartTime).inSeconds < granularity) {
      if (_open == null) {
        _open = _value;
      }
      if (_low == null) {
        _low = _value;
      }
      if (_high == null) {
        _high = _value;
      }

      _high = max(_high!, _value);
      _low = min(_low!, _value);

      onNewCandle(OHLC(
        time: _intervalStartTime.millisecondsSinceEpoch,
        open: _open!,
        high: _high!,
        low: _low!,
        close: _value,
        // intervalInSec: granularity,
      ));
    } else {
      _open = null;
      _high = null;
      _low = null;
      _intervalStartTime = now;
    }
  }
}
