// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';
import 'package:location/location.dart';
import 'dart:developer' as developer;

import 'package:poi_map_app/crosshair_plugin.dart';

void main() => runApp(MaterialApp(
  title: 'Černobor POI mapa',
  theme: ThemeData(
    primaryColor: Colors.lightGreen,
  ),
  home: Map(),
));

class MapState extends State<Map> {
  final MapController mapController = MapControllerImpl();
  final Location location = Location();
  final double maxZoom = 20;
  final double minZoom = 7;
  bool locationEnabled = false;
  LatLng currentLocation;

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
      appBar: AppBar(
        /*leading: IconButton(
          icon: Icon(Icons.menu),
          tooltip: 'Menu',
          onPressed: null,
        ),*/
        title: Text('TODO title')
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(50, 14),
          zoom: 13,
          maxZoom: maxZoom,
          minZoom: minZoom,
          debug: true,
          onPositionChanged: !mapController.ready ? null : (MapPosition position, bool hasGesture) {
            setState(() {});
          },
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: 'http://192.168.1.2:8080/styles/{id}/{z}/{x}/{y}@2x.png',
            additionalOptions: {
              'id': 'osm-bright'
            },
          ),
          MarkerLayerOptions(
            markers: currentLocation == null ? [] : [
              Marker(
                width: 30,
                height: 30,
                anchorPos: AnchorPos.align(AnchorAlign.center),
                point: currentLocation,
                builder: (context) {
                  return Icon(Icons.my_location,
                    color: Theme.of(context).accentColor,
                  );
                }
              )
            ]
          ),
          MarkerLayerOptions(
            markers: mapController.ready ? [
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
                }
              )
            ] : []
          )
        ],
        mapController: mapController,
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(5),
            child: FloatingActionButton(
              tooltip: 'Zoom in',
              child: Icon(Icons.zoom_in),
              backgroundColor: mapController.ready && mapController.zoom < maxZoom ? Theme.of(context).accentColor : Theme.of(context).disabledColor,
              onPressed: () {
                mapController.move(mapController.center, mapController.zoom + 1);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(5),
            child: FloatingActionButton(
              tooltip: 'Zoom out',
              child: Icon(Icons.zoom_out),
              backgroundColor: mapController.ready && mapController.zoom > minZoom ? Theme.of(context).accentColor : Theme.of(context).disabledColor,
              onPressed: () {
                mapController.move(mapController.center, mapController.zoom - 1);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(5),
            child: FloatingActionButton(
              tooltip: 'Get current position',
              child: Icon(mapController.ready && currentLocation == mapController.center ? Icons.my_location : Icons.location_searching),
              backgroundColor: locationEnabled ? Colors.red : Colors.black,
              onPressed: this.setLocation,
            ),
          ),
        ],
      ),
      //floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
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
}

class Map extends StatefulWidget {
  @override
  MapState createState() => MapState();
}