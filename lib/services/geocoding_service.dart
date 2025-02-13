import 'package:geocoding/geocoding.dart';
import 'api_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

//this class should deal with all direct communication with the GeoCoding API
class GeocodingService {
  APIManager apiManager = APIManager();

  Future<Placemark?> getCurrentPlacemark(position) async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(position.latitude, position.longitude);
      return p[0];
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<String?> getPlaceIdFromCoordinates(lat, lng) async {
    final key = apiManager.getKey();
    Uri uri =
        Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$key');

    print(uri);
    http.Response encodedString;
    try {
      encodedString = await http.get(uri);
    } catch (e) {
      print(e);
      return null;
    }
    String response = encodedString.body;

    var json = convert.jsonDecode(response);
    String? placeId;
    try {
      placeId = json['results'][0]['place_id']; //TODO: handle results being empty
    } catch (e) {
      print(e);
      return null;
    }
    print("PlaceId obtained: $placeId");
    return placeId;
  }
}
