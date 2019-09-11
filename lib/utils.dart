import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:poi_map_app/communication.dart';

import 'i18n.dart';

class Tuple<A, B> {
  final A a;
  final B b;

  Tuple(this.a, this.b);
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