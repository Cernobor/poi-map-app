import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:more/math.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poi_map_app/utils.dart';

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

class MapLimits {
  final Range<int> zoom;
  final Range<int> x;
  final Range<int> y;
  final Range<double> lat;
  final Range<double> lng;

  MapLimits(this.zoom, this.x, this.y)
    : lat = Range(_y2lat(y.max, pow(2.0, zoom.max)), _y2lat(y.min, pow(2.0, zoom.max)))
    , lng = Range(_x2lng(x.min, pow(2.0, zoom.max)), _x2lng(x.max, pow(2.0, zoom.max)));

  LatLngBounds get latLngBounds => LatLngBounds(LatLng(lat.min, lng.min), LatLng(lat.max, lng.max));

  static _y2lat(int y, double trz) => atan(sinh(pi - 2 * pi * y / trz)) * 180 / pi;
  static _x2lng(int x, double trz) => x * 360 / trz - 180;
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

  Map<String, dynamic> asMap() {
    return {
      'id': id,
      'author_id': authorId,
      'name': name,
      'description': description,
      'lat': coords.latitude,
      'lng': coords.longitude
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

  delete(Poi poi) async {
    if (!pois.remove(poi)) {
      throw IllegalStateException('Attempted to remove poi that was not in poi collection.');
    }
    await save();
  }

  List<Map<String, dynamic>> asGeoJsonList() {
    return pois.map((Poi poi) => poi.asGeoJson()).toList(growable: false);
  }

  List<Map<String, dynamic>> asMapList() {
    return pois.map((Poi poi) => poi.asMap()).toList(growable: false);
  }
}

class Authors {
  final Map<int, String> _authors;

  Authors() : _authors = HashMap();

  save() async {
    final path = await _localPath;
    final file = File('$path/authors.json');
    file.writeAsString(encoder.convert(_authors.map((int id, String name) => MapEntry<String, String>(id.toString(), name))));
  }

  Future<void> load() async {
    final path = await _localPath;
    final file = File('$path/authors.json');
    Map<String, String> data = jsonDecode(await file.readAsString());
    _authors.clear();
    _authors.addAll(data.map((String id, String name) => MapEntry<int, String>(int.parse(id), name)));
  }

  set(Map<int, String> authors) async {
    this._authors.clear();
    this._authors.addAll(authors);
    await save();
  }

  String operator[](int authorId) => _authors[authorId];
}

class MapState {
  static const String _FILE = 'mapState.json';
  LatLng _center;
  int _zoom;

  MapState() : _center = null, _zoom = null;
  MapState._(this._center, this._zoom);

  Future<void> load() async {
    final path = await _localPath;
    final file = File('$path/$_FILE');
    Map<String, dynamic> data = jsonDecode(await file.readAsString());
    _center = LatLng(data['lat'], data['lng']);
    _zoom = data['zoom'];
  }

  save() async {
    final path = await _localPath;
    final file = File('$path/$_FILE');
    file.writeAsString(encoder.convert({
      'lat': _center.latitude,
      'lng': _center.longitude,
      'zoom': _zoom
    }));
  }

  LatLng get center => _center;
  int get zoom => _zoom;

  Future<void> set({LatLng center, int zoom}) async {
    bool changed = false;
    if (center != null && center != _center) {
      _center = center;
      changed = true;
    }
    if (zoom != null && zoom != _zoom) {
      _zoom = zoom;
      changed = true;
    }
    if (changed) {
      await save();
    }
  }
}

Future<void> saveTilePackRaw(Stream<List<int>> zipStream) async {
  final path = await _localPath;
  final file = File(_getMapZipPath(path));
  var sink = file.openWrite();
  await zipStream.pipe(sink);
}

Future<void> unpackTilePack(Function(int, int) onProgress) async {
  final path = await _localPath;
  final archiveFile = File(_getMapZipPath(path));
  final mapPath = _getMapPath(path);
  final mapDir = Directory(mapPath);
  if (mapDir.existsSync()) {
    mapDir.deleteSync(recursive: true);
  }
  Archive archive = ZipDecoder().decodeBytes(await archiveFile.readAsBytes());
  int n = 1;
  for (ArchiveFile file in archive) {
    if (file.isFile) {
      var f = File('$mapPath/${file.name}');
      await f.create(recursive: true);
      await f.writeAsBytes(file.content);
    }
    onProgress(n++, archive.length);
  }
  await archiveFile.delete();
}

String _getMapZipPath(String basePath) {
  return '$basePath/tilePack.zip';
}

String _getMapPath(String basePath) {
  return '$basePath/mapData';
}

Future<String> getMapPath() async {
  final path = await _localPath;
  return '$path/mapData';
}

Future<MapLimits> getMapLimits() async {
  final mapPath = _getMapPath(await _localPath);
  Range<int> minMaxZ = await Directory(mapPath).list()
      .where((FileSystemEntity e) => e.statSync().type == FileSystemEntityType.directory)
      .map((FileSystemEntity e) => e.uri.pathSegments.lastWhere((String s) => s.isNotEmpty))
      .map(int.tryParse)
      .fold(Range.nil(0), Range.merged);
  Range<int> minMaxX = await Directory('$mapPath/${minMaxZ.max}').list()
      .where((FileSystemEntity e) => e.statSync().type == FileSystemEntityType.directory)
      .map((FileSystemEntity e) => e.uri.pathSegments.lastWhere((String s) => s.isNotEmpty))
      .map(int.tryParse)
      .fold(Range.nil(0), Range.merged);
  Range<int> minXminMaxY = await Directory('$mapPath/${minMaxZ.max}/${minMaxX.min}').list()
      .where((FileSystemEntity e) => e.statSync().type == FileSystemEntityType.file)
      .map((FileSystemEntity e) => e.uri.pathSegments.lastWhere((String s) => s.isNotEmpty))
      .where((String s) => s.endsWith('@2x.png'))
      .map((String s) => s.substring(0, s.length - '@2x.png'.length))
      .map(int.tryParse)
      .fold(Range.nil(0), Range.merged);
  Range<int> maxXminMaxY = await Directory('$mapPath/${minMaxZ.max}/${minMaxX.max}').list()
      .where((FileSystemEntity e) => e.statSync().type == FileSystemEntityType.file)
      .map((FileSystemEntity e) => e.uri.pathSegments.lastWhere((String s) => s.isNotEmpty))
      .where((String s) => s.endsWith('@2x.png'))
      .map((String s) => s.substring(0, s.length - '@2x.png'.length))
      .map(int.tryParse)
      .fold(Range.nil(0), Range.merged);
  if (minXminMaxY != maxXminMaxY) {
    throw IllegalStateException('Minimum and maximum Y tiles are different for minimum and maximum X.');
  }
  return MapLimits(minMaxZ, minMaxX, minXminMaxY);
}

Future<String> get _localPath async {
  final dir = await getApplicationDocumentsDirectory();
  return dir.path;
}

const JsonEncoder encoder = JsonEncoder.withIndent(' ');