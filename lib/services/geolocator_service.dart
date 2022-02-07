import 'package:geolocator/geolocator.dart';

//this class should deal with all direct communication with the Geolocator API

class GeolocatorService {
  // Method for retrieving the current location
  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }
}
