import 'dart:convert';
import 'dart:io';

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
    file.writeAsString(jsonEncode({
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

Future<String> get _localPath async {
  final dir = await getApplicationDocumentsDirectory();
  return dir.path;
}