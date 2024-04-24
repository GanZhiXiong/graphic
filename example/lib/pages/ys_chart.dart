import 'dart:async';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:graphic/graphic.dart';
import 'package:intl/intl.dart';

import 'chart_full_page.dart';

enum ChartType {
  line,
  column,
  bar,
  pie,
}

class CoordinatePoint {
  final DateTime x;
  final int y;

  CoordinatePoint(this.x, this.y);
}

class YSChart extends StatefulWidget {
  final ChartType chartType;
  final String? title;
  final DateFormat timeFormat;
  final String? yUnit;
  final List<CoordinatePoint> data;
  final List<DateTime>? xTicks;
  final String? morePath;


  // final VoidCallback? onPressedFullScreen;
  final bool isFullScreen;

  const YSChart({
    super.key,
    required this.timeFormat,
    this.yUnit,
    required this.data,
    this.isFullScreen = false,
    this.title,
    required this.chartType,
    this.xTicks, this.morePath,
  });

  @override
  State<YSChart> createState() => _YSChartState();
}

class _YSChartState extends State<YSChart> with WidgetsBindingObserver {
  /// The device kind of the last [Gesture].
  ///
  /// It is record by chart state to for [Gesture]s when the [GestureDetector]
  /// callback dosen't have a current device kind. It is updated when the callback
  /// has a current device kind.
  PointerDeviceKind _gestureKind = PointerDeviceKind.unknown;

  /// Size of the chart widget.
  ///
  /// The chart state hold this for the [Listener] and the [GestureDetector] to
  /// create [Gesture]s.
  Size size = Size.zero;

  /// The local position of the last [Gesture].
  ///
  /// It is record by chart state to for [Gesture]s when the [GestureDetector]
  /// callback dosen't have a current position. It is updated when the callback
  /// has a current position.
  Offset gestureLocalPosition = Offset.zero;

  Timer? timer;
  int _zoomLevel = 0;

  bool? rebuild;

  int get zoomLevel => _zoomLevel;

  set zoomLevel(int value) {
    print('setzoomLevel: $value');
    if (maxHorizontalRange + value < 1) return;
    _zoomLevel = value;
  }

  double _maxHorizontalRange = 2;

  double get maxHorizontalRange => _maxHorizontalRange;

  set maxHorizontalRange(double value) {
    print('setmaxHorizontalRange: $value');
    if (value < 1) {
      _maxHorizontalRange = 1;
      return;
    }
    _maxHorizontalRange = value;
  }

  final gestureStream = StreamController<GestureEvent>.broadcast();

  Size chartSize = Size(350, 250);

  Orientation orientation = Orientation.portrait;

  void scaleUpdateToLeft() {
    scaleUpdate(Offset(24, 0));
  }

  void scaleUpdateToRight() {
    scaleUpdate(Offset(-24, 0));
  }

  void scaleUpdate(Offset offset) {
    var g = Gesture(
      GestureType.scaleUpdate,
      _gestureKind,
      gestureLocalPosition,
      chartSize,
      ScaleUpdateDetails(
        scale: 1.0,
        horizontalScale: 1.0,
        verticalScale: 1.0,
        rotation: 0.0,
        pointerCount: 1,
      ),
      preScaleDetail: ScaleUpdateDetails(focalPointDelta: offset),
    );
    // gestureScaleDetail = detail;
    gestureStream.sink.add(GestureEvent(g));
  }

  @override
  void initState() {
    super.initState();
    maxHorizontalRange = widget.data.length / 12;
    WidgetsBinding.instance.addObserver(this);
  }

  // Widget buildTitle(BuildContext context) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: <Widget>[
  //       Spacer(),
  //       Text(
  //         "Energy Usage (Wh)",
  //         textAlign: TextAlign.center,
  //       ),
  //       if (widget.morePath == null) Spacer(),
  //       if (widget.morePath != null)
  //         Expanded(
  //           child: Align(
  //               alignment: Alignment.topRight,
  //               child: TextButton.icon(
  //                 onPressed: () {
  //                   Application.push(context, widget.morePath!);
  //                 },
  //                 label: Text("More"),
  //                 icon: Icon(
  //                   FontAwesomeIcons.chartLine,
  //                   size: 18,
  //                 ),
  //               )),
  //         ),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;
    var toolbarHeight = 44.0;
    return Column(
      // mainAxisSize: MainAxisSize.max,
      children: [
        // buildTitle(context),
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        Expanded(child: buildChart()),
        // widget.isFullScreen
        //     ? Expanded(child: buildChart())
        //     // ? SizedBox(height: 300, child: buildChart())
        //     : SizedBox(height: 300, child: buildChart()),
        // SizedBox(height: screenHeight - toolbarHeight, child: buildChart()),
        SizedBox(height: toolbarHeight, child: buildTool()),
        // buildTool1(),
      ],
    );
  }

  Row buildTool() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        InkWell(
            // borderRadius: BorderRadius.circular(20),
            // elevation: 20,
            child: GestureDetector(
          onTap: () {
            scaleUpdateToLeft();
          },
          onLongPress: () {
            scaleUpdateToLeft();
            timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
              scaleUpdateToLeft();
            });
          },
          onLongPressEnd: (details) {
            timer?.cancel();
          },
          // onLongPressEnd: (_) => setState(() {
          //   // action = "Longpress stopped";
          //   timer?.cancel();
          // }),
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(
              Icons.chevron_left,
              size: 28,
              color: Colors.grey,
            ),
          ),
        )),
        InkWell(
            // borderRadius: BorderRadius.circular(20),
            // elevation: 20,
            child: GestureDetector(
          onTap: () {
            scaleUpdateToRight();
          },
          onLongPress: () {
            timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
              scaleUpdateToRight();
            });
          },
          onLongPressEnd: (details) {
            timer?.cancel();
          },
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(
              Icons.chevron_right,
              size: 28,
              color: Colors.grey,
            ),
          ),
        )),
        IconButton(
            onPressed: () {
              setState(() {
                // 修复通过手势缩放图表，然后将 maxHorizontalRange 设置为默认值，图表没有 rebuild。
                rebuild = true;
                maxHorizontalRange = widget.data.length / 12;
                // rebuild = null;
              });
            },
            icon: const Icon(
              Icons.search_rounded,
              size: 28,
              color: Colors.grey,
            )),
        IconButton(
            onPressed: () {
              setState(() {
                maxHorizontalRange++;
              });
            },
            icon: const Icon(
              Icons.zoom_in,
              size: 28,
              color: Colors.grey,
            )),
        IconButton(
            onPressed: () {
              setState(() {
                maxHorizontalRange--;
              });
            },
            icon: const Icon(
              Icons.zoom_out,
              size: 28,
              color: Colors.grey,
            )),
        widget.isFullScreen
            ? IconButton(
                onPressed: () {
                  // 强制竖屏
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                    DeviceOrientation.portraitDown
                  ]);
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.fullscreen_exit,
                  size: 28,
                  color: Colors.grey,
                ))
            : IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChartFullPage(
                          title: widget.title,
                          timeFormat: widget.timeFormat,
                          data: widget.data,
                          chartType: widget.chartType,
                        ),
                      ));
                },
                icon: const Icon(
                  Icons.fullscreen,
                  size: 28,
                  color: Colors.grey,
                )),
      ],
    );
  }

  Row buildTool1() {
    return Row(
      children: [
        TextButton(
            onPressed: () {
              gestureStream.sink.add(GestureEvent(Gesture(
                GestureType.doubleTap,
                _gestureKind,
                Offset(296, 254),
                Size(350, 300),
                null,
                // chartKey: widget.key,
              )));
            },
            child: Text('next')),
        TextButton(
            onPressed: () {
              // gestureLocalPosition = detail.localPosition;
              // gestureLocalMoveStart = null;
              var longPress = Gesture(
                GestureType.scroll,
                _gestureKind,
                // gestureLocalPosition,
                Offset.zero,
                // Offset(296, 254),
                Size(350, 300),
                Offset(100, 0),
                // Offset(396, 254),
                // chartKey: widget.key,
                // localMoveStart: Offset.zero,
              );
              gestureStream.sink.add(GestureEvent(longPress));
            },
            child: Text('next')),
        TextButton(
            onPressed: () {
              scaleUpdateToLeft();
            },
            child: Text('scaleUpdate left')),
        TextButton(
            onPressed: () {
              var g = Gesture(
                GestureType.scaleUpdate,
                _gestureKind,
                gestureLocalPosition,
                Size(350, 300),
                ScaleUpdateDetails(
                  scale: 1.0,
                  horizontalScale: 1.0,
                  verticalScale: 1.0,
                  rotation: 0.0,
                  pointerCount: 1,
                ),
                preScaleDetail:
                    ScaleUpdateDetails(focalPointDelta: Offset(-24.0, 0.0)),
              );
              // gestureScaleDetail = detail;
              gestureStream.sink.add(GestureEvent(g));
            },
            child: Text('right')),
      ],
    );
  }

  List<MarkElement> simpleTooltip(
    Size size,
    Offset anchor,
    Map<int, Tuple> selectedTuples,
  ) {
    List<MarkElement> elements;

    String textContent = '';
    final selectedTupleList = selectedTuples.values;
    // final fields = selectedTupleList.first.keys.toList();
    // if (selectedTuples.length == 1) {
    //   final original = selectedTupleList.single;
    //   var field = fields.first;
    //   textContent += '$field: ${original[field]}';
    //   for (var i = 1; i < fields.length; i++) {
    //     field = fields[i];
    //     textContent += '\n$field: ${original[field]}';
    //   }
    // } else {
    //   for (var original in selectedTupleList) {
    //     final domainField = fields.first;
    //     final measureField = fields.last;
    //     textContent += '\n${original[domainField]}: ${original[measureField]}';
    //     textContent += '\n${original[domainField]}: ${original[measureField]}';
    //   }
    // }
    String unit = '';
    if (widget.yUnit != null) {
      unit = ' (${widget.yUnit})';
    }
    textContent =
        '${selectedTupleList.first['y']}$unit\n${widget.timeFormat.format(selectedTupleList.first['x'])}';

    const textStyle = TextStyle(fontSize: 12, color: Colors.white);
    const padding = EdgeInsets.all(5);
    const align = Alignment.topRight;
    const offset = Offset(5, -5);
    const elevation = 1.0;
    const backgroundColor = Colors.black;

    final painter = TextPainter(
      text: TextSpan(text: textContent, style: textStyle),
      textDirection: ui.TextDirection.ltr,
    );
    painter.layout();

    final width = padding.left + painter.width + padding.right;
    final height = padding.top + painter.height + padding.bottom;

    final paintPoint = getBlockPaintPoint(
      anchor + offset,
      width,
      height,
      align,
    );

    final window = Rect.fromLTWH(
      paintPoint.dx,
      paintPoint.dy,
      width,
      height,
    );

    var textPaintPoint = paintPoint + padding.topLeft;

    elements = <MarkElement>[
      RectElement(
          rect: window,
          style: PaintStyle(fillColor: backgroundColor, elevation: elevation)),
      LabelElement(
          text: textContent,
          anchor: textPaintPoint,
          style:
              LabelStyle(textStyle: textStyle, align: Alignment.bottomRight)),
    ];

    return elements;
  }

  Widget buildChart() {
    print('buildChart: $maxHorizontalRange');
    var chart = Chart(
      // padding: (_) => EdgeInsets.zero,
      data: widget.data,
      variables: {
        'x': Variable(
          accessor: (CoordinatePoint datum) => datum.x,
          scale: TimeScale(
            // marginMin: 0,
            // marginMax: 1,
            // ticks: widget.data.map((e) => e.x).toList(),
            ticks: widget.xTicks,
            // tickCount: 14,
            formatter: (time) {
              // if (widget.data
              //         .firstWhereOrNull((element) => widget.timeFormat.format(element.x) == widget.timeFormat.format(time)) ==
              //     null) {
              //   return '';
              // }
              print('time:$time, ${widget.timeFormat.format(time)}');
              // return '12';
              return widget.timeFormat.format(time);
            },
          ),
        ),
        'y': Variable(
          scale: LinearScale(min: 0),
          accessor: (CoordinatePoint datum) => datum.y,
        ),
      },
      // rebuild: rebuild,
      // 旋转屏幕时，屏幕的宽高会变化，会多次 build Widget，因此需要更新 Widget 的时候，就 rebuild，但是它会影响性能。
      rebuild: true,
      gestureStream: gestureStream,
      coord: RectCoord(
          // dimCount: 0,
          // horizontalRange: [0, widget.data.length / 12 + zoomLevel],
          horizontalRange: [0, maxHorizontalRange],
          // horizontalRangeUpdater: Defaults.horizontalRangeEvent
          horizontalRangeUpdater: (initialValue, preValue, event) {
            final horizontalRangeUpdater = Defaults.horizontalRangeEvent;
            // return horizontalRangeUpdater(initialValue, preValue, event);
            final res = horizontalRangeUpdater(initialValue, preValue, event);
            print('initialValue:$initialValue, preValue:$preValue, event:$event, res:$res');
            // print('res:$res');
            // if (res[0] < 0) res[0] = 0;
            // 限制最小缩放为显示区域。
            if (res[1] < 1) res[1] = 1;
            // 防止在最右边滑动，变为放大坐标点间距。
            // TODO: 在最左或最右边滑动时，Tooltip 不会跳到下一个坐标点。
            if (res[0].abs() + 1 > maxHorizontalRange) res[0] = preValue[0];

            // if (res[1] - res[0] < maxHorizontalRange) {
            //   // 限制进一步缩小
            //   res[1] = res[0] + maxHorizontalRange;
            // }
            // if (res[1] - res[0] > maxHorizontalRange * 2) {
            //   // 限制进一步放大
            //   res[1] = res[0] + maxHorizontalRange * 2;
            // }
            if (res[0] > 0.1) {
              // 限制继续图表向右移动
              res[1] = res[1] - (res[0] - 0.1);
              res[0] = 0.1;
            }
            if (res[1] < 0.9) {
              // 限制继续图表向左边移动
              res[0] = res[0] - (res[1] - 0.9);
              res[1] = 0.9;
            }
            maxHorizontalRange = res[1];
            return res;
          }
          // horizontalRangeUpdater: horizontalRangeFocusEvent1
          //
          // // horizontalRangeUpdater: (initialValue, preValue, event) {
          // //   final horizontalRangeUpdater = Defaults.horizontalRangeEvent;
          // //   return horizontalRangeUpdater(initialValue, preValue, event);
          // //   // final res = horizontalRangeUpdater(initialValue, preValue, event);
          // //   // if (res[1] - res[0] < maxHorizontalRange) {
          // //   //   // 限制进一步缩小
          // //   //   res[1] = res[0] + maxHorizontalRange;
          // //   // }
          // //   // if (res[1] - res[0] > maxHorizontalRange * 2) {
          // //   //   // 限制进一步放大
          // //   //   res[1] = res[0] + maxHorizontalRange * 2;
          // //   // }
          // //   // if (res[0] > 0.1) {
          // //   //   // 限制继续图表向右移动
          // //   //   res[1] = res[1] - (res[0] - 0.1);
          // //   //   res[0] = 0.1;
          // //   // }
          // //   // if (res[1] < 0.9) {
          // //   //   // 限制继续图表向左边移动
          // //   //   res[0] = res[0] - (res[1] - 0.9);
          // //   //   res[1] = 0.9;
          // //   // }
          // //   // return res;
          // // },

          ),
      marks: [
        if (widget.chartType == ChartType.line) ...[
          AreaMark(
            shape: ShapeEncode(value: BasicAreaShape(smooth: true)),
            color: ColorEncode(value: Defaults.colors10.first.withAlpha(80)),
          ),
          LineMark(
            shape: ShapeEncode(value: BasicLineShape(smooth: true)),
            size: SizeEncode(value: 0.5),
            // color: ColorEncode(
            //   variable: 'y',
            //   values: Defaults.colors10,
            //
            //   // values: [
            //   //   const Color(0xff5470c6),
            //   //   const Color(0xff91cc75),
            //   // ],
            // )
          ),
        ],
        if (widget.chartType == ChartType.column)
          IntervalMark(
            // shape: ShapeEncode(value: TriangleShape()),
            label: LabelEncode(encoder: (tuple) {
              // print(tuple['y'].toString());
              return Label(tuple['y'].toString());
            }),
            // elevation: ElevationEncode(value: 0, updaters: {
            //   'tap': {
            //     true: (a) {
            //       print('tap: $a');
            //       return 500;
            //     }
            //   },
            // }),
            color: ColorEncode(value: Theme.of(context).primaryColor, updaters: {
              'tap': {false: (color) => color.withAlpha(100)},
              // 'choose': {true: (_) => Colors.red}
            }),
            // modifiers: [DodgeSizeModifier()],
            tag: (p0) {
              return 'tag';
              print('tag: $p0');
            },
          )
      ],
      axes: [
        // Defaults.horizontalAxis
        // ..label = null
        //   ..tickLineMapper = (text, index, total) {
        // print(text);
        // return null;
        //
        //   }
        // ..line = null,
        Defaults.horizontalAxis,
        Defaults.verticalAxis,
      ],
      selections: {'tap': PointSelection(dim: Dim.x)},
      tooltip: TooltipGuide(renderer: simpleTooltip),
      crosshair: CrosshairGuide(),
    );

    rebuild = null;
    return chart;
  }
}
