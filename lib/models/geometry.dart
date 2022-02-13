import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map/models/location.dart';

//model of Google Places API's JSON response's Geometry field when finding location information
//modified to use Flutter's LatLng over the original Location, as LatLng itself is more useful than the individual fields
class Geometry {
  final LatLng latLng;

  Geometry({required this.latLng});

  factory Geometry.fromJson(Map<dynamic, dynamic> parsedJson) {
    Location location = Location.fromJson(parsedJson['location']);
    return Geometry(latLng: LatLng(location.lat, location.lng));
  }
}
