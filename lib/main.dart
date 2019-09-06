// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';
import 'package:location/location.dart';
import 'package:poi_map_app/AddPoiDialog.dart';
import 'package:poi_map_app/PairingDialog.dart';
import 'package:poi_map_app/communication.dart';

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
      home: MainWidget(),
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

class MainWidgetState extends State<MainWidget> {
  final MapController mapController = MapControllerImpl();
  final Location location = Location();
  final double maxZoom = 20;
  final double minZoom = 1;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  StreamSubscription<LocationData> locationSubscription;
  bool viewLockedToLocation = false;
  LatLng currentLocation;

  bool pinging = false;
  bool serverAvailable = false;

  ServerSettings settings;
  PoiCollection localPois = PoiCollection('local', <Poi>[]);
  PoiCollection globalPois = PoiCollection('global', <Poi>[]);

  @override
  void initState() {
    ServerSettings.load().then((ServerSettings settings) {
      setState(() {
        this.settings = settings;
        startPinging();
      });
    }).catchError((e) {
      developer.log(e.toString());
      scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('TODO settings'),
        duration: Duration(seconds: 5),
      ));
    });
    localPois.load().catchError((e) {
      developer.log(e.toString());
      scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('TODO local'),
        duration: Duration(seconds: 5),
      ));
    });
    globalPois.load().catchError((e) {
      developer.log(e.toString());
      scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('TODO global'),
        duration: Duration(seconds: 5),
      ));
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
              onTap: onPing,
            ),
            ListTile(
              title: Text(I18N.of(context).logPoiCurrentLocation),
              leading: Icon(Icons.my_location),
              onTap: () => onLogPoi(LogPoiType.currentLocation),
              enabled: currentLocation != null,
            ),
            ListTile(
              title: Text(I18N.of(context).logPoiCrosshair),
              leading: Icon(Icons.add),
              onTap: () => onLogPoi(LogPoiType.crosshair),
            )
          ],
        ),
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(50.071213, 14.479101),
          zoom: 20,
          maxZoom: maxZoom,
          minZoom: minZoom,
          debug: true,
          onPositionChanged: !mapController.ready
              ? null
              : onMapPositionChanged,
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
                  height: 30,
                  width: 30,
                  anchorPos: AnchorPos.align(AnchorAlign.center),
                  point: currentLocation,
                  builder: (context) {
                    return Icon(
                      Icons.my_location,
                      color: locationSubscription == null
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).primaryColorLight,
                      size: 30,
                    );
                  }
                )
              ]
          ),
          MarkerLayerOptions(
            markers: mapController.ready
              ? [
                Marker(
                  width: 201,
                  height: 201,
                  anchorPos: AnchorPos.align(AnchorAlign.center),
                  point: mapController.center,
                  builder: (context) {
                    return Image(
                      image: AssetImage('assets/crosshair.png'),
                      //width: 201,
                      //height: 201,
                      fit: BoxFit.fill,
                    );
                  })
                ]
              : []
          ),
          MarkerLayerOptions(
            markers: localPois.pois.map((Poi poi) {
              return Marker(
                point: poi.coords,
                anchorPos: AnchorPos.align(AnchorAlign.top),
                width: 50, height: 46,
                builder: (context) {
                  return IconButton(
                    icon: Icon(Icons.place),
                    color: Colors.blue,
                    iconSize: 50,
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      developer.log('Marker ${poi.name} pressed.');
                    },
                    tooltip: poi.name,
                  );
                },
              );
            }).toList(growable: false)
          )
        ],
        mapController: mapController,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: FloatingActionButton(
              tooltip: I18N.of(context).zoomIn,
              child: Icon(Icons.zoom_in, size: 30,),
              backgroundColor: mapController.ready && mapController.zoom < maxZoom
                  ? Theme.of(context).accentColor
                  : Theme.of(context).disabledColor,
              onPressed: () {
                mapController.move(
                    mapController.center, mapController.zoom + 1);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: FloatingActionButton(
              tooltip: I18N.of(context).zoomOut,
              child: Icon(Icons.zoom_out, size: 30,),
              backgroundColor: mapController.ready && mapController.zoom > minZoom
                  ? Theme.of(context).accentColor
                  : Theme.of(context).disabledColor,
              onPressed: () {
                mapController.move(
                    mapController.center, mapController.zoom - 1);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              flex: 0,
              child: Table(
                defaultColumnWidth: IntrinsicColumnWidth(),
                children: <TableRow>[
                  TableRow(
                    children: <Widget>[
                      Container(),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                        alignment: Alignment.center,
                        child: Text('GPS', style: Theme.of(context).primaryTextTheme.body1.apply(fontFamily: 'monospace'),)
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                        alignment: Alignment.center,
                        child: Text('TGT', style: Theme.of(context).primaryTextTheme.body1.apply(fontFamily: 'monospace'),),
                      )
                    ]
                  ),
                  TableRow(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                        alignment: Alignment.centerLeft,
                        child: Text('Lat', style: Theme.of(context).primaryTextTheme.body1.apply(fontFamily: 'monospace'),),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                        alignment: Alignment.centerLeft,
                        child: Text(currentLocation == null ? '-' : currentLocation.latitude.toStringAsPrecision(8), style: Theme.of(context).primaryTextTheme.body1.apply(fontFamily: 'monospace'),),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                        alignment: Alignment.centerLeft,
                        child: Text(!mapController.ready ? '-' : mapController.center.latitude.toStringAsPrecision(8), style: Theme.of(context).primaryTextTheme.body1.apply(fontFamily: 'monospace'),),
                      ),
                    ]
                  ),
                  TableRow(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                        alignment: Alignment.centerLeft,
                        child: Text('Lng', style: Theme.of(context).primaryTextTheme.body1.apply(fontFamily: 'monospace'),),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                        alignment: Alignment.centerLeft,
                        child: Text(currentLocation == null ? '-' : currentLocation.longitude.toStringAsPrecision(8), style: Theme.of(context).primaryTextTheme.body1.apply(fontFamily: 'monospace'),),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                        alignment: Alignment.centerLeft,
                        child: Text(!mapController.ready ? '-' : mapController.center.longitude.toStringAsPrecision(8), style: Theme.of(context).primaryTextTheme.body1.apply(fontFamily: 'monospace'),),
                      ),
                    ]
                  )
                ],
              ),
            ),
            Expanded(
              flex: 0,
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: I18N.of(context).locationContinuousButtonTooltip,
                    icon: Icon(
                        locationSubscription == null
                            ? Icons.location_off
                            : Icons.location_on),
                    iconSize: 30.0,
                    color: Theme.of(context).colorScheme.onPrimary,
                    onPressed: onToggleLocationContinuous,
                  ),
                  IconButton(
                    tooltip: I18N.of(context).lockViewToLocationButtonTooltip,
                    icon: Icon(
                        viewLockedToLocation
                            ? Icons.gps_fixed
                            : Icons.gps_not_fixed),
                    iconSize: 30.0,
                    color: currentLocation == null
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).colorScheme.onPrimary,
                    onPressed: currentLocation == null
                        ? null
                        : onLockViewToLocation,
                  ),
                ],
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
      developer.log('One-time location: ${loc.latitude} ${loc.longitude}');
      setState(() {
        currentLocation = LatLng(loc.latitude, loc.longitude);
        onCurrentLocation();
      });
    });
  }

  void onLockViewToLocation() {
    setState(() {
      viewLockedToLocation = true;
      mapController.move(currentLocation, mapController.zoom);
    });
  }

  void onMapPositionChanged(MapPosition position, bool hasGesture) {
    if (mapController.center != currentLocation) {
      setState(() {
        viewLockedToLocation = false;
      });
    }
  }

  void onToggleLocationContinuous() {
    if (locationSubscription == null) {
      locationSubscription =
          location.onLocationChanged().listen((LocationData loc) {
            developer.log('Continuous location: ${loc.latitude} ${loc.longitude}');
            setState(() {
              currentLocation = LatLng(loc.latitude, loc.longitude);
              onCurrentLocation();
            });
          });
    } else {
      locationSubscription.cancel();
      setState(() {
        locationSubscription = null;
      });
    }
  }

  void onCurrentLocation() {
    if (viewLockedToLocation) {
      mapController.move(currentLocation, mapController.zoom);
    }
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
      this.settings.save();
    });
    startPinging();
  }

  void onPing() async {
    setState(() {
      pinging = true;
      ping(settings.serverAddress).then((bool pong) {
        setState(() {
          pinging = false;
          serverAvailable = pong;
        });
      });
    });
  }

  void startPinging() {
    onPing();
    Future.doWhile(() {
      if (settings == null) {
        return Future.value(true);
      }
      return Future.delayed(Duration(seconds: 5), () {
        onPing();
        return true;
      });
    });
  }

  void onLogPoi(LogPoiType type) async {
    developer.log('Log poi $type');
    LatLng loc;
    switch (type) {
      case LogPoiType.currentLocation:
        loc = currentLocation;
        break;
      case LogPoiType.crosshair:
        loc = mapController.center;
        break;
    }
    Map<String, String> info = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AddPoiDialog(location: loc);
      }
    );
    if (info == null) {
      return;
    }
    Navigator.pop(context);
    await localPois.add(Poi(null, settings.id, info['name'], info['description'], loc));
    setState(() {});
  }
}

class MainWidget extends StatefulWidget {
  @override
  MainWidgetState createState() => MainWidgetState();
}

enum LogPoiType {
  currentLocation,
  crosshair
}