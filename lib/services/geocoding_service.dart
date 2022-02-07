import 'package:geocoding/geocoding.dart';

//this class should deal with all direct communication with the GeoCoding API
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
