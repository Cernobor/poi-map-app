import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CommException implements Exception {
  final Uri uri;
  final String name;

  CommException(this.uri, this.name);

  @override
  String toString() {
    return 'CommException{uri: $uri, name: $name}';
  }

  static const String nameNotSupplied = 'nameNotSupplied';
  static const String nameAlreadyExists = 'nameAlreadyExists';
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

Future<Map<String, dynamic>> _handle(Uri uri) async {
  http.Response res = await http.get(uri);
  if (res.statusCode == HttpStatus.ok) {
    Map<String, dynamic> body = jsonDecode(res.body);
    if (body.containsKey('error')) {
      throw CommException(uri, body['error']);
    } else {
      return body;
    }
  } else {
    throw CommException(uri, 'Request refused. Code ${res.statusCode}');
  }
}

Future<void> _handleVoid(Uri uri) async {
  http.Response res = await http.get(uri);
  if (res.statusCode == HttpStatus.ok) {
    return;
  } else {
    throw CommException(uri, 'Request refused. Code ${res.statusCode}');
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
  var data = await _handle(uri);
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