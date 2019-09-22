// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';
import 'package:location/location.dart';
import 'package:poi_map_app/AddPoiDialog.dart';
import 'package:poi_map_app/PairingDialog.dart';
import 'package:poi_map_app/communication.dart' as comm;
import 'package:poi_map_app/data.dart' as data;
import 'package:poi_map_app/utils.dart';
import 'package:transparent_image/transparent_image.dart';

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
  // constants
  static const double FALLBACK_MIN_ZOOM = 1;
  static const double FALLBACK_MAX_ZOOM = 18;
  // "constants"
  final MapController mapController = MapControllerImpl();
  final Location location = Location();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // handling flags and values
  double progressValue = -1;
  bool pinging = false;
  bool serverAvailable = false;
  StreamSubscription<LocationData> locationSubscription;
  StreamSubscription<double> compassSubscription;
  bool viewLockedToLocation = false;
  LatLng currentLocation;
  double currentHeading;

  // settings
  String mapTilesPath;
  ServerSettings settings;
  PoiCollection localPois = PoiCollection('local', <Poi>[]);
  PoiCollection globalPois = PoiCollection('global', <Poi>[]);
  data.MapState mapState = data.MapState();
  MapLimits mapLimits;

  Future<dynamic> init;

  @override
  void initState() {
    init = Future.delayed(Duration(seconds: 5), () => Future.wait([
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
      }),
      localPois.load().catchError((e) {
        developer.log(e.toString());
        scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('TODO local'),
          duration: Duration(seconds: 5),
        ));
      }),
      globalPois.load().catchError((e) {
        developer.log(e.toString());
        scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('TODO global'),
          duration: Duration(seconds: 5),
        ));
      }),
      mapState.load().then((_) {
        mapController.move(mapState.center, mapState.zoom.toDouble());
      }).catchError((e) {
        developer.log(e.toString());
      }),
      getMapPath().then((String path) {
        developer.log('Map path: $path');
        setState(() {
          mapTilesPath = path;
        });
      }),
      getMapLimits().then((MapLimits mapLimits) {
        this.mapLimits = mapLimits;
      }).catchError((e) {
        developer.log(e.toString());
        scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('TODO map limits'),
          duration: Duration(seconds: 5),
        ));
      })
    ]));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: init,
      initialData: false,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.data == false) {
          return Container(
            child: Center(
              child: Image(
                image: AssetImage('assets/splash.png'),
                width: 320.0,
                height: 362.0,
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor
            ),
          );
        }
        return createUi(context);
      }
    );
  }

  Widget createUi(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      primary: true,
      appBar: AppBar(
        title: Text(I18N.of(context).appTitle),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size(double.infinity, 6.0),
          child: progressValue == -1 ? Container(height: 6.0) : LinearProgressIndicator(
            value: progressValue,
          ),
        ),
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
              title: Text(I18N.of(context).downloadMap),
              enabled: settings != null,
              leading: Icon(Icons.map),
              onTap: onDownloadMap
            ),
            ListTile(
              title: Text(I18N.of(context).sync),
              leading: Icon(Icons.sync),
              enabled: settings != null,
              onTap: onSync,
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SimpleDialog(
                      children: <Widget>[
                        ListTile(
                          title: Text(I18N.of(context).download),
                          leading: Icon(Icons.cloud_download),
                          enabled: settings != null,
                          onTap: () {
                            onDownload();
                            Navigator.of(context).pop();
                          },
                        ),
                        ListTile(
                          title: Text(I18N.of(context).upload),
                          leading: Icon(Icons.cloud_upload),
                          enabled: settings != null,
                          onTap: () {
                            onUpload();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  }
                );
              },
            ),
            ListTile(
              title: Text(I18N.of(context).logPoiCurrentLocation),
              leading: Icon(Icons.my_location),
              onTap: () => onLogPoi(LogPoiType.currentLocation),
              enabled: settings != null && currentLocation != null,
            ),
            ListTile(
              title: Text(I18N.of(context).logPoiCrosshair),
              leading: Icon(Icons.add),
              onTap: () => onLogPoi(LogPoiType.crosshair),
              enabled: settings != null,
            ),
            ListTile(
              title: Text(I18N.of(context).clearLocalPois),
              leading: Icon(Icons.clear),
              onTap: () => onClearLocalPois()
            )
          ],
        ),
      ),
      body: FlutterMap(
        options: MapOptions(
          center: mapState?.center,
          zoom: mapState?.zoom?.toDouble() ?? (mapLimits?.zoom?.min?.toDouble()) ?? FALLBACK_MIN_ZOOM,
          maxZoom: mapLimits?.zoom?.max?.toDouble() ?? FALLBACK_MAX_ZOOM,
          minZoom: mapLimits?.zoom?.min?.toDouble() ?? FALLBACK_MIN_ZOOM,
          nePanBoundary: mapLimits?.latLngBounds?.northEast,
          swPanBoundary: mapLimits?.latLngBounds?.southWest,
          debug: true,
          onPositionChanged: !mapController.ready
              ? null
              : onMapPositionChanged,
        ),
        layers: [
          TileLayerOptions(
            tileProvider: FileTileProvider(),
            urlTemplate: '$mapTilesPath/{z}/{x}/{y}@2x.png',
            backgroundColor: Theme.of(context).primaryColorDark,
            placeholderImage: MemoryImage(kTransparentImage)
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
                    if (currentHeading != null && locationSubscription != null) {
                      return Transform.rotate(
                        angle: currentHeading,
                        child: Icon(
                          Icons.navigation,
                          color: Theme.of(context).primaryColorLight,
                          size: 30,
                        ),
                      );
                    }
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
          ),
          MarkerLayerOptions(
              markers: globalPois.pois.map((Poi poi) {
                return Marker(
                  point: poi.coords,
                  anchorPos: AnchorPos.align(AnchorAlign.top),
                  width: 50, height: 46,
                  builder: (context) {
                    return IconButton(
                      icon: Icon(Icons.place),
                      color: Colors.red,
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
          ),
          PolylineLayerOptions(
            polylines: mapLimits == null ? [] : <Polyline>[
              Polyline(
                points: <LatLng>[
                  LatLng(mapLimits.lat.min, mapLimits.lng.min),
                  LatLng(mapLimits.lat.min, mapLimits.lng.max),
                  LatLng(mapLimits.lat.max, mapLimits.lng.max),
                  LatLng(mapLimits.lat.max, mapLimits.lng.min),
                  LatLng(mapLimits.lat.min, mapLimits.lng.min),
                ],
                strokeWidth: 5,
                color: Colors.red
              )
            ]
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
              backgroundColor: mapController.ready && mapController.zoom < (mapLimits?.zoom?.max ?? FALLBACK_MAX_ZOOM)
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
              backgroundColor: mapController.ready && mapController.zoom > (mapLimits?.zoom?.min ?? FALLBACK_MIN_ZOOM)
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
    mapState.set(
      center: mapController.center,
      zoom: mapController.zoom.round()
    );
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
      compassSubscription = FlutterCompass.events.listen((double heading) {
        developer.log('Heading: $heading');
        setState(() {
          currentHeading = math.pi * heading / 180.0;
        });
      });
      developer.log('Compass subscription: $compassSubscription');
    } else {
      locationSubscription.cancel();
      setState(() {
        locationSubscription = null;
      });
      compassSubscription.cancel();
      compassSubscription = null;
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
      comm.ping(settings.serverAddress).then((bool pong) {
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

  void onDownloadMap() async {
    developer.log('onDownloadMap');
    Navigator.of(context).pop();
    // download
    var res = await comm.downloadMap(settings.serverAddress, settings.tilePackPath);
    var length = res.a;
    var data = res.b;
    var received = 0;
    var stream = data.map(length != null ? (chunk) {
      received += chunk.length;
      //developer.log('Received $received of ${length} bytes.');
      setState(() {
        progressValue = received / length;
      });
      return chunk;
    } : (chunk) {
      received += chunk.length;
      //developer.log('Received $received bytes.');
      return chunk;
    });
    scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(I18N.of(context).downloadingMapSnackBar),
      duration: Duration(seconds: 3),
    ));
    await saveTilePackRaw(stream);

    // unpack
    setState(() {
      progressValue = 0;
    });
    scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(I18N.of(context).unpackingMapSnackBar),
      duration: Duration(seconds: 3),
    ));
    await unpackTilePack((int n, int total) {
      var p = n.toDouble() / total.toDouble();
      setState(() {
        progressValue = p;
      });
    });

    // get and focus on map center
    var mapLimits = await getMapLimits();
    mapController.fitBounds(mapLimits.latLngBounds);
    if (mapController.zoom < mapLimits.zoom.min) {
      mapController.move(mapController.center, mapLimits.zoom.min.toDouble());
    } else if (mapController.zoom > mapLimits.zoom.max) {
      mapController.move(mapController.center, mapLimits.zoom.max.toDouble());
    }
    setState(() {
      this.mapLimits = mapLimits;
    });

    // done
    setState(() {
      progressValue = -1;
    });
    scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(I18N.of(context).doneMapSnackBar),
      duration: Duration(seconds: 3),
    ));
  }

  void onDownload() async {
    developer.log('onDownload');
    List<Poi> pois;
    try {
      pois = await comm.download(settings.serverAddress);
    } on comm.CommException catch (e) {
      await commErrorDialog(e, context);
      return;
    }
    await globalPois.set(pois);
    setState(() {});
  }

  void onUpload() async {
    developer.log('onUpload');
    try {
      await comm.upload(settings.serverAddress, localPois);
    } on comm.CommException catch (e) {
      await commErrorDialog(e, context);
      return;
    }
    await localPois.set([]);
    setState(() {});
  }

  void onSync() async {
    developer.log('onSync');
    try {
      await comm.upload(settings.serverAddress, localPois);
    } on comm.CommException catch (e) {
      await commErrorDialog(e, context);
      return;
    }
    List<Poi> pois;
    try {
      pois = await comm.download(settings.serverAddress);
    } on comm.CommException catch (e) {
      await commErrorDialog(e, context);
      return;
    }
    await globalPois.set(pois);
    await localPois.set([]);
    setState(() {});
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

  void onClearLocalPois() async {
    await localPois.set([]);
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