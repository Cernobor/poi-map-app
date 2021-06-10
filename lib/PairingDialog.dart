import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:poi_map_app/data.dart';
import 'package:poi_map_app/utils.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'communication.dart' as comm;
import 'i18n.dart';

class _PairingDialogState extends State<PairingDialog> {
  final TextEditingController addressInputController = TextEditingController();
  final TextEditingController nameInputController = TextEditingController();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final GlobalKey<ScaffoldState> scaffoldKey;

  String? addressInputError;
  String? nameInputError;
  bool exists = false;

  QRViewController? controller;
  bool scanning = false;

  _PairingDialogState(this.scaffoldKey);


  @override
  Widget build(BuildContext context) {
    if (addressInputController.text.isNotEmpty) {
      addressInputError = null;
    } else {
      addressInputError = I18N.of(context).errorAddressRequired;
    }
    if (nameInputController.text.isNotEmpty) {
      nameInputError = null;
    } else {
      nameInputError = I18N.of(context).errorNameRequired;
    }
    return SimpleDialog(
      //title: Text('Scan pairing code'),
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: addressInputController,
                decoration: InputDecoration(
                  labelText: I18N.of(context).serverAddressLabel,
                  errorText: addressInputError
                ),
                onChanged: (String value) {
                  setState(() {
                    if (value.isEmpty) {
                      addressInputError = I18N.of(context).errorAddressRequired;
                    } else {
                      addressInputError = null;
                    }
                  });
                },
              ),
            ),
            ElevatedButton(
              child: Text(scanning ? I18N.of(context).stop : I18N.of(context).scan),
              onPressed: scanning ?
                () {
                  setState(() {
                    controller!.dispose();
                    scanning = false;
                  });
                }
                : () {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    scanning = true;
                  });
                },
            ),
          ],
        ),
      ] + (
        scanning ? [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: <Widget>[
                QRView(
                  onQRViewCreated: _onQRViewCreated,
                  key: qrKey,
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: IconButton(
                    icon: Icon(Icons.switch_camera),
                    color: Theme.of(context).accentColor,
                    onPressed: () {
                      controller!.flipCamera();
                    },
                  ),
                ),
              ]
            )
          )
        ] : []
      ) + [
        TextField(
          controller: nameInputController,
          decoration: InputDecoration(
            labelText: I18N.of(context).nameLabel,
            errorText: nameInputError
          ),
          onChanged: (String value) {
            setState(() {
              if (value.isEmpty) {
                nameInputError = I18N.of(context).errorNameRequired;
              } else {
                nameInputError = null;
              }
            });
          },
        ),
        CheckboxListTile(
          value: exists,
          title: Text(I18N.of(context).handshakeExistsTitle),
          subtitle: Text(I18N.of(context).handshakeExistsSubtitle),
          onChanged: (bool? value) {
            setState(() {
              exists = value!;
            });
          },
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            ElevatedButton(
              child: Text(I18N.of(context).dialogPair),
              onPressed: _isValid() ? _pair : null,
            ),
            ElevatedButton(
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

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((Barcode barcode) {
      developer.log(barcode.code);
      addressInputController.text = barcode.code;
    });
  }

  bool _isValid() {
    return addressInputController.text.isNotEmpty
        && nameInputController.text.isNotEmpty;
  }

  void _pair() async {
    String serverAddress = addressInputController.text;
    comm.HandshakeResponse response;
    try {
      response = await comm.handshake(
          serverAddress, nameInputController.text, exists);
    } on comm.CommException catch (e) {
      await commErrorDialog(e, context);
      return;
    } on Exception catch (e) {
      await commErrorDialog(e, context);
      return;
    }
    Navigator.of(context).pop(ServerSettings(
      serverAddress: serverAddress,
      name: response.name,
      id: response.id,
      tilePackPath: response.tilePackPath
    ));
  }

  @override
  void dispose() {
    addressInputController.dispose();
    nameInputController.dispose();
    if (controller != null) {
      controller!.dispose();
    }
    super.dispose();
  }
}

class PairingDialog extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const PairingDialog({Key? key, required this.scaffoldKey}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PairingDialogState(scaffoldKey);
  }
}
