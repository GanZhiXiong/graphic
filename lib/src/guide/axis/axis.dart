import 'dart:ui';

import 'package:graphic/src/common/label.dart';
import 'package:graphic/src/common/layers.dart';
import 'package:graphic/src/common/operators/render.dart';
import 'package:graphic/src/common/styles.dart';
import 'package:graphic/src/coord/coord.dart';
import 'package:graphic/src/coord/polar.dart';
import 'package:graphic/src/coord/rect.dart';
import 'package:graphic/src/dataflow/operator/updater.dart';
import 'package:graphic/src/dataflow/pulse/pulse.dart';
import 'package:graphic/src/graffiti/graffiti.dart';
import 'package:graphic/src/guide/axis/circular.dart';
import 'package:graphic/src/guide/axis/horizontal.dart';
import 'package:graphic/src/guide/axis/radial.dart';
import 'package:graphic/src/guide/axis/vertical.dart';
import 'package:graphic/src/scale/scale.dart';
import 'package:graphic/src/util/assert.dart';

class TickLine {
  const TickLine({
    this.style = const StrokeStyle(),
    this.length = 2,
  });

  final StrokeStyle style;

  final double length;

  @override
  bool operator ==(Object other) =>
    other is TickLine &&
    style == other.style &&
    length == other.length;
}

typedef TickLineMapper = TickLine? Function(String text, int index, int total);

typedef LabelMapper = LabelSyle? Function(String text, int index, int total);

typedef GridMapper = StrokeStyle? Function(String text, int index, int total);

class GuideAxis<V> {
  GuideAxis({
    this.dim,
    this.variable,
    this.position,
    this.flip,
    this.line,
    this.tickLine,
    this.tickLineMapper,
    this.label,
    this.labelMapper,
    this.grid,
    this.gridMapper,
    this.zIndex,
    this.gridZIndex,
  })
    : assert(isSingle([tickLine, tickLineMapper], allowNone: true)),
      assert(isSingle([label, labelMapper], allowNone: true)),
      assert(isSingle([grid, gridMapper], allowNone: true));

  /// By default, axes specification list implies [dim1, dim2].
  final int? dim;

  /// The first variable in this dim by default.
  final String? variable;

  final double? position;

  final bool? flip;  // Flip tick and label to other side of the axis.

  final StrokeStyle? line;

  final TickLine? tickLine;

  final TickLineMapper? tickLineMapper;

  final LabelSyle? label;

  final LabelMapper? labelMapper;

  final StrokeStyle? grid;

  final GridMapper? gridMapper;

  final int? zIndex;

  final int? gridZIndex;

  @override
  bool operator ==(Object other) =>
    other is GuideAxis &&
    dim == other.dim &&
    variable == other.variable &&
    position == other.position &&
    flip == other.flip &&
    line == other.line &&
    tickLine == other.tickLine &&
    // tickLineMapper: Function
    label == other.label &&
    // labelMapper: Function
    grid == other.grid &&
    // gridMapper: Function
    zIndex == other.zIndex &&
    gridZIndex == other.gridZIndex;
}

// tickInfo

class TickInfo {
  TickInfo(
    this.position,
    this.text,
  );

  final double position;

  final String text;

  TickLine? tickLine;

  LabelSyle? label;

  StrokeStyle? grid;
}

/// -         / AxisRenderOp
/// TickInfoOp
/// -         \ GridRenderOp
class TickInfoOp extends Updater<List<TickInfo>> {
  TickInfoOp(Map<String, dynamic> params) : super(params);

  @override
  List<TickInfo> update(Pulse pulse) {
    final variable = params['variable'] as String;
    final scales = params['scales'] as Map<String, ScaleConv>;
    final tickLine = params['tickLine'] as TickLine?;
    final tickLineMapper = params['tickLineMapper'] as TickLineMapper?;
    final label = params['label'] as LabelSyle?;
    final labelMapper = params['labelMapper'] as LabelMapper?;
    final grid = params['grid'] as StrokeStyle?;
    final gridMapper = params['gridMapper'] as GridMapper?;

    final scale = scales[variable]!;

    final ticks = scale.ticks!.map((value) => TickInfo(
      scale.normalize(scale.convert(value)),
      scale.formatter!(value),
    )).toList();

    final total = ticks.length;
    for (var i = 0; i < total; i++) {
      final tick = ticks[i];
      if (tickLine != null) {
        tick.tickLine = tickLine;
      } else if (tickLineMapper != null) {
        tick.tickLine = tickLineMapper(tick.text, i, total);
      }
      if (label != null) {
        tick.label = label;
      } else if (labelMapper != null) {
        tick.label = labelMapper(tick.text, i, total);
      }
      if (grid != null) {
        tick.grid = grid;
      } else if (gridMapper != null) {
        tick.grid = gridMapper(tick.text, i, total);
      }
    }

    return ticks;
  }
}

// axis

abstract class AxisPainter<C extends CoordConv> extends Painter {
  AxisPainter(
    this.ticks,
    this.position,
    this.flip,
    this.line,
    this.coord,
    this.region,
  );

  final List<TickInfo> ticks;

  final double position;

  final bool flip;

  final StrokeStyle? line;

  final C coord;

  final Rect region;
}

class AxisScene extends Scene {
  @override
  int get layer => Layers.axis;
}

class AxisRenderOp extends Render<AxisScene> {
  AxisRenderOp(
    Map<String, dynamic> params,
    AxisScene value,
  ) : super(params, value);

  @override
  void render(AxisScene scene) {
    final zIndex = params['zIndex'] as int;
    final coord = params['coord'] as CoordConv;
    final region = params['region'] as Rect;
    final dim = params['dim'] as int;
    final position = params['position'] as double;
    final flip = params['flip'] as bool;
    final line = params['line'] as StrokeStyle?;
    final ticks = params['ticks'] as List<TickInfo>;
    
    scene.zIndex = zIndex;

    final canvasDim = coord.getCanvasDim(dim);
    if (coord is RectCoordConv) {
      if (canvasDim == 1) {
        scene.painter = HorizontalAxisPainter(
          ticks,
          position,
          flip,
          line,
          coord,
          region,
        );
      } else {
        scene.painter = VerticalAxisPainter(
          ticks,
          position,
          flip,
          line,
          coord,
          region,
        );
      }
    } else {
      coord as PolarCoordConv;
      if (coord.transposed) {
        scene.painter = CircularAxisPainter(
          ticks,
          position,
          flip,
          line,
          coord,
          region,
        );
      } else {
        scene.painter = RadialAxisPainter(
          ticks,
          position,
          flip,
          line,
          coord,
          region,
        );
      }
    }
  }
}

// grid

abstract class GridPainter<C extends CoordConv> extends Painter {
  GridPainter(
    this.ticks,
    this.coord,
    this.region,
  );

  final List<TickInfo> ticks;

  final C coord;

  final Rect region;
}

class GridScene extends Scene {
  @override
  int get layer => Layers.grid;
}

class GridRenderOp extends Render<GridScene> {
  GridRenderOp(
    Map<String, dynamic> params,
    GridScene value,
  ) : super(params, value);

  @override
  void render(GridScene scene) {
    final gridZIndex = params['gridZIndex'] as int;
    final coord = params['coord'] as CoordConv;
    final region = params['region'] as Rect;
    final dim = params['dim'] as int;
    final ticks = params['ticks'] as List<TickInfo>;
    
    scene.zIndex = gridZIndex;

    final canvasDim = coord.transposed ? (3 - dim) : dim;
    if (coord is RectCoordConv) {
      if (canvasDim == 1) {
        scene.painter = HorizontalGridPainter(
          ticks,
          coord,
          region,
        );
      } else {
        scene.painter = VerticalGridPainter(
          ticks,
          coord,
          region,
        );
      }
    } else {
      coord as PolarCoordConv;
      if (coord.transposed) {
        scene.painter = CircularGridPainter(
          ticks,
          coord,
          region,
        );
      } else {
        scene.painter = RadialGridPainter(
          ticks,
          coord,
          region,
        );
      }
    }
  }
}
