import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'ys_chart.dart';

class ChartFullPage extends StatefulWidget {
  final ChartType chartType;
  final String? title;
  final DateFormat timeFormat;
  final String? yUnit;
  final List<CoordinatePoint> data;

  const ChartFullPage(
      {super.key,
      required this.timeFormat,
      this.yUnit,
      required this.data,
      this.title,
      required this.chartType});

  @override
  State<ChartFullPage> createState() => _ChartFullPageState();
}

class _ChartFullPageState extends State<ChartFullPage> {
  @override
  void initState() {
    super.initState();
    // 强制横屏
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
          child: YSChart(
        title: widget.title,
        timeFormat: widget.timeFormat,
        data: widget.data,
        isFullScreen: true,
        chartType: widget.chartType,
      )),
    );
  }
}
