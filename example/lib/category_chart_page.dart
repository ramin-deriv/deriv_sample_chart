import 'package:flutter/material.dart';
import 'package:flutter_financial_chart/deriv_sample_chart.dart';

import 'mock_api.dart';

class CategoryChartPage extends StatefulWidget {
  @override
  _CategoryChartPageState createState() => _CategoryChartPageState();
}

class _CategoryChartPageState extends State<CategoryChartPage> {
  List<OHLC> ohlcValues = [];

  List<Tick> maValues = [];

  List<Tick> markerValues = [];

  bool _connected = false;

  int chartType = 1;

  @override
  void initState() {
    super.initState();

    _connectToAPI();
  }

  void _connectToAPI() async {
    _connected = true;

    MockAPI(
        granularity: 3,
        historyForPastSeconds: 10 * 1000,
        onOHLCHistory: (List<OHLC> history) {
          setState(() {
            ohlcValues = history;
          });
        },
        onNewCandle: (OHLC ohlc) {
          final OHLC entry = ohlc;
          ohlcValues = ohlcValues.toList();
          if (ohlcValues.isNotEmpty && ohlc.time == ohlcValues.last.time) {
            ohlcValues.removeLast();
          }
          setState(() {
            ohlcValues.add(entry);
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          constraints: BoxConstraints.expand(),
          child: _connected
              ? Stack(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Material(
                          color: Colors.transparent,
                          child: _buildTopButtons(),
                        ),
                        Expanded(
                          flex: 4,
                          child: ohlcValues.length < 2
                              ? Container()
                              : Container(
                                  width: double.infinity,
                                  child: ChartWidget(
                                    mainComponent: DataSeries(ohlcValues),
                                    components: [
                                      Annotation(ohlcValues.last),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                )
              : Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Row _buildTopButtons() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.show_chart),
          onPressed: () => setState(() => chartType++),
        ),
        IconButton(
          icon: Icon(Icons.outlined_flag),
          onPressed: () {
            final secondLast = ohlcValues[ohlcValues.length - 2];
            setState(() => markerValues
                .add(Tick(time: secondLast.time, value: secondLast.value)));
          },
        ),
      ],
    );
  }
}
