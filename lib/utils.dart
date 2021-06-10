import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:poi_map_app/communication.dart';

import 'i18n.dart';

class Tuple<A, B> {
  final A ?a;
  final B ?b;

  Tuple(this.a, this.b);
}

class IntRange {
  final int min;
  final int max;
  final bool openMin;
  final bool openMax;

  IntRange(int min, int max) : this.min = min, this.max = max, this.openMin = false, this.openMax = false {
    if (min > max) {
      throw InvalidRangeException('$min is greater than $max');
    }
  }

  IntRange.openMin(int max) : this.min = 0, this.max = max, this.openMin = true, this.openMax = true;
  IntRange.openMax(int min) : this.min = min, this.max = 0, this.openMin = false, this.openMax = true;
  IntRange.open() : this.min = 0, this.max = 0, this.openMin = true, this.openMax = true;
  IntRange.point(int x) : this(x, x);

  IntRange extend(int v) {
    if (openMin && openMax) {
      return this;
    }
    if (openMin) {
      return IntRange.openMin(math.max(max, v));
    }
    if (openMax) {
      return IntRange.openMax(math.min(min, v));
    }
    return IntRange(math.min(min, v), math.max(max, v));
  }

  static IntRange extended(IntRange r, int v) {
    return r.extend(v);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntRange &&
          runtimeType == other.runtimeType &&
          (
              (openMin && openMax && other.openMin && other.openMax) ||
              (openMin && !openMax && other.openMin && !other.openMax && max == other.max) ||
              (!openMin && openMax && !other.openMin && other.openMax && min == other.min) ||
              (!openMin && !openMax && !other.openMin && !other.openMax && min == other.min && max == other.max)
          );

  @override
  int get hashCode {
    if (openMin && openMax) {
      return openMin.hashCode ^ openMax.hashCode;
    }
    if (openMin) {
      return openMin.hashCode ^ openMax.hashCode ^ max.hashCode;
    }
    if (openMax) {
      return openMin.hashCode ^ openMax.hashCode ^ min.hashCode;
    }
    return min.hashCode ^ max.hashCode ^ openMin.hashCode ^ openMax.hashCode;
  }
}

class DoubleRange {
  final double min;
  final double max;

  DoubleRange(double min, double max) : this.min = min, this.max = max {
    if (min > max) {
      throw InvalidRangeException('$min is greater than $max');
    }
  }

  DoubleRange.point(double x) : this(x, x);

  DoubleRange extend(double v) {
    return DoubleRange(math.min(min, v), math.max(max, v));
  }

  static IntRange extended(IntRange r, int v) {
    return r.extend(v);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoubleRange &&
          runtimeType == other.runtimeType &&
          min == other.min &&
          max == other.max;

  @override
  int get hashCode => min.hashCode ^ max.hashCode;
}

Future<void> commErrorDialog(Exception e, BuildContext context) async {
  String errorText;
  String subText;
  if (e is CommException) {
    errorText = e.name;
    switch (e.name) {
      case CommException.nameNotSupplied:
        errorText = I18N.of(context).commErrorNameNotSupplied;
        break;
      case CommException.nameAlreadyExists:
        errorText = I18N.of(context).commErrorNameAlreadyExists;
        break;
    }
    subText = '\n${e.uri}\n${e.fullError.toString()}';
  } else {
    errorText = 'Unknown exception';
    subText = e.toString();
  }
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(I18N
            .of(context)
            .alertErrorTitle),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(errorText),
            Text(subText, style: TextStyle(fontFamily: 'monospace', fontSize: 10),),
          ],
        ),
        actions: <Widget>[
          MaterialButton(
            child: Text(I18N.of(context).ok),
            color: Theme.of(context).accentColor,
            colorBrightness: Theme.of(context).accentColorBrightness,
            textTheme: Theme.of(context).buttonTheme.textTheme,
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      );
    }
  );
}

class _BaseException implements Exception {
  final String ?msg;

  _BaseException([this.msg]);

  @override
  String toString() => msg ?? this.runtimeType.toString();
}

class InvalidRangeException extends _BaseException {
  InvalidRangeException(String msg) : super(msg);
}

class IllegalStateException extends _BaseException {
  IllegalStateException(String msg) : super(msg);
}