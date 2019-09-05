// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';
import 'package:location/location.dart';
import 'package:poi_map_app/PairingDialog.dart';

import 'data.dart';
import 'i18n.dart';

void main() => runApp(MaterialApp(
      onGenerateTitle: (BuildContext context) => I18N.of(context).appTitle,
      theme: ThemeData(
        primaryColor: Color(0xFF33691e),
        primaryColorBrightness: Brightness.dark,
        primaryColorDark: Color(0xFF003d00),
        primaryColorLight: Color(0xFF629749),
        accentColor: Color(0xFF827717),
        accentColorBrightness: Brightness.dark,
      ),
      home: Map(),
      localizationsDelegates: [
        const I18NDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: [
        const Locale('en'),
        const Locale('cs')
      ],
    ));

class MapState extends State<Map> {
  final MapController mapController = MapControllerImpl();
  final Location location = Location();
  final double maxZoom = 20;
  final double minZoom = 1;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  bool locationEnabled = false;
  LatLng currentLocation;

  bool pinging = false;
  bool serverAvailable = false;

  ServerSettings settings;

  @override
  void initState() {
    location.getLocation().then((LocationData loc) {
      mapController.onReady.then((_) {
        developer.log('ready');
        setState(() {
          locationEnabled = true;
          currentLocation = LatLng(loc.latitude, loc.longitude);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      primary: true,
      appBar: AppBar(
        title: Text(I18N.of(context).appTitle),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text(I18N.of(context).drawerPaired),
              trailing: settings == null
                ? Icon(Icons.clear, color: Colors.red,)
                : Icon(Icons.done, color: Colors.green,),
              onTap: onPair,
            ),
            ListTile(
              title: Text(I18N.of(context).drawerServerAvailable),
              enabled: settings != null,
              trailing: settings != null && pinging
                ? Container(
                    child: CircularProgressIndicator(
                        value: null, strokeWidth: 2.5),
                    height: 16,
                    width: 16,
                  )
                : (settings != null && serverAvailable
                  ? Icon(Icons.done, color: Colors.green,)
                  : Icon(Icons.clear, color: Colors.red,)
                ),
              onTap: this.onPing,
            ),
          ],
        ),
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(50, 14),
          zoom: 13,
          maxZoom: maxZoom,
          minZoom: minZoom,
          debug: true,
          onPositionChanged: !mapController.ready
              ? null
              : (MapPosition position, bool hasGesture) {
                  setState(() {});
                },
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: 'http://10.0.2.2:8080/styles/{id}/{z}/{x}/{y}@2x.png',
            additionalOptions: {'id': 'osm-bright'},
          ),
          MarkerLayerOptions(
              markers: currentLocation == null
                  ? []
                  : [
                      Marker(
                          width: 30,
                          height: 30,
                          anchorPos: AnchorPos.align(AnchorAlign.center),
                          point: currentLocation,
                          builder: (context) {
                            return Icon(
                              Icons.my_location,
                              color: Theme.of(context).accentColor,
                            );
                          })
                    ]),
          MarkerLayerOptions(
              markers: mapController.ready
                  ? [
                      Marker(
                          width: 100,
                          height: 100,
                          anchorPos: AnchorPos.align(AnchorAlign.center),
                          point: mapController.center,
                          builder: (context) {
                            return Icon(
                              Icons.add,
                              size: 100,
                              color: Color.fromRGBO(0, 0, 0, 0.5),
                            );
                          })
                    ]
                  : [])
        ],
        mapController: mapController,
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                      'Lat: ${mapController.ready ? mapController.center.latitude.toStringAsPrecision(8) : '-'}',
                      style: Theme.of(context)
                          .primaryTextTheme
                          .body1
                          .apply(fontFamily: 'monospace')),
                  Text(
                      'Lng: ${mapController.ready ? mapController.center.longitude.toStringAsPrecision(8) : '-'}',
                      style: Theme.of(context)
                          .primaryTextTheme
                          .body1
                          .apply(fontFamily: 'monospace')),
                ],
              )
            ),
            Expanded(
              flex: 0,
              child: IconButton(
                tooltip: I18N.of(context).centerButtonTooltip,
                icon: Icon(
                    mapController.ready && currentLocation == mapController.center
                        ? Icons.my_location
                        : Icons.location_searching),
                iconSize: 30.0,
                color: locationEnabled
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).disabledColor,
                onPressed: this.setLocation,
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  IconButton(
                    tooltip: I18N.of(context).zoomIn,
                    icon: Icon(Icons.zoom_in),
                    iconSize: 30.0,
                    color: mapController.ready && mapController.zoom < maxZoom
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).disabledColor,
                    onPressed: () {
                      mapController.move(
                          mapController.center, mapController.zoom + 1);
                    },
                  ),
                  IconButton(
                    tooltip: I18N.of(context).zoomOut,
                    icon: Icon(Icons.zoom_out),
                    iconSize: 30.0,
                    color: mapController.ready && mapController.zoom > minZoom
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).disabledColor,
                    onPressed: () {
                      mapController.move(
                          mapController.center, mapController.zoom - 1);
                    },
                  ),
                ]
              ),
            ),
          ],
        ),
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  void setLocation() {
    location.getLocation().then((LocationData loc) {
      setState(() {
        developer.log('$currentLocation');
        currentLocation = LatLng(loc.latitude, loc.longitude);
        mapController.move(currentLocation, mapController.zoom);
      });
    });
  }

  void onPair() async {
    var settings = await showDialog<ServerSettings>(
      context: context,
      builder: (BuildContext context) {
        return PairingDialog(scaffoldKey: scaffoldKey,);
      },
    );
    if (settings == null) {
      developer.log('no settings');
      return;
    }
    developer.log(settings.toString());
    setState(() {
      this.settings = settings;
    });
  }

  void onPing() {
    setState(() {
      pinging = true;
      Future.delayed(Duration(seconds: 1)).then((_) {
        setState(() {
          pinging = false;
          serverAvailable = true;
        });
        Future.delayed(Duration(seconds: 1)).then((_) {
          setState(() {
            pinging = true;
            Future.delayed(Duration(seconds: 1)).then((_) {
              setState(() {
                pinging = false;
                serverAvailable = false;
              });
            });
          });
        });
      });
    });
  }
}

class Map extends StatefulWidget {
  @override
  MapState createState() => MapState();
}
