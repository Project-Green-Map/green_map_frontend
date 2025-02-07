//model of Google Places API's JSON response's Location field when finding location information
class Location {
  final double lat;
  final double lng;

  Location({required this.lat, required this.lng});

  factory Location.fromJson(Map<dynamic, dynamic> parsedJson) {
    return Location(
      lat: parsedJson['lat'],
      lng: parsedJson['lng'],
    );
  }
}
