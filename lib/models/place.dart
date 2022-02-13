import 'package:map/models/geometry.dart';

//model of Google Places API's JSON response's Place field when finding location information
class Place {
  final Geometry geometry;
  final String name;

  Place({required this.geometry, required this.name});

  factory Place.fromJson(Map<String, dynamic> parsedJson) {
    return Place(
      geometry: Geometry.fromJson(parsedJson['geometry']),
      name: parsedJson['formatted_address'],
    );
  }
}
