import 'dart:convert';
import 'dart:io';

import 'package:latlong/latlong.dart';
import 'package:path_provider/path_provider.dart';

class ServerSettings {
  static const String _FILE = 'serverSettings.json';

  final String serverAddress;
  final String name;
  final int id;
  final String tilePackPath;

  ServerSettings({this.serverAddress, this.name, this.id, this.tilePackPath});

  static Future<ServerSettings> load() async {
    final path = await _localPath;
    final file = File('$path/$_FILE');
    Map<String, dynamic> data = jsonDecode(await file.readAsString());
    return ServerSettings(
      serverAddress: data['serverAddress'],
      name: data['name'],
      id: data['id'],
      tilePackPath: data['tilePackPath']
    );
  }

  save() async {
    final path = await _localPath;
    final file = File('$path/$_FILE');
    file.writeAsString(encoder.convert({
      'serverAddress': serverAddress,
      'name': name,
      'id': id,
      'tilePackPath': tilePackPath
    }));
  }

  @override
  String toString() {
    return 'ServerSettings{serverAddress: $serverAddress, name: $name, id: $id, tilePackPath: $tilePackPath}';
  }
}

class Poi {
  final int id;
  final int authorId;
  final String name;
  final String description;
  final LatLng coords;

  Poi(this.id, this.authorId, this.name, this.description, this.coords);

  Map<String, dynamic> asGeoJson() {
    return {
      'type': 'Feature',
      'geometry': {
        'coordinates': [coords.longitude, coords.latitude],
        'type': 'Point',
      },
      'properties': {
        'id': id,
        'author_id': authorId,
        'name': name,
        'description': description,
      },
    };
  }

  static Poi fromGeoJson(Map<String, dynamic> json) {
    return Poi(
      json['properties']['id'],
      json['properties']['author_id'],
      json['properties']['name'],
      json['properties']['description'],
      LatLng(
        (json['geometry']['coordinates'][1] as num).toDouble(),
        (json['geometry']['coordinates'][0] as num).toDouble()
      )
    );
  }
}

class PoiCollection {
  final String name;
  final List<Poi> pois;

  PoiCollection(this.name, this.pois);

  save() async {
    final path = await _localPath;
    final file = File('$path/pois-$name.json');
    file.writeAsString(encoder.convert(asGeoJsonList()));
  }

  Future<void> load() async {
    final path = await _localPath;
    final file = File('$path/pois-$name.json');
    List<dynamic> data = jsonDecode(await file.readAsString());
    pois.clear();
    pois.addAll(data.map((p) => Poi.fromGeoJson(p as Map<String, dynamic>)));
  }

  add(Poi poi) async {
    pois.add(poi);
    await save();
  }

  set(List<Poi> pois) async {
    this.pois.clear();
    this.pois.addAll(pois);
    await save();
  }

  List<Map<String, dynamic>> asGeoJsonList() {
    return pois.map((Poi poi) => poi.asGeoJson()).toList(growable: false);
  }
}

Future<String> get _localPath async {
  final dir = await getApplicationDocumentsDirectory();
  return dir.path;
}

const JsonEncoder encoder = JsonEncoder.withIndent(' ');