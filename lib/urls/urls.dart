import 'package:poi_map_app/urls/stub.dart'
  // ignore: uri_does_not_exist
  if (dart.library.io) 'package:poi_map_app/urls/mobile.dart'
  // ignore: uri_does_not_exist
  if (dart.library.html) 'package:poi_map_app/urls/web.dart';


abstract class UriCreator {
  Uri handshakeUri(String serverAddress, String name, bool exists);
  Uri pingUri(String serverAddress);
  Uri poiData(String serverAddress);

  factory UriCreator() => getUriCreator();
}

String cleanupAddress(String address) {
  if (address.startsWith('http://')) {
    return address.substring('http://'.length);
  }
  if (address.startsWith('https://')) {
    return address.substring('https://'.length);
  }
  return address;
}
