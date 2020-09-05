import 'package:poi_map_app/urls/urls.dart';

class MobileUriCreator implements UriCreator {
  @override
  Uri handshakeUri(String serverAddress, String name, bool exists) {
    return Uri.http(cleanupAddress(serverAddress), 'handshake', {'name': name, 'exists': exists ? '1' : '0'});
  }

  @override
  Uri pingUri(String serverAddress) {
    return Uri.http(cleanupAddress(serverAddress), 'ping');
  }

  @override
  Uri poiData(String serverAddress) {
    return Uri.http(cleanupAddress(serverAddress), 'data', {'data': 'pois,authors'});
  }
}

UriCreator getUriCreator() => MobileUriCreator();