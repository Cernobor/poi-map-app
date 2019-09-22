import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:poi_map_app/communication.dart';

import 'i18n.dart';

class Tuple<A, B> {
  final A a;
  final B b;

  Tuple(this.a, this.b);
}

class Range<T extends num> {
  final T min;
  final T max;

  Range(this.min, this.max) {
    if (this.min > this.max) {
      throw InvalidRangeException('$min is greater than $max');
    }
  }

  Range.equal(T x) : this(x, x);

  const Range.nil(T _) : min = null, max = null;

  Range<T> merge(T v) {
    if (this == Range.nil(v)) {
      return Range.equal(v);
    }
    return Range(math.min(min, v), math.max(max, v));
  }

  static Range<V> merged<V extends num>(Range<V> r, V v) {
    return r.merge(v);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Range &&
              runtimeType == other.runtimeType &&
              min == other.min &&
              max == other.max;

  @override
  int get hashCode =>
      min.hashCode ^
      max.hashCode;
}

Future<void> commErrorDialog(CommException e, BuildContext context) async {
  var errorText = e.name;
  switch (e.name) {
    case CommException.nameNotSupplied:
      errorText = I18N.of(context).commErrorNameNotSupplied;
      break;
    case CommException.nameAlreadyExists:
      errorText = I18N.of(context).commErrorNameAlreadyExists;
      break;
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
            Text('\n${e.uri}', style: TextStyle(fontFamily: 'monospace', fontSize: 10),),
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
  final String msg;

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