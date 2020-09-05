import 'package:poi_map_app/urls/urls.dart';

class WebUriCreator implements UriCreator {
  @override
  Uri handshakeUri(String serverAddress, String name, bool exists) {
    return Uri.parse('${Uri.base.scheme}://${cleanupAddress(serverAddress)}/handshake').replace(queryParameters: {'name': name, 'exists': exists ? '1' : '0'});
  }

  @override
  Uri pingUri(String serverAddress) {
    return Uri.parse('${Uri.base.scheme}://${cleanupAddress(serverAddress)}/ping');
  }

  @override
  Uri poiData(String serverAddress) {
    return Uri.parse('${Uri.base.scheme}://${cleanupAddress(serverAddress)}/data').replace(queryParameters: {'data': 'pois,authors'});
  }
}

UriCreator getUriCreator() => WebUriCreator();