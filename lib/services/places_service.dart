import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert; // package for converting between file types
import 'package:flutter/services.dart' show rootBundle;
import 'package:map/models/place.dart';

import 'package:map/models/place_search.dart';

import 'api_manager.dart';

//this class should deal with all direct communication with the Places API
class PlacesService {
  APIManager apiManager = APIManager();

  Future<List<PlaceSearch>> getAutocomplete(String search) async {
    final key = apiManager.getKey();
    //!Uncomment for real data
    Uri uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$search&key=$key');
    var response = await http.get(uri);
    var json = convert.jsonDecode(response.body);

    //!Comment to remove dummy data
    // var response = await rootBundle.loadString('lib/dummy_data/places_request/places_request.json');
    // var json = convert.jsonDecode(response);

    var jsonResults = json['predictions'] as List;
    return jsonResults.map((place) => PlaceSearch.fromJson(place)).toList();
  }

  Future<Place> getPlace(String placeId) async {
    final key = apiManager.getKey();
    Uri uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?key=$key&place_id=$placeId&fields=formatted_address,geometry');
    //example placeID: ChIJcWGw3Ytzj1QR7Ui7HnTz6Dg
    var response = await http.get(uri);
    var json = convert.jsonDecode(response.body)['result'] as Map<String, dynamic>;
    return Place.fromJson(json);
  }
}
