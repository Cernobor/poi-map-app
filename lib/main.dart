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
  static const Distance distance = Distance();
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
  Poi infoTarget;
  Poi navigationTarget;

  // settings
  String mapTilesPath;
  ServerSettings settings;
  PoiCollection localPois = PoiCollection('local', <Poi>[]);
  PoiCollection globalPois = PoiCollection('global', <Poi>[]);
  Authors authors = data.Authors();
  data.MapState mapState = data.MapState();
  MapLimits mapLimits;

  Future<dynamic> init;

  @override
  void initState() {
    super.initState();
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
      authors.load().catchError((e) {
        developer.log(e.toString());
        scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('TODO authors'),
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
      appBar: createAppBar(context),
      drawer: createDrawer(context),
      body: createBody(context),
      //floatingActionButton: createZoomControls(context),
      //floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      bottomNavigationBar: createBottomBar(context),
    );
  }

  Widget createAppBar(BuildContext context) {
    return AppBar(
      title: Text(I18N.of(context).appTitle),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: Size(double.infinity, 6.0),
        child: progressValue == -1 ? Container(height: 6.0) : LinearProgressIndicator(
          value: progressValue,
        ),
      ),
    );
  }

  Widget createDrawer(BuildContext context) {
    return Drawer(
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
    );
  }

  Widget createBody(BuildContext context) {
    return Stack(
      children: <Widget>[
        createMap(context),
        if (navigationTarget != null && currentLocation != null)
          Container(
            child: createPoiInfoContentDistance(context),
            alignment: Alignment.bottomCenter,
            constraints: BoxConstraints.expand(),
          ),
        if (infoTarget != null)
          Container(
            child: createPoiInfoContentFull(context),
            alignment: Alignment.bottomCenter,
            constraints: BoxConstraints.expand(),
          ),
        Container(
          alignment: Alignment.center,
          child: IgnorePointer(
            child: Image(
              image: AssetImage('assets/crosshair.png'),
              //width: 201,
              //height: 201,
            )
          )
        ),
        Container(
          child: createZoomControls(context),
          alignment: Alignment.topRight,
          padding: EdgeInsets.all(8.0),
        )
      ],
    );
  }

  Widget createMap(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: mapState?.center,
        zoom: mapState?.zoom?.toDouble() ?? (mapLimits?.zoom?.min?.toDouble()) ?? FALLBACK_MIN_ZOOM,
        maxZoom: mapLimits?.zoom?.max?.toDouble() ?? FALLBACK_MAX_ZOOM,
        minZoom: mapLimits?.zoom?.min?.toDouble() ?? FALLBACK_MIN_ZOOM,
        nePanBoundary: mapLimits?.latLngBounds?.northEast,
        swPanBoundary: mapLimits?.latLngBounds?.southWest,
        onPositionChanged: !mapController.ready
            ? null
            : onMapPositionChanged,
        onTap: onMapTap
      ),
      layers: [
        TileLayerOptions(
            tileProvider: FileTileProvider(),
            urlTemplate: '$mapTilesPath/{z}/{x}/{y}@2x.png',
            backgroundColor: Theme.of(context).primaryColorDark,
            placeholderImage: MemoryImage(kTransparentImage)
        ),
        // limits
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
              ),
            ]
        ),
        // line to target
        if (currentLocation != null && navigationTarget != null)
          PolylineLayerOptions(
            polylines: <Polyline>[
              Polyline(
                points: <LatLng>[
                  currentLocation,
                  navigationTarget.coords,
                ],
                strokeWidth: 5,
                color: Colors.blue
              ),
            ]
          ),
        // current location
        if (currentLocation != null)
          MarkerLayerOptions(
            markers: [
              Marker(
                height: 50,
                width: 50,
                anchorPos: AnchorPos.align(AnchorAlign.center),
                point: currentLocation,
                builder: (context) {
                  if (currentHeading != null && locationSubscription != null) {
                    return Transform.rotate(
                      angle: currentHeading,
                      child: Icon(
                        Icons.navigation,
                        color: Theme.of(context).primaryColorLight,
                        size: 50,
                      ),
                    );
                  }
                  return Icon(
                    Icons.my_location,
                    color: locationSubscription == null
                      ? Theme.of(context).disabledColor
                      : Theme.of(context).primaryColorLight,
                    size: 50,
                  );
                }
              )
            ]
          ),
        // POIs
        MarkerLayerOptions(markers: createMarkers(globalPois)),
        MarkerLayerOptions(markers: createMarkers(localPois)),
      ],
      mapController: mapController,
    );
  }

  List<Marker> createMarkers(data.PoiCollection pois) {
    Color baseColor = Colors.green;
    Color myColor = pois == globalPois ? Colors.blue : Colors.blue.withAlpha(128);
    return pois.pois.map((Poi poi) => Marker(
      point: poi.coords,
      anchorPos: AnchorPos.align(AnchorAlign.top),
      width: 50.0 * (poi == infoTarget ? 1.5 : 1),
      height: 46.0 * (poi == infoTarget ? 1.5 : 1),
      builder: (context) => Container(
        child: GestureDetector(
          onTap: () => this.onPoiTap(poi),
          onLongPress: () => this.onPoiLongPress(poi),
          child: Icon(
            Icons.place,
            size: 50.0 * (poi == infoTarget ? 1.5 : 1),
            color: poi.authorId == settings.id ? myColor : baseColor,
          )
        ),
      ),
    )).toList(growable: false);
  }

  Widget createPoiInfoContentDistance(BuildContext context) {
    var dist = distance.as(LengthUnit.Centimeter, currentLocation, navigationTarget.coords) / 100.0;
    var bearing = distance.bearing(currentLocation, navigationTarget.coords);
    if (bearing < 0) {
      bearing += 360;
    }
    return Card(
      child: InkWell(
        child: Container(
          padding: EdgeInsets.all(8.0),
          child: Text('${dist.toStringAsFixed(2)} m  ${bearing.toStringAsFixed(2)}°',
            textAlign: TextAlign.center,
          )
        ),
        onTap: onPoiInfoDistanceTap,
      )
    );
  }

  Widget createPoiInfoContentFull(BuildContext context) {
    bool isNavigating = navigationTarget != null && currentLocation != null && navigationTarget == infoTarget;
    String latStr = 'Lat: ${infoTarget.coords.latitude.toStringAsFixed(6)}';
    String lngStr = 'Lng: ${infoTarget.coords.longitude.toStringAsFixed(6)}';
    String distStr, brgStr;
    if (isNavigating) {
      distStr = '${I18N.of(context).distance}: ${distance.as(LengthUnit.Centimeter, currentLocation, navigationTarget.coords) / 100.0} m';
      var bearing = distance.bearing(currentLocation, navigationTarget.coords);
      if (bearing < 0) {
        bearing += 360;
      }
      brgStr = '${I18N.of(context).bearing}: ${bearing.toStringAsFixed(1)}°';
    }
    return Dismissible(
      key: Key('fullInfoDismissible'),
      onDismissed: (DismissDirection dd) {
        setState(() {
          infoTarget = null;
        });
      },
      resizeDuration: null,
      child: Card(
        child: Container(
          padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.only(top: 0.0, left: 16.0, right: 16.0, bottom: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${infoTarget.name} (${authors[infoTarget.authorId]})', style: Theme.of(context).textTheme.title),
                    Text('$latStr $lngStr', style: Theme.of(context).textTheme.caption),
                    if (isNavigating)
                      Text('$distStr $brgStr', style: Theme.of(context).textTheme.caption),
                  ],
                ),
              ),
              if (infoTarget.description != null && infoTarget.description.isNotEmpty)
                Container(
                    padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 4.0),
                    child: Text(infoTarget.description)
                ),
              Container(
                padding: EdgeInsets.zero,
                height: 30,
                margin: EdgeInsets.zero,
                child: ButtonTheme.bar(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      MaterialButton(
                        child: Text(
                            (navigationTarget == infoTarget ? I18N.of(context).stopNavigationButton : I18N.of(context).navigateToButton).toUpperCase()
                        ),
                        onPressed: currentLocation == null ? null : () => this.onPoiInfoNavigate(infoTarget),
                      ),
                      MaterialButton(
                        child: Text(I18N.of(context).deleteButton.toUpperCase()),
                        onPressed: infoTarget.id != null ? null : () => this.onDeletePoi(infoTarget),
                      ),
                      MaterialButton(
                        child: Text(I18N.of(context).centerViewPoiInfoButton.toUpperCase()),
                        onPressed: () => this.onCenterViewPoi(infoTarget),
                      )
                    ],
                  ),
                )
              )
            ]
          )
        )
      )
    );
  }

  Widget createZoomControls(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(bottom: 6),
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
          padding: EdgeInsets.only(top: 6),
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
    );
  }

  Widget createBottomBar(BuildContext context) {
    return BottomAppBar(
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
            //developer.log('Continuous location: ${loc.latitude} ${loc.longitude}');
            setState(() {
              currentLocation = LatLng(loc.latitude, loc.longitude);
              onCurrentLocation();
            });
          });
      compassSubscription = FlutterCompass.events.listen((double heading) {
        //developer.log('Heading: $heading');
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
    Map<int, String> authors;
    try {
      var data = await comm.downloadPoiData(settings.serverAddress);
      authors = data.a;
      pois = data.b;
    } on comm.CommException catch (e) {
      await commErrorDialog(e, context);
      return;
    }
    await globalPois.set(pois);
    await this.authors.set(authors);
    setState(() {});
  }

  void onUpload() async {
    developer.log('onUpload');
    try {
      await comm.uploadPois(settings.serverAddress, localPois);
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
      await comm.uploadPois(settings.serverAddress, localPois);
    } on comm.CommException catch (e) {
      await commErrorDialog(e, context);
      return;
    }
    List<Poi> pois;
    Map<int, String> authors;
    try {
      var data = await comm.downloadPoiData(settings.serverAddress);
      authors = data.a;
      pois = data.b;
    } on comm.CommException catch (e) {
      await commErrorDialog(e, context);
      return;
    }
    await globalPois.set(pois);
    await localPois.set([]);
    await this.authors.set(authors);
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

  void onMapTap(LatLng coords) {
    developer.log('onMapTap: $coords');
    setState(() {
      infoTarget = null;
    });
  }

  void onPoiTap(Poi poi) {
    developer.log('Poi ${poi.name} tap.');
    setState(() {
      if (infoTarget == poi) {
        infoTarget = null;
      } else {
        infoTarget = poi;
      }
    });
  }

  void onPoiLongPress(Poi poi) {
    developer.log('Poi ${poi.name} long press.');
    toggleNavigation(poi);
  }

  void onPoiInfoNavigate(Poi poi) {
    developer.log('onPoiInfoNavigate: ${poi.name}');
    toggleNavigation(poi);
  }

  void onPoiInfoDistanceTap() {
    developer.log('onPoiInfoDistanceTap');
    setState(() {
      infoTarget = navigationTarget;
    });
  }

  void onDeletePoi(Poi toDelete) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(I18N.of(context).areYouSure),
          content: Text('${I18N.of(context).aboutToDeletePoi}:\n'
              'Lat: ${toDelete.coords.latitude.toStringAsFixed(6)}\n'
              'Lng: ${toDelete.coords.latitude.toStringAsFixed(6)}\n'
              '${toDelete.description ?? ''}'),
          actions: <Widget>[
            FlatButton(
              child: Text(I18N.of(context).yes.toUpperCase()),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            FlatButton(
              child: Text(I18N.of(context).no.toUpperCase()),
              onPressed: () => Navigator.of(context).pop(false),
            )
          ],
        );
      }
    );
    if (!confirmed) {
      return;
    }
    await localPois.delete(toDelete);
    setState(() {
      if (infoTarget == toDelete) {
        infoTarget = null;
      }
      if (navigationTarget == toDelete) {
        navigationTarget = null;
      }
    });
  }

  void onCenterViewPoi(Poi target) {
    mapController.move(target.coords, mapController.zoom);
  }

  void toggleNavigation(Poi poi) {
    setState(() {
      if (navigationTarget == poi) {
        navigationTarget = null;
      } else {
        navigationTarget = poi;
      }
    });
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