import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';

import 'i18n.dart';


class _AddPoiDialogState extends State<AddPoiDialog> {
  final TextEditingController nameInputController = TextEditingController();
  final TextEditingController descriptionInputController = TextEditingController();
  final LatLng location;

  String nameInputError;

  _AddPoiDialogState(this.location);

  @override
  Widget build(BuildContext context) {
    if (nameInputController.text != null && nameInputController.text.isNotEmpty) {
      nameInputError = null;
    } else {
      nameInputError = I18N.of(context).errorNameRequired;
    }
    return SimpleDialog(
      //title: Text('Scan pairing code'),
      children: <Widget>[
        Text('Lat: ${location.latitude}'),
        Text('Lng: ${location.longitude}'),
        TextField(
          controller: nameInputController,
          decoration: InputDecoration(
              labelText: I18N.of(context).nameLabel,
              errorText: nameInputError
          ),
          onChanged: (String value) {
            setState(() {
              if (value == null || value.isEmpty) {
                nameInputError = I18N.of(context).errorNameRequired;
              } else {
                nameInputError = null;
              }
            });
          },
        ),
        TextField(
          controller: descriptionInputController,
          decoration: InputDecoration(
            labelText: I18N.of(context).descriptionLabel,
          ),
          maxLines: null,
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            RaisedButton(
              color: Theme.of(context).accentColor,
              textTheme: Theme.of(context).buttonTheme.textTheme,
              child: Text(I18N.of(context).dialogSave),
              onPressed: _isValid() ? _save : null,
            ),
            RaisedButton(
              color: Theme.of(context).accentColor,
              textTheme: Theme.of(context).buttonTheme.textTheme,
              child: Text(I18N.of(context).dialogCancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        ),
      ],
    );
  }

  bool _isValid() {
    return nameInputController.text != null
        && nameInputController.text.isNotEmpty;
  }

  void _save() {
    Navigator.of(context).pop({
      'name': nameInputController.text,
      'description': descriptionInputController.text
    });
  }

  @override
  void dispose() {
    nameInputController?.dispose();
    super.dispose();
  }
}

class AddPoiDialog extends StatefulWidget {
  final LatLng location;

  const AddPoiDialog({Key key, this.location}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AddPoiDialogState(location);
  }
}
