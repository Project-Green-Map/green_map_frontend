import 'package:geocoding/geocoding.dart';

class GeocodingService {
  Future<Placemark?> getCurrentPlacemark(position) async {
    try {
      List<Placemark> p =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      return p[0];
    } catch (e) {
      print(e);
      return null;
    }
  }
}
