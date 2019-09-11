import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:poi_map_app/data.dart';
import 'package:poi_map_app/utils.dart';

class CommException implements Exception {
  final Uri uri;
  final String name;
  final Map<String, dynamic> fullError;

  CommException(this.uri, this.name, this.fullError);

  @override
  String toString() {
    return 'CommException{uri: $uri, name: $name, fullError: $fullError}';
  }

  static const String nameNotSupplied = 'nameNotSupplied';
  static const String nameAlreadyExists = 'nameAlreadyExists';
  static const String malformedData = 'malformedData';
  static const String invalidData = 'invalidData';
}

class HandshakeResponse {
  final int id;
  final String name;
  final String tilePackPath;

  HandshakeResponse._(this.id, this.name, this.tilePackPath);

  factory HandshakeResponse.fromJson(Map<String, dynamic> json) {
    return HandshakeResponse._(json['id'], json['name'], json['tilePackPath']);
  }

  @override
  String toString() {
    return 'HandshakeResponse{id: $id, name: $name, tilePackPath: $tilePackPath}';
  }
}

enum Method {
  GET, POST
}

Future<dynamic> _handle(Uri uri, {Method method = Method.GET, Map<String, String> headers, dynamic body}) async {
  http.Response res;
  switch (method) {
    case Method.GET:
      res = await http.get(uri, headers: headers);
      break;
    case Method.POST:
      res = await http.post(uri, headers: headers, body: body);
      break;
  }
  if (res.statusCode == HttpStatus.ok) {
    var body = jsonDecode(res.body);
    if (body is Map<String, dynamic> && body.containsKey('error')) {
      throw CommException(uri, body['error'], body);
    } else {
      return body;
    }
  } else {
    throw CommException(uri, 'Request refused. Code ${res.statusCode}', null);
  }
}

Future<void> _handleVoid(Uri uri, {Method method = Method.GET, Map<String, String> headers, dynamic body}) async {
  http.Response res;
  switch (method) {
    case Method.GET:
      res = await http.get(uri, headers: headers);
      break;
    case Method.POST:
      res = await http.post(uri, headers: headers, body: body);
      break;
  }
  if (res.statusCode == HttpStatus.ok) {
    return;
  } else {
    throw CommException(uri, 'Request refused. Code ${res.statusCode}', null);
  }
}

String _cleanupAddress(String address) {
  if (address.startsWith('http://')) {
    return address.substring('http://'.length);
  }
  return address;
}

Future<HandshakeResponse> handshake(String serverAddress, String name) async {
  var uri = Uri.http(_cleanupAddress(serverAddress), 'handshake', {'name': name});
  var data = await _handle(uri) as Map<String, dynamic>;
  return HandshakeResponse.fromJson(data);
}

Future<bool> ping(String serverAddress) async {
  var uri = Uri.http(_cleanupAddress(serverAddress), 'ping');
  try {
    await _handleVoid(uri);
    return true;
  } catch (_) {
    return false;
  }
}

Future<Tuple<int, http.ByteStream>> downloadMap(String serverAddress, String tilePackPath) async {
  var uri = Uri.http(_cleanupAddress(serverAddress), tilePackPath);
  var req = http.Request('GET', uri);
  var res = await req.send();
  if (res.statusCode != HttpStatus.ok) {
    throw CommException(uri, 'Request refused. Code: ${res.statusCode}', null);
  }
  return Tuple(res.contentLength, res.stream);
}

Future<List<Poi>> download(String serverAddress) async {
  var uri = Uri.http(_cleanupAddress(serverAddress), 'poi');
  var data = await _handle(uri) as List;
  return data.cast<Map<String, dynamic>>().map((Map<String, dynamic> poi) => Poi.fromGeoJson(poi)).toList(growable: false);
}

Future<void> upload(String serverAddress, PoiCollection collection) async {
  var uri = Uri.http(_cleanupAddress(serverAddress), 'poi');
  await _handleVoid(uri,
    method: Method.POST,
    headers: { 'Content-Type': 'application/json' },
    body: encoder.convert(collection.asGeoJsonList())
  );
}