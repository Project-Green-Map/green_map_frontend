import 'package:geolocator/geolocator.dart';

class GeolocatorService {
  // Method for retrieving the current location
  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }
}
